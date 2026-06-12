<template>
  <view class="container">
    <!-- 顶部导航 -->
    <view class="nav-header" :style="{paddingTop: vuex_status_bar_height + 'px'}">
      <view class="nav-bar">
        <text class="tn-icon-left nav-back" @click="goBack"></text>
        <text class="nav-title">我的动态</text>
        <view class="nav-placeholder"></view>
      </view>
    </view>
    
    <scroll-view 
      class="content" 
      :style="{paddingTop: (vuex_status_bar_height + 44) + 'px'}"
      scroll-y
      refresher-enabled
      :refresher-triggered="refreshing"
      @refresherrefresh="onRefresh"
      @scrolltolower="loadMore"
    >
      <view class="feed-list">
        <view class="feed-item" v-for="(item, index) in myPosts" :key="item.id">
          <view class="feed-header">
            <image class="feed-avatar" :src="item.avatar_url || defaultAvatar" mode="aspectFill"></image>
            <view class="feed-user">
              <text class="feed-name">{{item.nickname || '珈邻用户'}}</text>
              <text class="feed-meta">{{formatTime(item.created_at)}} · {{item.building || '珈邻小区'}}</text>
            </view>
            <text class="tn-icon-delete delete-btn" @click="deletePost(item, index)"></text>
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
              @click="previewImage(item.images, imgIdx)"
            ></image>
            <view class="img-more" v-if="item.images.length > 3">
              <text>+{{item.images.length - 3}}</text>
            </view>
          </view>
          <view class="feed-stats">
            <text>{{item.like_count || 0}} 赞</text>
            <text>{{item.comment_count || 0}} 评论</text>
          </view>
        </view>
      </view>
      
      <!-- 加载状态 -->
      <view class="load-status" v-if="myPosts.length > 0">
        <text v-if="loading">加载中...</text>
        <text v-else-if="noMore">没有更多了</text>
      </view>
      
      <view class="empty-tip" v-if="!loading && myPosts.length === 0">
        <text class="tn-icon-file empty-icon"></text>
        <text class="empty-text">暂无动态</text>
      </view>
    </scroll-view>
    
    <!-- 发布按钮 -->
    <view class="publish-btn" @click="goPublish" v-if="showFabBtn">
      <text class="tn-icon-edit"></text>
    </view>
    
    <login-modal ref="loginModal"></login-modal>
    
    <!-- 注册提示弹框 -->
    <register-tip-modal ref="registerTipModal"></register-tip-modal>
  </view>
</template>

<script>
import { auth, supabase, storage } from '@/libs/supabase/supabase-mini.js'
import authMixin from '@/libs/mixin/auth.mixin.js'
import loginModal from '@/components/login-modal/login-modal.vue'
import registerTipModal from '@/components/register-tip-modal/register-tip-modal.vue'

