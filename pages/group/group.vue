<template>
  <view class="container">
    <!-- 顶部导航 -->
    <view class="nav-bar" :style="{paddingTop: vuex_status_bar_height + 'px'}">
      <view class="nav-content">
        <text class="nav-title">组团</text>
      </view>
    </view>
    
    <view class="page-content" :style="{paddingTop: (vuex_status_bar_height + 44) + 'px'}">
      <!-- 类型筛选 -->
      <view class="filter-section">
        <view 
          class="filter-item" 
          :class="currentCategory === '' ? 'active' : ''"
          @click="switchCategory('')"
        >
          <view class="filter-icon all-icon">
            <text class="tn-icon-menu"></text>
          </view>
          <text class="filter-name">全部</text>
        </view>
        <view 
          class="filter-item" 
          :class="currentCategory === 'activity' ? 'active' : ''"
          @click="switchCategory('activity')"
        >
          <view class="filter-icon activity-icon">
            <text class="tn-icon-team-fill"></text>
          </view>
          <text class="filter-name">邻里活动</text>
        </view>
        <view 
          class="filter-item" 
          :class="currentCategory === 'merchant' ? 'active' : ''"
          @click="switchCategory('merchant')"
        >
          <view class="filter-icon merchant-icon">
            <text class="tn-icon-gift"></text>
          </view>
          <text class="filter-name">商家活动</text>
        </view>
        <view 
          class="filter-item" 
          :class="currentCategory === 'sams' ? 'active' : ''"
          @click="switchCategory('sams')"
        >
          <view class="filter-icon sams-icon">
            <text class="tn-icon-shop-fill"></text>
          </view>
          <text class="filter-name">山姆代购</text>
        </view>
      </view>
      
      <!-- 列表标题 -->
      <view class="section-header">
        <text class="section-title">{{currentCategoryName}}</text>
        <text class="section-count" v-if="groupList.length > 0">共{{groupList.length}}个</text>
      </view>
      
      <!-- 活动列表 -->
      <view class="activity-list">
        <view 
          class="activity-card" 
          v-for="(item, index) in groupList" 
          :key="index" 
          @click="goDetail(item)"
        >
          <image class="card-image" :src="getItemImage(item)" mode="aspectFill"></image>
          <view class="card-info">
            <text class="card-title">{{item.title}}</text>
            <text class="card-desc">{{item.description || '精彩活动等你参加'}}</text>
            <view class="card-meta">
              <text class="meta-count">{{item.current_count || 0}}/{{item.target_count}}人</text>
              <text class="meta-status" :class="isExpired(item) ? 'expired' : 'active'">{{isExpired(item) ? '已结束' : '进行中'}}</text>
            </view>
            <view class="card-user">
              <image class="user-avatar" :src="item.avatar_url || defaultAvatar"></image>
              <text class="user-name">{{item.nickname || '邻居'}}</text>
              <text class="card-time">{{formatTime(item.created_at)}}</text>
            </view>
          </view>
        </view>
      </view>
      
      <!-- 空状态 -->
      <view class="empty-state" v-if="!loading && groupList.length === 0">
        <text class="tn-icon-team empty-icon"></text>
        <text class="empty-text">暂无活动</text>
      </view>
      
      <!-- 底部占位 -->
      <view style="height: 200rpx;"></view>
    </view>
    
    <!-- 悬浮按钮 -->
    <view class="fab-btn" @click="goPublish" v-if="showFabBtn">
      <text class="tn-icon-add"></text>
    </view>
    
    <!-- 自定义tabbar -->
    <custom-tabbar :current="3"></custom-tabbar>
    
    <login-modal ref="loginModal"></login-modal>
    <register-tip-modal ref="registerTipModal"></register-tip-modal>
  </view>
</template>

<script>
import authMixin from '@/libs/mixin/auth.mixin.js'
import loginModal from '@/components/login-modal/login-modal.vue'
import registerTipModal from '@/components/register-tip-modal/register-tip-modal.vue'
import { auth, supabase } from '@/libs/supabase/supabase-mini.js'

