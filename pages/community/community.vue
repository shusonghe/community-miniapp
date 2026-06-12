<template>
  <view class="container">
    <!-- 搜索栏 -->
    <view class="search-bar" :style="{paddingTop: vuex_status_bar_height + 'px'}">
      <view class="search-box">
        <text class="tn-icon-search"></text>
        <input class="search-input" v-model="keyword" placeholder="搜索邻里动态" confirm-type="search" @confirm="onSearch" />
      </view>
    </view>
    
    <scroll-view 
      class="content" 
      :style="{paddingTop: (vuex_status_bar_height + 60) + 'px'}"
      scroll-y
      refresher-enabled
      :refresher-triggered="refreshing"
      @refresherrefresh="onRefresh"
      @scrolltolower="loadMore"
    >
      <!-- 动态列表 -->
      <view class="feed-list">
        <view class="feed-item" v-for="(item, index) in posts" :key="item.id">
          <view class="feed-header">
            <image class="feed-avatar" :src="item.avatar_url || defaultAvatar" mode="aspectFill"></image>
            <view class="feed-user">
              <text class="feed-name">{{item.nickname || '珈邻用户'}}</text>
              <text class="feed-meta">{{formatTime(item.created_at)}} · {{item.building || '珈邻小区'}}</text>
            </view>
          </view>
          <text class="feed-text">{{item.content}}</text>
          <view class="feed-topic" v-if="item.topic">
            <text>#{{item.topic}}</text>
          </view>
          <view class="feed-images" v-if="item.images && item.images.length">
            <image 
              v-for="(img, imgIndex) in item.images.slice(0, 3)" 
              :key="imgIndex" :src="img" mode="aspectFill"
              class="feed-img"
              @click="previewImage(item.images, imgIndex)"
            ></image>
            <view class="img-more" v-if="item.images.length > 3">
              <text>+{{item.images.length - 3}}</text>
            </view>
          </view>
          <view class="feed-actions">
            <view class="action-item" @click="showComments(item)">
              <text class="tn-icon-message"></text>
              <text>{{item.comment_count || ''}}</text>
            </view>
            <view class="action-item" @click="toggleLike(item, index)">
              <text :class="['tn-icon-like-fill', item.liked ? 'liked' : '']"></text>
              <text :class="item.liked ? 'liked' : ''">{{item.like_count || ''}}</text>
            </view>
          </view>
        </view>
        
        <!-- 加载状态 -->
        <view class="load-status" v-if="posts.length > 0">
          <text v-if="loading">加载中...</text>
          <text v-else-if="noMore">没有更多了</text>
        </view>
        
        <!-- 空状态 -->
        <view class="empty-state" v-if="!loading && posts.length === 0">
          <text class="tn-icon-file"></text>
          <text>暂无动态</text>
        </view>
      </view>
    </scroll-view>
    
    <custom-tabbar :current="2"></custom-tabbar>
    
    <!-- 发布按钮 -->
    <view class="publish-btn" @click="goPublish" v-if="showFabBtn">
      <text class="tn-icon-edit"></text>
    </view>
    
    <!-- 评论弹窗 -->
    <view class="comment-mask" v-if="showCommentModal" @click="showCommentModal = false">
      <view class="comment-modal" @click.stop>
        <view class="comment-header">
          <text class="comment-title">评论 ({{currentPost.comment_count || 0}})</text>
          <text class="comment-close" @click="showCommentModal = false">×</text>
        </view>
        <scroll-view class="comment-list" scroll-y>
          <view class="comment-item" v-for="c in comments" :key="c.id">
            <image class="comment-avatar" :src="c.avatar_url || defaultAvatar" mode="aspectFill"></image>
            <view class="comment-content">
              <text class="comment-name">{{c.nickname}}</text>
              <text class="comment-text">{{c.content}}</text>
              <text class="comment-time">{{formatTime(c.created_at)}}</text>
            </view>
          </view>
          <view class="comment-empty" v-if="comments.length === 0">
            <text>暂无评论</text>
          </view>
        </scroll-view>
        <view class="comment-input-bar">
          <input class="comment-input" v-model="commentText" placeholder="写评论..." />
          <view class="comment-send" :class="{active: commentText.trim()}" @click="submitComment">发送</view>
        </view>
      </view>
    </view>
    
    <login-modal ref="loginModal"></login-modal>
    <register-tip-modal ref="registerTipModal"></register-tip-modal>
  </view>
</template>

<script>
import { auth, db } from '@/libs/supabase/supabase-mini.js'
import authMixin from '@/libs/mixin/auth.mixin.js'
import loginModal from '@/components/login-modal/login-modal.vue'
import registerTipModal from '@/components/register-tip-modal/register-tip-modal.vue'

