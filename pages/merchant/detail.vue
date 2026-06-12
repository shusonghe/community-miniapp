<template>
  <view class="container">
    <!-- 头图 -->
    <swiper class="cover-swiper" indicator-dots indicator-color="rgba(255,255,255,0.5)" indicator-active-color="#fff" circular>
      <swiper-item v-for="(img, index) in merchant.images" :key="index">
        <image :src="img" mode="aspectFill" @click="previewImage(index)"></image>
      </swiper-item>
    </swiper>
    
    <!-- 返回按钮 -->
    <view class="back-btn" :style="{top: (vuex_status_bar_height + 10) + 'px'}" @click="goBack">
      <text class="tn-icon-left"></text>
    </view>
    
    <view class="content">
      <!-- 商家信息 -->
      <view class="merchant-card">
        <view class="merchant-header">
          <text class="merchant-name">{{merchant.name}}</text>
          <view class="merchant-rating">
            <text class="tn-icon-star-fill"></text>
            <text class="rating-score">{{merchant.rating}}</text>
          </view>
        </view>
        <text class="merchant-category">{{merchant.category}}</text>
        <view class="merchant-tags">
          <text class="tag" v-for="(tag, index) in merchant.tags" :key="index">{{tag}}</text>
        </view>
      </view>
      
      <!-- 联系信息 -->
      <view class="contact-card">
        <view class="contact-item" @click="openMap">
          <view class="contact-icon">
            <text class="tn-icon-map"></text>
          </view>
          <view class="contact-info">
            <text class="contact-label">地址</text>
            <text class="contact-value">{{merchant.address}}</text>
          </view>
          <text class="tn-icon-right"></text>
        </view>
        <view class="contact-item" @click="callMerchant">
          <view class="contact-icon phone">
            <text class="tn-icon-phone"></text>
          </view>
          <view class="contact-info">
            <text class="contact-label">电话</text>
            <text class="contact-value">{{merchant.phone}}</text>
          </view>
          <text class="tn-icon-right"></text>
        </view>
      </view>
      
      <!-- 商家介绍 -->
      <view class="intro-card">
        <text class="card-title">商家介绍</text>
        <text class="intro-text">{{merchant.description}}</text>
      </view>
    </view>
    
    <!-- 底部操作栏 -->
    <view class="bottom-bar">
      <view class="action-btns">
        <view class="action-item">
          <text class="tn-icon-collection"></text>
          <text>收藏</text>
        </view>
        <view class="action-item">
          <text class="tn-icon-share"></text>
          <text>分享</text>
        </view>
      </view>
      <view class="call-btn" @click="callMerchant">
        <text class="tn-icon-phone"></text>
        <text>立即咨询</text>
      </view>
    </view>
  </view>
</template>

<script>
export default {
  data() {
    return {
      merchant: {
        id: 1,
        name: '张姐家政服务',
        category: '家政服务',
        rating: '4.9',
        images: ['https://resource.tuniaokj.com/images/avatar/xiong/x1.jpg', 'https://resource.tuniaokj.com/images/avatar/xiong/x1.jpg'],
        address: '小区东门50米，阳光商业街A座102',
        phone: '13888888888',
        tags: ['保洁', '月嫂', '钟点工', '家电清洗'],
        description: '专业家政服务10年，服务周到，价格实惠。我们的服务人员都经过专业培训，持证上岗，让您放心。\n\n服务项目：\n• 日常保洁 / 深度清洁\n• 月嫂服务 / 育儿嫂\n• 钟点工 / 住家保姆\n• 家电清洗（空调、油烟机、洗衣机等）\n\n营业时间：08:00 - 20:00\n服务范围：本小区及周边3公里'
      }
    }
  },
  onLoad(options) {
    if (options.id) {
      // this.loadMerchantDetail(options.id)
    }
  },
  methods: {
    goBack() { uni.navigateBack() },
    previewImage(index) {
      uni.previewImage({ urls: this.merchant.images, current: this.merchant.images[index] })
    },
    callMerchant() { uni.makePhoneCall({ phoneNumber: this.merchant.phone }) },
    openMap() { uni.showToast({ title: '地图功能开发中', icon: 'none' }) }
  }
}
</script>

