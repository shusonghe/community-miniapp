<template>
  <view class="container">
    <!-- 顶部导航 -->
    <view class="nav-bar" :style="{paddingTop: vuex_status_bar_height + 'px'}">
      <view class="nav-content">
        <view class="back-btn" @click="goBack">
          <text class="tn-icon-left"></text>
        </view>
        <text class="nav-title">商品详情</text>
        <view class="nav-placeholder"></view>
      </view>
    </view>
    
    <scroll-view class="content" :style="{paddingTop: (vuex_status_bar_height + 44) + 'px'}" scroll-y>
      <!-- 图片轮播 -->
      <swiper class="image-swiper" indicator-dots indicator-color="rgba(255,255,255,0.5)" indicator-active-color="#fff" circular v-if="goods.images && goods.images.length">
        <swiper-item v-for="(img, index) in goods.images" :key="index">
          <image :src="img" mode="aspectFit" @click="previewImage(index)"></image>
        </swiper-item>
      </swiper>
      
      <view class="detail-content" v-if="goods.id">
        <!-- 价格信息 -->
        <view class="price-section">
          <view class="price-row">
            <text class="price">¥{{goods.price}}</text>
            <text class="original-price" v-if="goods.original_price">原价¥{{goods.original_price}}</text>
          </view>
          <text class="title">{{goods.title}}</text>
          <view class="stats-row">
            <text class="stat-item">{{goods.view_count || 0}}浏览</text>
            <text class="stat-item">{{goods.favorite_count || 0}}收藏</text>
          </view>
        </view>
        
        <!-- 商品描述 -->
        <view class="desc-section" v-if="goods.description">
          <text class="section-title">商品描述</text>
          <text class="desc-text">{{goods.description}}</text>
        </view>
        
        <!-- 卖家信息 -->
        <view class="seller-section">
          <image class="seller-avatar" :src="goods.avatar_url || defaultAvatar"></image>
          <view class="seller-info">
            <text class="seller-name">{{goods.nickname || '珈邻用户'}}</text>
            <text class="seller-building" v-if="goods.building">{{goods.building}}</text>
          </view>
        </view>
      </view>
    </scroll-view>
    
    <!-- 底部操作栏 -->
    <view class="bottom-bar">
      <view class="action-item" @click="toggleFavorite">
        <text :class="goods.favorited ? 'tn-icon-star-fill' : 'tn-icon-star'" :style="{color: goods.favorited ? '#FFB800' : '#666'}"></text>
        <text>{{goods.favorited ? '已收藏' : '收藏'}}</text>
      </view>
      <view class="contact-btn" @click="callSeller">
        <text>联系卖家</text>
      </view>
    </view>
    
    <login-modal ref="loginModal"></login-modal>
    <!-- 注册提示弹框 -->
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
      defaultAvatar: 'https://img.icons8.com/?size=100&id=s4mUhvTRUkP2&format=png&color=000000&padding=30',
      itemId: null,
      goods: {}
    }
  },
  onLoad(options) {
    if (options.id) {
      this.itemId = options.id
      this.loadDetail()
    }
  },
  methods: {
    goBack() { uni.navigateBack() },
    async loadDetail() {
      try {
        const user = auth.getLocalUser()
        const { data, error } = await supabase.rpc('get_secondhand_detail', {
          p_item_id: parseInt(this.itemId),
          p_user_id: user ? user.id : null
        })
        
        console.log('商品详情:', data, error)
        
        if (error) throw error
        if (data) {
          this.goods = data
        }
      } catch (e) {
        console.error('加载详情失败:', e)
        uni.showToast({ title: '加载失败', icon: 'none' })
      }
    },
    previewImage(index) {
      if (this.goods.images && this.goods.images.length) {
        uni.previewImage({ urls: this.goods.images, current: this.goods.images[index] })
      }
    },
    async toggleFavorite() {
      const user = auth.getLocalUser()
      if (!user) {
        this.$refs.loginModal.show()
        return
      }
      
      try {
        const { data, error } = await supabase.rpc('toggle_favorite', {
          p_item_id: parseInt(this.itemId),
          p_user_id: user.id
        })
        
        if (error) throw error
        
        this.goods.favorited = data.favorited
        this.goods.favorite_count = data.favorite_count
        uni.showToast({ title: data.favorited ? '已收藏' : '已取消收藏', icon: 'none' })
      } catch (e) {
        console.error('收藏失败:', e)
        uni.showToast({ title: '操作失败', icon: 'none' })
      }
    },
    callSeller() {
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
      
      if (this.goods.phone) {
        uni.makePhoneCall({ phoneNumber: this.goods.phone })
      } else {
        uni.showToast({ title: '卖家未留联系方式', icon: 'none' })
      }
    }
  }
}
</script>