export default {
  components: { loginModal, registerTipModal },
  mixins: [authMixin],
  data() {
    return {
      keyword: '',
      posts: [],
      loading: false,
      refreshing: false,
      noMore: false,
      page: 0,
      pageSize: 20,
      defaultAvatar: 'https://img.icons8.com/?size=100&id=s4mUhvTRUkP2&format=png&color=000000&padding=30',
      showCommentModal: false,
      currentPost: {},
      comments: [],
      commentText: ''
    }
  },
  computed: {
    showFabBtn() {
      const config = this.vuex_tabbar_config
      return config && Array.isArray(config) && config.length > 1
    }
  },
  onLoad() {
    this.loadPosts()
    uni.$on('postPublished', () => {
      this.onRefresh()
    })
  },
  onUnload() {
    uni.$off('postPublished')
  },
  methods: {
    async loadPosts(refresh = false) {
      if (this.loading) return
      if (!refresh && this.noMore) return
      
      this.loading = true
      if (refresh) {
        this.page = 0
        this.noMore = false
      }
      
      const user = auth.getLocalUser()
      const { data, error } = await db.rpc('get_posts', {
        p_user_id: user?.id || null,
        p_limit: this.pageSize,
        p_offset: this.page * this.pageSize,
        p_keyword: this.keyword || null
      })
      
      this.loading = false
      this.refreshing = false
      
      if (error) {
        uni.showToast({ title: '加载失败', icon: 'none' })
        return
      }
      
      const list = data || []
      if (refresh) {
        this.posts = list
      } else {
        this.posts = [...this.posts, ...list]
      }
      
      if (list.length < this.pageSize) {
        this.noMore = true
      }
      this.page++
    },
    onRefresh() {
      this.refreshing = true
      this.loadPosts(true)
    },
    loadMore() {
      this.loadPosts()
    },
    async toggleLike(item, index) {
      if (!this.requireLogin()) return
      
      const user = auth.getLocalUser()
      const { data, error } = await db.rpc('toggle_like', {
        p_post_id: item.id,
        p_user_id: user.id
      })
      
      if (error) {
        uni.showToast({ title: '操作失败', icon: 'none' })
        return
      }
      
      this.posts[index].liked = data.liked
      this.posts[index].like_count = data.like_count
    },
    async showComments(item) {
      if (!this.requireLogin()) return
      
      this.currentPost = item
      this.showCommentModal = true
      this.comments = []
      
      const { data, error } = await db.rpc('get_comments', {
        p_post_id: item.id
      })
      
      if (!error && data) {
        this.comments = data
      }
    },
    async submitComment() {
      if (!this.commentText.trim()) return
      if (!this.requireLogin()) return
      
      const user = auth.getLocalUser()
      const { data, error } = await db.rpc('add_comment', {
        p_post_id: this.currentPost.id,
        p_user_id: user.id,
        p_content: this.commentText.trim()
      })
      
      if (error) {
        uni.showToast({ title: '评论失败', icon: 'none' })
        return
      }
      
      // 添加到评论列表
      this.comments.push({
        ...data.comment,
        nickname: user.nickname,
        avatar_url: user.avatar_url
      })
      
      // 更新评论数
      const idx = this.posts.findIndex(p => p.id === this.currentPost.id)
      if (idx > -1) {
        this.posts[idx].comment_count = data.comment_count
      }
      this.currentPost.comment_count = data.comment_count
      
      this.commentText = ''
      uni.showToast({ title: '评论成功', icon: 'success' })
    },
    formatTime(time) {
      if (!time) return ''
      const date = new Date(time)
      const now = new Date()
      const diff = (now - date) / 1000
      
      if (diff < 60) return '刚刚'
      if (diff < 3600) return Math.floor(diff / 60) + '分钟前'
      if (diff < 86400) return Math.floor(diff / 3600) + '小时前'
      if (diff < 604800) return Math.floor(diff / 86400) + '天前'
      
      return `${date.getMonth() + 1}月${date.getDate()}日`
    },
    goPublish() {
      // 检查微信用户权限
      const user = auth.getLocalUser()
      if (!user) {
        this.$refs.loginModal.show()
        return
      }
      // 微信用户没有手机号，显示注册提示弹框
      if (!user.phone || user.phone === '') {
        this.$refs.registerTipModal.show()
        return
      }
      uni.navigateTo({ url: '/pages/community/publish' })
    },
    onSearch() {
      this.page = 0
      this.noMore = false
      this.posts = []
      this.loadPosts()
    },
    previewImage(images, current) { uni.previewImage({ urls: images, current: images[current] }) }
  }
}
</script>

