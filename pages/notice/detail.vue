<template>
  <view class="container">
    <!-- 顶部导航 -->
    <view class="nav-bar" :style="{paddingTop: vuex_status_bar_height + 'px'}">
      <view class="nav-content">
        <view class="nav-back" @click="goBack">
          <text class="tn-icon-left"></text>
        </view>
        <text class="nav-title">公告详情</text>
        <view class="nav-placeholder"></view>
      </view>
    </view>
    
    <scroll-view 
      class="content" 
      :style="{paddingTop: (vuex_status_bar_height + 54) + 'px'}"
      scroll-y
    >
      <view class="notice-detail" v-if="notice">
        <view class="notice-header">
          <text class="notice-tag">{{notice.tag || '公告'}}</text>
          <text class="notice-time">{{formatTime(notice.created_at)}}</text>
        </view>
        <text class="notice-title">{{notice.title}}</text>
        <view class="notice-divider"></view>
        <text class="notice-content">{{notice.content}}</text>
      </view>
      
      <!-- 加载状态 -->
      <view class="loading-state" v-if="loading">
        <text>加载中...</text>
      </view>
      
      <!-- 空状态 -->
      <view class="empty-state" v-if="!loading && !notice">
        <text class="tn-icon-notice"></text>
        <text>公告不存在或已删除</text>
      </view>
    </scroll-view>
  </view>
</template>

<script>
import { db } from '@/libs/supabase/supabase-mini.js'

export default {
  data() {
    return {
      noticeId: '',
      notice: null,
      loading: true
    }
  },
  onLoad(options) {
    if (options.id) {
      this.noticeId = options.id
      this.loadNoticeDetail()
    } else {
      this.loading = false
    }
  },
  methods: {
    async loadNoticeDetail() {
      this.loading = true
      const { data, error } = await db.select('notices', {
        filter: { id: { eq: this.noticeId } },
        limit: 1
      })
      
      this.loading = false
      if (!error && data && data.length > 0) {
        this.notice = data[0]
      }
    },
    formatTime(time) {
      if (!time) return ''
      const date = new Date(time)
      return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')} ${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`
    },
    goBack() {
      uni.navigateBack()
    }
  }
}
</script>

<style scoped>
.container { min-height: 100vh; background: linear-gradient(180deg, #E8F4FD 0%, #D6EBFA 50%, #C4E2F7 100%); }

.nav-bar { position: fixed; top: 0; left: 0; right: 0; z-index: 100; background: linear-gradient(135deg, #4A90E2, #357ABD); }
.nav-content { display: flex; align-items: center; justify-content: space-between; padding: 20rpx 24rpx; height: 88rpx; }
.nav-back { width: 60rpx; height: 60rpx; display: flex; align-items: center; justify-content: center; }
.nav-back text { font-size: 40rpx; color: #fff; }
.nav-title { font-size: 36rpx; font-weight: bold; color: #fff; }
.nav-placeholder { width: 60rpx; }

.content { height: 100vh; padding: 20rpx; box-sizing: border-box; }

.notice-detail { background: #fff; border-radius: 16rpx; padding: 32rpx; box-shadow: 0 2rpx 8rpx rgba(0,0,0,0.03); }
.notice-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 24rpx; }
.notice-tag { font-size: 24rpx; color: #4A90E2; background: #E8F4FD; padding: 8rpx 20rpx; border-radius: 8rpx; }
.notice-time { font-size: 24rpx; color: #999; }
.notice-title { font-size: 36rpx; color: #333; font-weight: 600; display: block; margin-bottom: 24rpx; line-height: 1.5; }
.notice-divider { height: 1rpx; background: #f0f0f0; margin-bottom: 24rpx; }
.notice-content { font-size: 30rpx; color: #666; line-height: 1.8; display: block; white-space: pre-wrap; }

.loading-state { display: flex; justify-content: center; padding: 60rpx 0; }
.loading-state text { font-size: 28rpx; color: #999; }

.empty-state { display: flex; flex-direction: column; align-items: center; padding: 120rpx 0; }
.empty-state text { color: #ccc; }
.empty-state text:first-child { font-size: 120rpx; margin-bottom: 24rpx; }
.empty-state text:last-child { font-size: 28rpx; }
</style>
