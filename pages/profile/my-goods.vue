<template>
  <view class="container">
    <!-- 顶部导航 -->
    <view class="nav-header" :style="{paddingTop: vuex_status_bar_height + 'px'}">
      <view class="nav-bar">
        <text class="tn-icon-left nav-back" @click="goBack"></text>
        <text class="nav-title">我的闲置</text>
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
      <!-- 状态筛选 -->
      <view class="status-tabs">
        <view :class="['tab-item', currentStatus === 'all' ? 'active' : '']" @click="switchStatus('all')">全部</view>
        <view :class="['tab-item', currentStatus === 'active' ? 'active' : '']" @click="switchStatus('active')">在售</view>
        <view :class="['tab-item', currentStatus === 'sold' ? 'active' : '']" @click="switchStatus('sold')">已售</view>
      </view>
      
      <!-- 商品列表 -->
      <view class="goods-list">
        <view class="goods-item" v-for="(item, index) in filteredGoods" :key="item.id" @click="goDetail(item)">
          <image class="goods-img" :src="item.images && item.images[0]" mode="aspectFill"></image>
          <view class="goods-info">
            <text class="goods-title">{{item.title}}</text>
            <view class="goods-price-row">
              <text class="goods-price">¥{{item.price}}</text>
              <text class="goods-status" :class="item.status">{{item.status === 'sold' ? '已售' : '在售'}}</text>
            </view>
            <view class="goods-meta">
              <text>{{item.view_count || 0}} 浏览</text>
              <text>{{formatTime(item.created_at)}}</text>
            </view>
          </view>
          <view class="goods-actions">
            <text class="action-btn sold-btn" v-if="item.status === 'active'" @click.stop="markSold(item, index)">标记已售</text>
            <text class="tn-icon-delete action-btn delete-btn" @click.stop="deleteGoods(item, index)"></text>
          </view>
        </view>
      </view>
      
      <!-- 加载状态 -->
      <view class="load-status" v-if="myGoods.length > 0">
        <text v-if="loading">加载中...</text>
        <text v-else-if="noMore">没有更多了</text>
      </view>
      
      <view class="empty-tip" v-if="!loading && filteredGoods.length === 0">
        <text class="tn-icon-shop empty-icon"></text>
        <text class="empty-text">暂无闲置物品</text>
      </view>
    </scroll-view>
    
    <!-- 发布按钮 -->
    <view class="publish-btn" @click="goPublish" v-if="showFabBtn">
      <text class="tn-icon-add"></text>
    </view>
    
    <!-- 注册提示弹框 -->
    <register-tip-modal ref="registerTipModal"></register-tip-modal>
  </view>
</template>

<script>
import { auth, supabase, storage } from '@/libs/supabase/supabase-mini.js'
import registerTipModal from '@/components/register-tip-modal/register-tip-modal.vue'