<style lang="scss" scoped>
.container { min-height: 100vh; background: linear-gradient(180deg, #E8F4FD 0%, #D6EBFA 50%, #C4E2F7 100%); padding-bottom: 140rpx; }

.cover-swiper { height: 400rpx; image { width: 100%; height: 100%; } }

.back-btn {
  position: fixed; left: 24rpx; z-index: 100;
  width: 64rpx; height: 64rpx; background: rgba(0,0,0,0.3);
  border-radius: 50%; display: flex; align-items: center; justify-content: center;
  text { font-size: 36rpx; color: #fff; }
}

.content { padding: 0 24rpx; margin-top: -60rpx; position: relative; z-index: 10; }

.merchant-card {
  background: #fff; border-radius: 16rpx; padding: 24rpx;
  .merchant-header { display: flex; justify-content: space-between; align-items: center; }
  .merchant-name { font-size: 40rpx; color: #333; font-weight: bold; }
  .merchant-rating {
    display: flex; align-items: center;
    text:first-child { font-size: 32rpx; color: #FF9500; }
    .rating-score { font-size: 30rpx; color: #FF9500; font-weight: 500; margin-left: 6rpx; }
  }
  .merchant-category { display: block; font-size: 28rpx; color: #4A90E2; margin-top: 12rpx; }
  .merchant-tags {
    display: flex; flex-wrap: wrap; gap: 12rpx; margin-top: 16rpx;
    .tag { font-size: 24rpx; color: #666; background: #F5F5F5; padding: 8rpx 20rpx; border-radius: 20rpx; }
  }
}

.contact-card {
  background: #fff; border-radius: 16rpx; margin-top: 16rpx; overflow: hidden;
  .contact-item {
    display: flex; align-items: center; padding: 24rpx;
    border-bottom: 1rpx solid #F5F5F5;
    &:last-child { border-bottom: none; }
    .contact-icon {
      width: 72rpx; height: 72rpx; background: #E8F4FD; border-radius: 16rpx;
      display: flex; align-items: center; justify-content: center; margin-right: 20rpx;
      text { font-size: 36rpx; color: #4A90E2; }
      &.phone { background: #E8F5E9; text { color: #43E97B; } }
    }
    .contact-info { flex: 1; }
    .contact-label { display: block; font-size: 24rpx; color: #999; }
    .contact-value { display: block; font-size: 28rpx; color: #333; margin-top: 6rpx; }
    text:last-child { font-size: 28rpx; color: #ccc; }
  }
}

.intro-card {
  background: #fff; border-radius: 16rpx; padding: 24rpx; margin-top: 16rpx;
  .card-title { display: block; font-size: 32rpx; color: #333; font-weight: 500; margin-bottom: 16rpx; }
  .intro-text { font-size: 28rpx; color: #666; line-height: 1.8; white-space: pre-wrap; }
}

.bottom-bar {
  position: fixed; bottom: 0; left: 0; right: 0;
  display: flex; align-items: center; background: #fff;
  padding: 16rpx 24rpx; padding-bottom: calc(16rpx + env(safe-area-inset-bottom));
  box-shadow: 0 -2rpx 16rpx rgba(0,0,0,0.06);
  .action-btns {
    display: flex;
    .action-item {
      display: flex; flex-direction: column; align-items: center; margin-right: 40rpx;
      text { font-size: 24rpx; color: #666; &:first-child { font-size: 40rpx; } }
    }
  }
  .call-btn {
    flex: 1; background: linear-gradient(135deg, #5B9FE8, #4A90E2);
    color: #fff; height: 88rpx; border-radius: 44rpx;
    display: flex; align-items: center; justify-content: center;
    font-size: 32rpx; font-weight: 500;
    text { &:first-child { font-size: 36rpx; margin-right: 12rpx; } }
  }
}
</style>
