<template>
  <view class="container">
    <!-- 顶部导航 -->
    <view class="nav-bar" :style="{paddingTop: vuex_status_bar_height + 'px'}">
      <view class="nav-content">
        <view class="back-btn" @click="goBack">
          <text class="tn-icon-left"></text>
        </view>
        <text class="nav-title">周边组团</text>
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
      <!-- 组团列表 -->
      <view class="group-list">
        <view class="group-card" v-for="item in groupList" :key="item.id" @click="goDetail(item)">
          <image class="group-img" :src="item.images && item.images[0] || defaultImg" mode="aspectFit"></image>
          <view class="group-info">
            <text class="group-title">{{item.title}}</text>
            <view class="group-meta">
              <text class="group-price" v-if="item.price">¥{{item.price}}</text>
              <text class="group-count">{{item.current_count}}/{{item.target_count}}人</text>
            </view>
            <view class="group-footer">
              <view class="organizer">
                <image class="organizer-avatar" :src="item.avatar_url || defaultAvatar"></image>
                <text class="organizer-name">{{item.nickname}}</text>
              </view>
              <text class="group-status" :class="item.joined ? 'joined' : ''">{{item.joined ? '已参团' : '立即参团'}}</text>
            </view>
          </view>
        </view>
      </view>
      
      <!-- 加载状态 -->
      <view class="load-status" v-if="groupList.length > 0">
        <text v-if="loading">加载中...</text>
        <text v-else-if="noMore">没有更多了</text>
      </view>
      
      <!-- 空状态 -->
      <view class="empty-state" v-if="!loading && groupList.length === 0">
        <text class="tn-icon-shop empty-icon"></text>
        <text class="empty-text">暂无组团活动</text>
      </view>
    </scroll-view>
    
    <!-- 发布按钮 -->
    <!-- <view class="publish-btn" @click="goPublish">
      <text class="tn-icon-add"></text>
    </view> -->
    
    <login-modal ref="loginModal"></login-modal>
  </view>
</template>

<script>
import authMixin from '@/libs/mixin/auth.mixin.js'
import loginModal from '@/components/login-modal/login-modal.vue'
import { auth, supabase } from '@/libs/supabase/supabase-mini.js'

export default {
  components: { loginModal },
  mixins: [authMixin],
  data() {
    return {
      defaultAvatar: 'https://img.icons8.com/?size=100&id=s4mUhvTRUkP2&format=png&color=000000&padding=30',
      defaultImg: 'https://picsum.photos/seed/group/400/300',
      groupList: [],
      loading: false,
      refreshing: false,
      noMore: false,
      page: 0,
      pageSize: 20
    }
  },
  onLoad() {
    this.loadData()
  },
  onShow() {
    this.loadData(true)
  },
  methods: {
    goBack() { uni.navigateBack() },
    async loadData(refresh = false) {
      if (this.loading) return
      if (!refresh && this.noMore) return
      
      this.loading = true
      if (refresh) {
        this.page = 0
        this.noMore = false
      }
      
      try {
        const user = auth.getLocalUser()
        const { data, error } = await supabase.rpc('get_groups', {
          p_user_id: user ? user.id : null,
          p_limit: this.pageSize,
          p_offset: this.page * this.pageSize
        })
        
        if (error) throw error
        
        const list = data || []
        if (refresh) {
          this.groupList = list
        } else {
          this.groupList = [...this.groupList, ...list]
        }
        
        if (list.length < this.pageSize) {
          this.noMore = true
        }
        this.page++
      } catch (e) {
        console.error('加载组团列表失败:', e)
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
    goDetail(item) {
      uni.navigateTo({ url: '/pages/group/detail?id=' + item.id })
    },
    goPublish() {
      this.checkLoginAndGo('/pages/group/publish')
    }
  }
}
</script>

<style scoped>
.container { min-height: 100vh; background: linear-gradient(180deg, #E8F4FD 0%, #D6EBFA 50%, #C4E2F7 100%); }

.nav-bar { position: fixed; top: 0; left: 0; right: 0; z-index: 100; background: linear-gradient(135deg, #4A90E2, #357ABD); }
.nav-content { display: flex; justify-content: space-between; align-items: center; height: 88rpx; padding: 0 24rpx; }
.back-btn { width: 60rpx; height: 60rpx; display: flex; align-items: center; justify-content: center; }
.back-btn text { font-size: 36rpx; color: #fff; }
.nav-title { font-size: 34rpx; color: #fff; font-weight: 500; }
.nav-placeholder { width: 60rpx; }

.content { height: 100vh; padding-bottom: 160rpx; box-sizing: border-box; }

.group-list { padding: 0 16rpx; }
.group-card { background: #fff; border-radius: 16rpx; margin-bottom: 16rpx; overflow: hidden; box-shadow: 0 2rpx 12rpx rgba(0,0,0,0.04); }
.group-img { width: 100%; height: 300rpx; background: #f5f5f5; }
.group-info { padding: 20rpx; }
.group-title { font-size: 32rpx; color: #333; font-weight: 500; display: block; margin-bottom: 12rpx; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
.group-meta { display: flex; align-items: center; margin-bottom: 16rpx; }
.group-price { font-size: 36rpx; color: #FF6B6B; font-weight: bold; margin-right: 16rpx; }
.group-count { font-size: 26rpx; color: #4A90E2; background: #E8F4FD; padding: 6rpx 16rpx; border-radius: 6rpx; }
.group-footer { display: flex; justify-content: space-between; align-items: center; }
.organizer { display: flex; align-items: center; }
.organizer-avatar { width: 48rpx; height: 48rpx; border-radius: 50%; margin-right: 12rpx; background: #f5f5f5; }
.organizer-name { font-size: 26rpx; color: #666; }
.group-status { font-size: 26rpx; color: #4A90E2; padding: 10rpx 24rpx; border: 2rpx solid #4A90E2; border-radius: 32rpx; }
.group-status.joined { color: #52C41A; border-color: #52C41A; }

.load-status { text-align: center; padding: 32rpx; }
.load-status text { font-size: 26rpx; color: #999; }

.empty-state { display: flex; flex-direction: column; align-items: center; padding: 120rpx 0; }
.empty-icon { font-size: 120rpx; color: #ccc; }
.empty-text { font-size: 28rpx; color: #999; margin-top: 20rpx; }

.publish-btn { position: fixed; right: 32rpx; bottom: 100rpx; width: 100rpx; height: 100rpx; background: linear-gradient(135deg, #5B9FE8, #4A90E2); border-radius: 50%; display: flex; align-items: center; justify-content: center; box-shadow: 0 8rpx 24rpx rgba(74, 144, 226, 0.4); }
.publish-btn text { font-size: 44rpx; color: #fff; }
</style>