export default {
  components: { registerTipModal },
  data() {
    return {
      currentStatus: 'all',
      myGoods: [],
      loading: false,
      refreshing: false,
      noMore: false,
      page: 0,
      pageSize: 20
    }
  },
  computed: {
    filteredGoods() {
      if (this.currentStatus === 'all') return this.myGoods
      return this.myGoods.filter(item => item.status === this.currentStatus)
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
    // 每次显示刷新
    this.page = 0
    this.noMore = false
    this.myGoods = []
    this.loadData()
  },
  methods: {
    goBack() { uni.navigateBack() },
    switchStatus(status) {
      this.currentStatus = status
    },
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
        const { data, error } = await supabase.rpc('get_my_secondhand', {
          p_user_id: user.id,
          p_limit: this.pageSize,
          p_offset: this.page * this.pageSize
        })
        
        console.log('我的闲置:', data, error)
        
        if (error) throw error
        
        const list = data || []
        if (refresh) {
          this.myGoods = list
        } else {
          this.myGoods = [...this.myGoods, ...list]
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
    goDetail(item) {
      uni.navigateTo({ url: '/pages/secondhand/detail?id=' + item.id })
    },
    markSold(item, index) {
      uni.showModal({
        title: '提示',
        content: '确定标记为已售出吗？',
        success: async (res) => {
          if (res.confirm) {
            const user = auth.getLocalUser()
            const { data, error } = await supabase.rpc('update_secondhand_status', {
              p_item_id: item.id,
              p_user_id: user.id,
              p_status: 'sold'
            })
            
            if (error || !data.success) {
              uni.showToast({ title: data?.message || '操作失败', icon: 'none' })
              return
            }
            
            this.myGoods[index].status = 'sold'
            uni.showToast({ title: '已标记为已售', icon: 'success' })
          }
        }
      })
    },
    deleteGoods(item, index) {
      uni.showModal({
        title: '提示',
        content: '确定要删除这个闲置物品吗？',
        success: async (res) => {
          if (res.confirm) {
            uni.showLoading({ title: '删除中...' })
            
            const user = auth.getLocalUser()
            
            // 1. 先删除 Storage 中的图片
            if (item.images && item.images.length > 0) {
              console.log('[Delete] 删除图片:', item.images)
              await storage.deleteImages(item.images)
            }
            
            // 2. 再删除数据库记录
            const { data, error } = await supabase.rpc('delete_secondhand', {
              p_item_id: item.id,
              p_user_id: user.id
            })
            
            uni.hideLoading()
            
            if (error || !data.success) {
              uni.showToast({ title: data?.message || '删除失败', icon: 'none' })
              return
            }
            
            this.myGoods.splice(index, 1)
            uni.showToast({ title: '已删除', icon: 'success' })
          }
        }
      })
    },
    goPublish() {
      // 检查微信用户权限
      const user = auth.getLocalUser()
      if (!user) {
        uni.showToast({ title: '请先登录', icon: 'none' })
        return
      }
      // 微信用户没有手机号，显示自定义弹框
      if (!user.phone || user.phone === '') {
        this.$refs.registerTipModal.show()
        return
      }
      uni.navigateTo({ url: '/pages/secondhand/publish' })
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

.content { height: 100vh; padding: 20rpx; padding-bottom: 160rpx; box-sizing: border-box; }

.status-tabs { display: flex; background: #fff; border-radius: 12rpx; padding: 8rpx; margin-bottom: 20rpx; }
.tab-item { flex: 1; text-align: center; padding: 20rpx 0; font-size: 28rpx; color: #666; border-radius: 8rpx; }
.tab-item.active { background: linear-gradient(135deg, #4A90E2, #357ABD); color: #fff; }

.goods-list { }
.goods-item { display: flex; background: #fff; border-radius: 16rpx; padding: 20rpx; margin-bottom: 16rpx; box-shadow: 0 2rpx 12rpx rgba(0,0,0,0.04); }
.goods-img { width: 180rpx; height: 180rpx; border-radius: 12rpx; background: #f0f0f0; }
.goods-info { flex: 1; margin-left: 20rpx; display: flex; flex-direction: column; justify-content: space-between; }
.goods-title { font-size: 28rpx; color: #333; line-height: 1.4; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
.goods-price-row { display: flex; align-items: center; justify-content: space-between; }
.goods-price { font-size: 36rpx; color: #4A90E2; font-weight: bold; }
.goods-status { font-size: 22rpx; padding: 6rpx 16rpx; border-radius: 6rpx; }
.goods-status.active { color: #52C41A; background: #F6FFED; }
.goods-status.sold { color: #999; background: #F5F5F5; }
.goods-meta { display: flex; justify-content: space-between; }
.goods-meta text { font-size: 24rpx; color: #999; }
.goods-actions { display: flex; flex-direction: column; justify-content: space-around; padding-left: 16rpx; align-items: flex-end; }
.action-btn { padding: 10rpx; }
.sold-btn { font-size: 24rpx; color: #4A90E2; background: #E8F4FD; padding: 8rpx 16rpx; border-radius: 6rpx; }
.delete-btn { font-size: 36rpx; color: #FF6B6B; }

.load-status { text-align: center; padding: 32rpx; }
.load-status text { font-size: 26rpx; color: #999; }

.empty-tip { display: flex; flex-direction: column; align-items: center; padding: 120rpx 0; }
.empty-icon { font-size: 120rpx; color: #ccc; }
.empty-text { font-size: 28rpx; color: #999; margin-top: 20rpx; }

.publish-btn { position: fixed; right: 32rpx; bottom: 100rpx; width: 100rpx; height: 100rpx; background: linear-gradient(135deg, #5B9FE8, #4A90E2); border-radius: 50%; display: flex; align-items: center; justify-content: center; box-shadow: 0 8rpx 24rpx rgba(74, 144, 226, 0.4); }
.publish-btn text { font-size: 44rpx; color: #fff; }
</style>