export default {
  components: { loginModal, registerTipModal },
  mixins: [authMixin],
  data() {
    return {
      defaultImages: {
        activity: 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=400&h=300&fit=crop',
        merchant: 'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=400&h=300&fit=crop',
        sams: 'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=400&h=300&fit=crop',
        default: 'https://images.unsplash.com/photo-1491438590914-bc09fcaaf77a?w=400&h=300&fit=crop'
      },
      defaultAvatar: 'https://img.icons8.com/?size=100&id=s4mUhvTRUkP2&format=png&color=000000',
      currentCategory: '',
      groupList: [],
      loading: false
    }
  },
  computed: {
    currentCategoryName() {
      const map = {
        '': '全部活动',
        'activity': '邻里活动',
        'merchant': '商家活动',
        'sams': '山姆代购'
      }
      return map[this.currentCategory] || '全部活动'
    },
    showFabBtn() {
      const config = this.vuex_tabbar_config
      return config && Array.isArray(config) && config.length > 1
    }
  },
  onLoad() {
    this.loadData()
  },
  onShow() {
    this.loadData()
  },
  onPullDownRefresh() {
    this.loadData().then(() => {
      uni.stopPullDownRefresh()
    })
  },
  methods: {
    async loadData() {
      if (this.loading) return
      this.loading = true
      
      try {
        const user = auth.getLocalUser()
        const { data, error } = await supabase.rpc('get_groups', {
          p_user_id: user ? user.id : null,
          p_limit: 20,
          p_offset: 0,
          p_category: this.currentCategory || null
        })
        
        console.log('组团列表数据:', data, error)
        if (error) throw error
        
        this.groupList = Array.isArray(data) ? data : []
      } catch (e) {
        console.error('加载组团列表失败:', e)
        this.groupList = []
      } finally {
        this.loading = false
      }
    },
    getItemImage(item) {
      // 如果有图片，使用第一张图片
      if (item.images && Array.isArray(item.images) && item.images.length > 0) {
        return item.images[0]
      }
      // 根据类型返回对应的默认图片
      return this.defaultImages[item.category] || this.defaultImages.default
    },
    switchCategory(category) {
      if (this.currentCategory === category) return
      this.currentCategory = category
      this.loadData()
    },
    goPublish() {
      const user = auth.getLocalUser()
      if (!user) {
        this.$refs.loginModal.show()
        return
      }
      if (!user.phone || user.phone === '') {
        this.$refs.registerTipModal.show()
        return
      }
      uni.navigateTo({ url: '/pages/group/publish' })
    },
    goDetail(item) {
      if (!this.requireLogin()) return
      uni.navigateTo({ url: '/pages/group/detail?id=' + item.id })
    },
    isExpired(item) {
      if (!item.end_time) return false
      return new Date(item.end_time) < new Date()
    },
    formatTime(time) {
      if (!time) return ''
      const date = new Date(time)
      const now = new Date()
      const diff = now - date
      
      if (diff < 60000) return '刚刚'
      if (diff < 3600000) return Math.floor(diff / 60000) + '分钟前'
      if (diff < 86400000) return Math.floor(diff / 3600000) + '小时前'
      if (diff < 604800000) return Math.floor(diff / 86400000) + '天前'
      
      return (date.getMonth() + 1) + '/' + date.getDate()
    }
  }
}
</script>

