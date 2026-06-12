<template>
  <view class="container">
    <!-- 顶部导航 -->
    <view class="nav-bar" :style="{paddingTop: vuex_status_bar_height + 'px'}">
      <view class="nav-content">
        <text class="nav-logo">珈邻</text>
        <view class="nav-search">
          <text class="tn-icon-search"></text>
          <input class="search-input" v-model="keyword" placeholder="搜索小区动态" confirm-type="search" @confirm="onSearch" />
        </view>
      </view>
    </view>
    
    <scroll-view 
      class="content" 
      :style="{paddingTop: (vuex_status_bar_height + 54) + 'px'}"
      scroll-y
      refresher-enabled
      :refresher-triggered="refreshing"
      @refresherrefresh="onRefresh"
      @scrolltolower="loadMore"
    >
      <!-- 功能入口 -->
      <view class="func-section">
        <view class="func-item" @click="goTo('/pages/community/community')">
          <view class="func-icon func-icon-1">
            <text class="tn-icon-team"></text>
          </view>
          <text class="func-name">社区</text>
        </view>
        <view class="func-item" @click="goTo('/pages/secondhand/secondhand')">
          <view class="func-icon func-icon-2">
            <text class="tn-icon-gift"></text>
          </view>
          <text class="func-name">闲置</text>
        </view>
        <view class="func-item" @click="goTo('/pages/group/group')">
          <view class="func-icon func-icon-3">
            <text class="tn-icon-shop"></text>
          </view>
          <text class="func-name">组团</text>
        </view>
        <view class="func-item" @click="goTo('/pages/profile/profile')">
          <view class="func-icon func-icon-4">
            <text class="tn-icon-my-fill"></text>
          </view>
          <text class="func-name">我的</text>
        </view>
      </view>
      
      <!-- 邻里动态 -->
      <view class="section-header">
        <text class="section-title">邻里动态</text>
        <view class="section-tabs">
          <text :class="['tab-item', currentTab === 0 ? 'active' : '']" @click="switchTab(0)">最新</text>
          <text :class="['tab-item', currentTab === 1 ? 'active' : '']" @click="switchTab(1)">热门</text>
        </view>
      </view>
      
      <!-- 动态列表 -->
      <view class="feed-list">
        <view class="feed-item" v-for="(item, index) in posts" :key="item.id" @click="goDetail(item)">
          <view class="feed-header">
            <image class="feed-avatar" :src="item.avatar_url || defaultAvatar" mode="aspectFill"></image>
            <view class="feed-user">
              <view class="user-row">
                <text class="feed-name">{{item.nickname || '珈邻用户'}}</text>
              </view>
              <text class="feed-meta">{{formatTime(item.created_at)}} · {{item.building || '珈邻小区'}}</text>
            </view>
          </view>
          <text class="feed-text">{{item.content}}</text>
          <view class="feed-topic" v-if="item.topic">
            <text>#{{item.topic}}</text>
          </view>
          <view class="feed-images" v-if="item.images && item.images.length">
            <image 
              v-for="(img, imgIdx) in item.images.slice(0, 3)" 
              :key="imgIdx" 
              :src="img" 
              mode="aspectFill"
              class="feed-img"
              @click.stop="previewImage(item.images, imgIdx)"
            ></image>
            <view class="img-more" v-if="item.images.length > 3">
              <text>+{{item.images.length - 3}}</text>
            </view>
          </view>
          <view class="feed-actions" @click.stop>
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
    
    <custom-tabbar :current="0"></custom-tabbar>
    
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
  </view>
</template>

<script>
import { auth, db } from '@/libs/supabase/supabase-mini.js'
import authMixin from '@/libs/mixin/auth.mixin.js'
import loginModal from '@/components/login-modal/login-modal.vue'