<style scoped>
.container { min-height: 100vh; background: linear-gradient(180deg, #E8F4FD 0%, #D6EBFA 50%, #C4E2F7 100%); }

/* 搜索栏 */
.search-bar { position: fixed; top: 0; left: 0; right: 0; z-index: 100; background: linear-gradient(135deg, #4A90E2, #357ABD); padding: 12rpx 24rpx 16rpx; }
.search-box { display: flex; align-items: center; background: rgba(255,255,255,0.95); border-radius: 32rpx; padding: 12rpx 24rpx; }
.search-box .tn-icon-search { font-size: 32rpx; color: #999; margin-right: 12rpx; }
.search-input { flex: 1; font-size: 28rpx; }

.content { height: 100vh; padding-bottom: 200rpx; box-sizing: border-box; }

/* 动态列表 */
.feed-list { padding: 16rpx; }
.feed-item { background: #fff; padding: 24rpx; margin-bottom: 16rpx; border-radius: 16rpx; box-shadow: 0 2rpx 12rpx rgba(0,0,0,0.04); }
.feed-header { display: flex; align-items: center; margin-bottom: 16rpx; }
.feed-avatar { width: 80rpx; height: 80rpx; border-radius: 50%; margin-right: 16rpx; background: #f5f5f5; }
.feed-user { flex: 1; }
.feed-name { font-size: 30rpx; color: #333; font-weight: 500; display: block; }
.feed-meta { font-size: 24rpx; color: #999; margin-top: 4rpx; display: block; }
.feed-text { font-size: 30rpx; color: #333; line-height: 1.7; margin-bottom: 16rpx; white-space: pre-wrap; }
.feed-topic { margin-bottom: 16rpx; }
.feed-topic text { font-size: 26rpx; color: #4A90E2; background: #E8F4FD; padding: 6rpx 16rpx; border-radius: 6rpx; }

/* 图片网格 */
.feed-images { display: flex; gap: 12rpx; margin-bottom: 16rpx; position: relative; }
.feed-img { width: 220rpx; height: 220rpx; border-radius: 12rpx; background: #f0f0f0; }
.img-more { position: absolute; right: 0; bottom: 0; width: 220rpx; height: 220rpx; background: rgba(0,0,0,0.4); border-radius: 12rpx; display: flex; align-items: center; justify-content: center; }
.img-more text { font-size: 36rpx; color: #fff; font-weight: 500; }

/* 操作栏 */
.feed-actions { display: flex; justify-content: flex-end; padding-top: 16rpx; border-top: 1rpx solid #f5f5f5; }
.action-item { display: flex; align-items: center; margin-left: 48rpx; }
.action-item text { font-size: 26rpx; color: #999; }
.action-item text:first-child { font-size: 36rpx; margin-right: 8rpx; }
.action-item .liked { color: #FF6B6B; }

/* 加载状态 */
.load-status { text-align: center; padding: 32rpx; }
.load-status text { font-size: 26rpx; color: #999; }

/* 空状态 */
.empty-state { display: flex; flex-direction: column; align-items: center; padding: 120rpx 0; }
.empty-state text { color: #ccc; }
.empty-state text:first-child { font-size: 120rpx; margin-bottom: 24rpx; }
.empty-state text:last-child { font-size: 28rpx; }

/* 发布按钮 */
.publish-btn { position: fixed; right: 32rpx; bottom: 260rpx; width: 100rpx; height: 100rpx; background: linear-gradient(135deg, #5B9FE8, #4A90E2); border-radius: 50%; display: flex; align-items: center; justify-content: center; box-shadow: 0 8rpx 24rpx rgba(74, 144, 226, 0.4); }
.publish-btn text { font-size: 44rpx; color: #fff; }

/* 评论弹窗 */
.comment-mask { position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.5); z-index: 1000; display: flex; align-items: flex-end; }
.comment-modal { width: 100%; height: 70vh; background: #fff; border-radius: 24rpx 24rpx 0 0; display: flex; flex-direction: column; }
.comment-header { display: flex; justify-content: space-between; align-items: center; padding: 32rpx; border-bottom: 1rpx solid #f5f5f5; }
.comment-title { font-size: 32rpx; color: #333; font-weight: 500; }
.comment-close { font-size: 48rpx; color: #999; line-height: 1; }
.comment-list { flex: 1; padding: 0 24rpx; }
.comment-item { display: flex; padding: 24rpx 0; border-bottom: 1rpx solid #f5f5f5; }
.comment-avatar { width: 64rpx; height: 64rpx; border-radius: 50%; margin-right: 16rpx; background: #f5f5f5; }
.comment-content { flex: 1; }
.comment-name { font-size: 26rpx; color: #666; display: block; }
.comment-text { font-size: 28rpx; color: #333; margin-top: 8rpx; display: block; }
.comment-time { font-size: 24rpx; color: #999; margin-top: 8rpx; display: block; }
.comment-empty { text-align: center; padding: 60rpx; }
.comment-empty text { font-size: 28rpx; color: #999; }
.comment-input-bar { display: flex; align-items: center; padding: 16rpx 24rpx; border-top: 1rpx solid #f5f5f5; padding-bottom: calc(16rpx + env(safe-area-inset-bottom)); }
.comment-input { flex: 1; height: 72rpx; background: #f5f5f5; border-radius: 36rpx; padding: 0 24rpx; font-size: 28rpx; }
.comment-send { margin-left: 16rpx; padding: 16rpx 32rpx; background: #ccc; color: #fff; font-size: 28rpx; border-radius: 36rpx; }
.comment-send.active { background: linear-gradient(135deg, #4A90E2, #357ABD); }
</style>