<style scoped>
.container { min-height: 100vh; background: #f5f5f5; }

.nav-bar { position: fixed; top: 0; left: 0; right: 0; z-index: 100; background: linear-gradient(135deg, #4A90E2, #357ABD); }
.nav-content { display: flex; justify-content: space-between; align-items: center; height: 88rpx; padding: 0 24rpx; }
.back-btn { width: 60rpx; height: 60rpx; display: flex; align-items: center; justify-content: center; }
.back-btn text { font-size: 36rpx; color: #fff; }
.nav-title { font-size: 34rpx; color: #fff; font-weight: 500; }
.nav-placeholder { width: 60rpx; }

.content { height: 100vh; padding-bottom: 140rpx; box-sizing: border-box; }

.image-swiper { width: 100%; height: 560rpx; background: #f0f0f0; }
.image-swiper image { width: 100%; height: 100%; }

.detail-content { padding: 0 24rpx 24rpx; }

.price-section { background: #fff; border-radius: 16rpx; padding: 24rpx; margin-top: 16rpx; }
.price-row { margin-bottom: 16rpx; }
.price { font-size: 48rpx; color: #4A90E2; font-weight: bold; }
.original-price { font-size: 28rpx; color: #999; text-decoration: line-through; margin-left: 16rpx; }
.title { font-size: 32rpx; color: #333; font-weight: 500; line-height: 1.5; }
.stats-row { margin-top: 16rpx; }
.stat-item { font-size: 24rpx; color: #999; margin-right: 24rpx; }

.desc-section { background: #fff; padding: 24rpx; margin-top: 16rpx; border-radius: 16rpx; }
.section-title { display: block; font-size: 30rpx; color: #333; font-weight: 500; margin-bottom: 16rpx; }
.desc-text { font-size: 28rpx; color: #666; line-height: 1.7; white-space: pre-wrap; }

.seller-section { display: flex; align-items: center; background: #fff; padding: 24rpx; margin-top: 16rpx; border-radius: 16rpx; }
.seller-avatar { width: 96rpx; height: 96rpx; border-radius: 50%; margin-right: 20rpx; background: #f5f5f5; }
.seller-info { flex: 1; }
.seller-name { display: block; font-size: 30rpx; color: #333; font-weight: 500; }
.seller-building { display: block; font-size: 24rpx; color: #999; margin-top: 8rpx; }

.bottom-bar { position: fixed; bottom: 0; left: 0; right: 0; display: flex; align-items: center; background: #fff; padding: 16rpx 24rpx; padding-bottom: calc(16rpx + env(safe-area-inset-bottom)); box-shadow: 0 -2rpx 16rpx rgba(0,0,0,0.06); }
.action-item { display: flex; flex-direction: column; align-items: center; margin-right: 40rpx; }
.action-item text { font-size: 24rpx; color: #666; }
.action-item text:first-child { font-size: 40rpx; }
.contact-btn { flex: 1; background: linear-gradient(135deg, #5B9FE8, #4A90E2); color: #fff; height: 88rpx; border-radius: 44rpx; display: flex; align-items: center; justify-content: center; font-size: 32rpx; font-weight: 500; }
</style>
