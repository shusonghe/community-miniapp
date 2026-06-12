<template>
  <view class="container">
    <!-- 顶部导航 -->
    <view class="nav-bar" :style="{paddingTop: vuex_status_bar_height + 'px'}">
      <view class="nav-content">
        <text class="nav-title">公告</text>
      </view>
    </view>
    
    <scroll-view 
      class="content" 
      :style="{paddingTop: (vuex_status_bar_height + 54) + 'px'}"
      scroll-y
    >
      <!-- 公告列表 -->
      <view class="notice-list">
        <view class="notice-item" v-for="item in notices" :key="item.id" @click="goDetail(item)">
          <view class="notice-header">
            <text class="notice-tag">{{item.tag || '公告'}}</text>
            <text class="notice-time">{{formatTime(item.created_at)}}</text>
          </view>
          <text class="notice-title">{{item.title}}</text>
          <view class="notice-arrow">
            <text class="tn-icon-right"></text>
          </view>
        </view>
        
        <!-- 空状态 -->
        <view class="empty-state" v-if="notices.length === 0">
          <text class="tn-icon-notice"></text>
          <text>暂无公告</text>
        </view>
      </view>
    </scroll-view>
    
    <custom-tabbar></custom-tabbar>
    
    <!-- 登录弹框 -->
    <login-modal ref="loginModal"></login-modal>
  </view>
</template>

<script>
import { db } from '@/libs/supabase/supabase-mini.js'
import authMixin from '@/libs/mixin/auth.mixin.js'
import loginModal from '@/components/login-modal/login-modal.vue'

export default {
  components: { loginModal },
  mixins: [authMixin],
  data() {
    return {
      notices: []
    }
  },
  onLoad() {
    this.loadNotices()
  },
  methods: {
    async loadNotices() {
      const { data, error } = await db.select('notices', {
        filter: { status: { eq: 'active' } },
        order: 'created_at.desc',
        limit: 50
      })
      
      if (!error && data) {
        this.notices = data
      }
    },
    goDetail(item) {
      // 检查登录状态，未登录则显示弹框
      if (!this.requireLogin()) return
      
      uni.navigateTo({
        url: `/pages/notice/detail?id=${item.id}`
      })
    },
    formatTime(time) {
      if (!time) return ''
      const date = new Date(time)
      return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`
    }
  }
}
</script>

<style scoped>
.container { min-height: 100vh; background: linear-gradient(180deg, #E8F4FD 0%, #D6EBFA 50%, #C4E2F7 100%); }

.nav-bar { position: fixed; top: 0; left: 0; right: 0; z-index: 100; background: linear-gradient(135deg, #4A90E2, #357ABD); }
.nav-content { display: flex; align-items: center; justify-content: center; padding: 20rpx 24rpx; height: 88rpx; }
.nav-title { font-size: 36rpx; font-weight: bold; color: #fff; }

.content { height: 100vh; padding: 20rpx; padding-bottom: 200rpx; box-sizing: border-box; }

.notice-list { }
.notice-item { 
  background: #fff; 
  border-radius: 16rpx; 
  padding: 24rpx; 
  margin-bottom: 16rpx; 
  box-shadow: 0 2rpx 8rpx rgba(0,0,0,0.03); 
  position: relative;
  display: flex;
  flex-direction: column;
}
.notice-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16rpx; }
.notice-tag { font-size: 24rpx; color: #4A90E2; background: #E8F4FD; padding: 6rpx 16rpx; border-radius: 6rpx; }
.notice-time { font-size: 24rpx; color: #999; }
.notice-title { font-size: 32rpx; color: #333; font-weight: 500; display: block; padding-right: 40rpx; }
.notice-arrow { 
  position: absolute; 
  right: 24rpx; 
  top: 50%; 
  transform: translateY(-50%); 
}
.notice-arrow text { font-size: 32rpx; color: #ccc; }

.empty-state { display: flex; flex-direction: column; align-items: center; padding: 120rpx 0; }
.empty-state text { color: #ccc; }
.empty-state text:first-child { font-size: 120rpx; margin-bottom: 24rpx; }
.empty-state text:last-child { font-size: 28rpx; }
</style>