<style scoped>
.container {
  min-height: 100vh;
  background: linear-gradient(180deg, #E8F4FD 0%, #F5F9FC 30%, #F8FAFC 100%);
}

/* 导航栏 */
.nav-bar {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 100;
  background: linear-gradient(135deg, #4A90E2, #357ABD);
}
.nav-content {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 88rpx;
  padding: 0 24rpx;
}
.nav-title {
  font-size: 36rpx;
  color: #fff;
  font-weight: bold;
}

/* 页面内容 */
.page-content {
  padding: 16rpx;
}

/* 类型筛选 */
.filter-section {
  display: flex;
  justify-content: space-around;
  padding: 24rpx 16rpx;
  background: #fff;
  border-radius: 20rpx;
  box-shadow: 0 4rpx 20rpx rgba(74, 144, 226, 0.1);
  margin-bottom: 20rpx;
}
.filter-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 16rpx;
  border-radius: 16rpx;
}
.filter-item.active {
  background: linear-gradient(135deg, #E8F4FD, #D6EBFA);
}
.filter-icon {
  width: 80rpx;
  height: 80rpx;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 12rpx;
  box-shadow: 0 4rpx 12rpx rgba(0, 0, 0, 0.1);
}
.filter-icon text {
  font-size: 36rpx;
  color: #fff;
}
.all-icon {
  background: linear-gradient(135deg, #667eea, #764ba2);
}
.activity-icon {
  background: linear-gradient(135deg, #43E97B, #38F9D7);
}
.merchant-icon {
  background: linear-gradient(135deg, #FF6B6B, #FF8E53);
}
.sams-icon {
  background: linear-gradient(135deg, #4A90E2, #357ABD);
}
.filter-name {
  font-size: 24rpx;
  color: #666;
}
.filter-item.active .filter-name {
  color: #4A90E2;
  font-weight: 600;
}

/* 列表标题 */
.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16rpx 8rpx;
}
.section-title {
  font-size: 32rpx;
  color: #333;
  font-weight: bold;
}
.section-count {
  font-size: 24rpx;
  color: #999;
}

/* 活动卡片 */
.activity-list {
  
}
.activity-card {
  display: flex;
  background: #fff;
  border-radius: 16rpx;
  padding: 20rpx;
  margin-bottom: 20rpx;
  box-shadow: 0 4rpx 16rpx rgba(0, 0, 0, 0.06);
}
.card-image {
  width: 200rpx;
  height: 200rpx;
  border-radius: 12rpx;
  background: #f5f5f5;
  flex-shrink: 0;
}
.card-info {
  flex: 1;
  margin-left: 20rpx;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}
.card-title {
  font-size: 30rpx;
  color: #333;
  font-weight: 600;
  display: -webkit-box;
  -webkit-line-clamp: 1;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
.card-desc {
  font-size: 26rpx;
  color: #999;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  line-height: 1.4;
  margin: 8rpx 0;
}
.card-meta {
  display: flex;
  align-items: center;
  gap: 16rpx;
}
.meta-count {
  font-size: 24rpx;
  color: #4A90E2;
}
.meta-status {
  font-size: 22rpx;
  padding: 4rpx 12rpx;
  border-radius: 6rpx;
}
.meta-status.active {
  background: #E8F5E9;
  color: #4CAF50;
}
.meta-status.expired {
  background: #f5f5f5;
  color: #999;
}
.card-user {
  display: flex;
  align-items: center;
  margin-top: 8rpx;
}
.user-avatar {
  width: 40rpx;
  height: 40rpx;
  border-radius: 50%;
  background: #f0f0f0;
}
.user-name {
  font-size: 24rpx;
  color: #666;
  margin-left: 8rpx;
  flex: 1;
}
.card-time {
  font-size: 22rpx;
  color: #bbb;
}

/* 空状态 */
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 100rpx 0;
}
.empty-icon {
  font-size: 120rpx;
  color: #ccc;
  margin-bottom: 24rpx;
}
.empty-text {
  font-size: 28rpx;
  color: #999;
  margin-bottom: 32rpx;
}
.empty-btn {
  padding: 20rpx 48rpx;
  background: linear-gradient(135deg, #4A90E2, #357ABD);
  border-radius: 40rpx;
  box-shadow: 0 8rpx 24rpx rgba(74, 144, 226, 0.3);
}
.empty-btn text {
  font-size: 28rpx;
  color: #fff;
  font-weight: 500;
}

/* 悬浮按钮 */
.fab-btn {
  position: fixed;
  right: 32rpx;
  bottom: 220rpx;
  width: 100rpx;
  height: 100rpx;
  background: linear-gradient(135deg, #4A90E2, #357ABD);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 8rpx 32rpx rgba(74, 144, 226, 0.4);
  z-index: 99;
}
.fab-btn text {
  font-size: 48rpx;
  color: #fff;
}
</style>