export default {
  components: { loginModal },
  mixins: [authMixin],
  data() {
    return {
      keyword: '',
      currentTab: 0,
      posts: [],
      loading: false,
      refreshing: false,
      noMore: false,
      page: 0,
      pageSize: 10,
      defaultAvatar: 'https://img.icons8.com/?size=100&id=s4mUhvTRUkP2&format=png&color=000000&padding=30',
      showCommentModal: false,
      currentPost: {},
      comments: [],
      commentText: ''
    }
  },
  onLoad() {
    this.loadPosts()
    uni.$on('postPublished', () => {
      this.onRefresh()
    })
  },
  onShow() {
    // 每次显示页面时刷新数据，确保头像等信息是最新的
    this.onRefresh()
  },
  onUnload() {
    uni.$off('postPublished')
  },
  methods: {
    switchTab(tab) {
      if (this.currentTab === tab) return
      this.currentTab = tab
      this.posts = []
      this.page = 0
      this.noMore = false
      this.loadPosts()
    },
    async loadPosts(refresh = false) {
      if (this.loading) return
      if (!refresh && this.noMore) return
      
      this.loading = true
      if (refresh) {
        this.page = 0
        this.noMore = false
      }
      
      const user = auth.getLocalUser()
      const orderBy = this.currentTab === 0 ? 'latest' : 'hot'
      const { data, error } = await db.rpc('get_posts', {
        p_user_id: user?.id || null,
        p_limit: this.pageSize,
        p_offset: this.page * this.pageSize,
        p_keyword: this.keyword || null,
        p_order_by: orderBy
      })
      
      this.loading = false
      this.refreshing = false
      
      if (error) {
        console.log('Load posts error:', error)
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
      
      this.comments.push({
        ...data.comment,
        nickname: user.nickname,
        avatar_url: user.avatar_url
      })
      
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
    goTo(url) {
      uni.switchTab({ url }).catch(() => { uni.navigateTo({ url }) })
    },
    goDetail(item) {
      // 可以跳转到详情页
    },
    onSearch() {
      this.page = 0
      this.noMore = false
      this.posts = []
      this.loadPosts()
    },
    previewImage(images, current) {
      uni.previewImage({ urls: images, current: images[current] })
    }
  }
}
</script>

<style scoped>
.container { min-height: 100vh; background: linear-gradient(180deg, #E8F4FD 0%, #D6EBFA 50%, #C4E2F7 100%); }

.nav-bar { position: fixed; top: 0; left: 0; right: 0; z-index: 100; background: linear-gradient(135deg, #4A90E2, #357ABD); }
.nav-content { display: flex; align-items: center; padding: 20rpx 24rpx; height: 88rpx; }
.nav-logo { font-size: 44rpx; font-weight: bold; color: #fff; margin-right: 20rpx; }
.nav-search { flex: 1; display: flex; align-items: center; background: rgba(255,255,255,0.9); border-radius: 32rpx; padding: 12rpx 24rpx; }
.nav-search .tn-icon-search { color: #999; font-size: 28rpx; margin-right: 12rpx; }
.search-input { flex: 1; font-size: 26rpx; color: #333; }

.content { height: 100vh; padding: 20rpx; padding-bottom: 200rpx; box-sizing: border-box; }

/* 功能入口 */
.func-section { display: flex; justify-content: space-between; padding: 20rpx 10rpx; }
.func-item { display: flex; flex-direction: column; align-items: center; width: 25%; }
.func-icon { width: 120rpx; height: 120rpx; border-radius: 24rpx; display: flex; align-items: center; justify-content: center; margin-bottom: 12rpx; }
.func-icon text { font-size: 52rpx; color: #fff; }
.func-icon-1 { background: linear-gradient(180deg, #5B9FE8, #4A90E2); }
.func-icon-2 { background: linear-gradient(180deg, #36CFC9, #13C2C2); }
.func-icon-3 { background: linear-gradient(180deg, #FFD666, #FAAD14); }
.func-icon-4 { background: linear-gradient(180deg, #FF9C6E, #FA8C16); }
.func-name { font-size: 26rpx; color: #333; }

/* 标题栏 */
.section-header { display: flex; justify-content: space-between; align-items: center; padding: 24rpx 8rpx; }
.section-title { font-size: 32rpx; font-weight: bold; color: #333; }
.section-tabs { display: flex; }
.tab-item { font-size: 28rpx; color: #999; margin-left: 24rpx; padding: 8rpx 0; }
.tab-item.active { color: #4A90E2; font-weight: 500; }

/* 动态列表 */
.feed-list { }
.feed-item { background: #fff; border-radius: 16rpx; padding: 24rpx; margin-bottom: 16rpx; box-shadow: 0 2rpx 8rpx rgba(0,0,0,0.03); }
.feed-header { display: flex; align-items: center; margin-bottom: 16rpx; }
.feed-avatar { width: 80rpx; height: 80rpx; border-radius: 50%; margin-right: 16rpx; background: #f5f5f5; }
.feed-user { flex: 1; }
.user-row { display: flex; align-items: center; }
.feed-name { font-size: 30rpx; color: #333; font-weight: 500; }
.feed-meta { font-size: 24rpx; color: #999; margin-top: 4rpx; display: block; }
.feed-text { font-size: 30rpx; color: #333; line-height: 1.6; margin-bottom: 16rpx; display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; overflow: hidden; }
.feed-topic { margin-bottom: 16rpx; }
.feed-topic text { font-size: 26rpx; color: #4A90E2; background: #E8F4FD; padding: 6rpx 16rpx; border-radius: 6rpx; }
.feed-images { display: flex; gap: 12rpx; margin-bottom: 16rpx; position: relative; }
.feed-img { width: 220rpx; height: 220rpx; border-radius: 12rpx; background: #f0f0f0; }
.img-more { position: absolute; right: 0; bottom: 0; width: 220rpx; height: 220rpx; background: rgba(0,0,0,0.4); border-radius: 12rpx; display: flex; align-items: center; justify-content: center; }
.img-more text { font-size: 36rpx; color: #fff; font-weight: 500; }
.feed-actions { display: flex; justify-content: flex-end; padding-top: 16rpx; border-top: 1rpx solid #F5F5F5; }
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