export default {
  components: { loginModal, registerTipModal },
  mixins: [authMixin],
  data() {
    return {
      defaultAvatar: 'https://img.icons8.com/?size=100&id=s4mUhvTRUkP2&format=png&color=000000&padding=30',
      myPosts: [],
      loading: false,
      refreshing: false,
      noMore: false,
      page: 0,
      pageSize: 20
    }
  },
  computed: {
    showFabBtn() {
      const config = this.vuex_tabbar_config
      return config && Array.isArray(config) && config.length > 1
    }
  },
  onLoad() {
    this.loadData()
  },
  methods: {
    goBack() { uni.navigateBack() },
    async loadData(refresh = false) {
      const user = auth.getLocalUser()
      if (!user) return
      
      if (this.loading) return
      if (!refresh && this.noMore) return
      
      this.loading = true
      if (refresh) {
        this.page = 0
        this.noMore = false
      }
      
      try {
        const { data, error } = await supabase.rpc('get_my_posts', {
          p_user_id: user.id,
          p_limit: this.pageSize,
          p_offset: this.page * this.pageSize
        })
        
        if (error) throw error
        
        const list = data || []
        if (refresh) {
          this.myPosts = list
        } else {
          this.myPosts = [...this.myPosts, ...list]
        }
        
        if (list.length < this.pageSize) {
          this.noMore = true
        }
        this.page++
      } catch (e) {
        console.error('加载失败:', e)
        uni.showToast({ title: '加载失败', icon: 'none' })
      } finally {
        this.loading = false
        this.refreshing = false
      }
    },
    onRefresh() {
      this.refreshing = true
      this.loadData(true)
    },
    loadMore() {
      this.loadData()
    },
    deletePost(item, index) {
      uni.showModal({
        title: '提示',
        content: '确定要删除这条动态吗？',
        success: async (res) => {
          if (res.confirm) {
            uni.showLoading({ title: '删除中...' })
            
            const user = auth.getLocalUser()
            
            // 1. 先删除 Storage 中的图片
            if (item.images && item.images.length > 0) {
              console.log('[Delete] 删除图片:', item.images)
              const deleteResult = await storage.deleteImages(item.images)
              console.log('[Delete] 图片删除结果:', deleteResult)
            }
            
            // 2. 再删除数据库记录
            const { data, error } = await supabase.rpc('delete_post', {
              p_post_id: item.id,
              p_user_id: user.id
            })
            
            console.log('[Delete] 数据库删除结果:', data, error)
            
            uni.hideLoading()
            
            if (error || !data.success) {
              uni.showToast({ title: data?.message || '删除失败', icon: 'none' })
              return
            }
            
            this.myPosts.splice(index, 1)
            uni.showToast({ title: '已删除', icon: 'success' })
          }
        }
      })
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
    previewImage(images, current) {
      uni.previewImage({ urls: images, current: images[current] })
    },
    goPublish() {
      // 检查微信用户权限
      const user = auth.getLocalUser()
      if (!user) {
        this.showLoginModal()
        return
      }
      // 微信用户没有手机号，显示自定义弹框
      if (!user.phone || user.phone === '') {
        this.$refs.registerTipModal.show()
        return
      }
      uni.navigateTo({ url: '/pages/community/publish' })
    }
  }
}
</script>

<style scoped>
.container { min-height: 100vh; background: linear-gradient(180deg, #E8F4FD 0%, #D6EBFA 50%, #C4E2F7 100%); }
.nav-header { position: fixed; top: 0; left: 0; right: 0; z-index: 100; background: linear-gradient(135deg, #4A90E2, #357ABD); }
.nav-bar { display: flex; align-items: center; justify-content: space-between; padding: 0 24rpx; height: 88rpx; }
.nav-back { font-size: 40rpx; color: #fff; padding: 10rpx; }
.nav-title { font-size: 34rpx; color: #fff; font-weight: 500; }
.nav-placeholder { width: 60rpx; }

.content { height: 100vh; padding: 20rpx; padding-bottom: 40rpx; box-sizing: border-box; }

.feed-list { }
.feed-item { background: #fff; border-radius: 16rpx; padding: 24rpx; margin-bottom: 16rpx; box-shadow: 0 2rpx 12rpx rgba(0,0,0,0.04); }
.feed-header { display: flex; align-items: center; margin-bottom: 16rpx; }
.feed-avatar { width: 80rpx; height: 80rpx; border-radius: 50%; margin-right: 16rpx; background: #f5f5f5; }
.feed-user { flex: 1; }
.feed-name { display: block; font-size: 30rpx; color: #333; font-weight: 500; }
.feed-meta { display: block; font-size: 24rpx; color: #999; margin-top: 4rpx; }
.delete-btn { font-size: 36rpx; color: #FF6B6B; padding: 10rpx; }
.feed-text { font-size: 30rpx; color: #333; line-height: 1.6; margin-bottom: 16rpx; white-space: pre-wrap; }
.feed-topic { margin-bottom: 16rpx; }
.feed-topic text { font-size: 26rpx; color: #4A90E2; background: #E8F4FD; padding: 6rpx 16rpx; border-radius: 6rpx; }
.feed-images { display: flex; gap: 12rpx; margin-bottom: 16rpx; position: relative; }
.feed-img { width: 200rpx; height: 200rpx; border-radius: 12rpx; background: #f0f0f0; }
.img-more { position: absolute; right: 0; bottom: 0; width: 200rpx; height: 200rpx; background: rgba(0,0,0,0.4); border-radius: 12rpx; display: flex; align-items: center; justify-content: center; }
.img-more text { font-size: 36rpx; color: #fff; font-weight: 500; }
.feed-stats { display: flex; gap: 32rpx; padding-top: 16rpx; border-top: 1rpx solid #F5F5F5; }
.feed-stats text { font-size: 26rpx; color: #999; }

.load-status { text-align: center; padding: 32rpx; }
.load-status text { font-size: 26rpx; color: #999; }

.empty-tip { display: flex; flex-direction: column; align-items: center; padding: 120rpx 0; }
.empty-icon { font-size: 120rpx; color: #ccc; }
.empty-text { font-size: 28rpx; color: #999; margin-top: 20rpx; }

/* 发布按钮 */
.publish-btn { position: fixed; right: 32rpx; bottom: 120rpx; width: 100rpx; height: 100rpx; background: linear-gradient(135deg, #5B9FE8, #4A90E2); border-radius: 50%; display: flex; align-items: center; justify-content: center; box-shadow: 0 8rpx 24rpx rgba(74, 144, 226, 0.4); }
.publish-btn text { font-size: 44rpx; color: #fff; }
</style>
