<template>
  <view class="container">
    <!-- 顶部导航 -->
    <view class="nav-bar" :style="{paddingTop: (vuex_status_bar_height + 10) + 'px'}">
      <view class="nav-content">
        <text class="nav-title">优质商家</text>
        <view class="nav-search" @click="goSearch">
          <text class="tn-icon-search"></text>
        </view>
      </view>
    </view>
    
    <view class="content" :style="{paddingTop: (vuex_status_bar_height + 54) + 'px'}">
      <!-- 分类筛选 -->
      <scroll-view scroll-x class="category-scroll">
        <view class="category-list">
          <view 
            :class="['category-item', currentCategory === index ? 'active' : '']"
            v-for="(item, index) in categories" 
            :key="index"
            @click="currentCategory = index"
          >{{item}}</view>
        </view>
      </scroll-view>
      
      <!-- 商家列表 -->
      <view class="merchant-list">
        <view class="merchant-card" v-for="(item, index) in merchantList" :key="index" @click="goDetail(item)">
          <image class="merchant-cover" :src="item.image" mode="aspectFill"></image>
          <view class="merchant-info">
            <view class="merchant-header">
              <text class="merchant-name">{{item.name}}</text>
              <view class="merchant-rating">
                <text class="tn-icon-star-fill" style="color: #FF9500;"></text>
                <text class="rating-score">{{item.rating}}</text>
              </view>
            </view>
            <text class="merchant-category">{{item.category}}</text>
            <view class="merchant-tags">
              <text class="tag" v-for="(tag, tagIndex) in item.tags" :key="tagIndex">{{tag}}</text>
            </view>
            <view class="merchant-location">
              <text class="tn-icon-map"></text>
              <text>{{item.address}}</text>
              <text class="distance">{{item.distance}}</text>
            </view>
          </view>
        </view>
      </view>
    </view>
    
    <!-- 自定义tabbar -->
    <custom-tabbar :current="1"></custom-tabbar>
  </view>
</template>

<script>
export default {
  data() {
    return {
      currentCategory: 0,
      categories: ['全部', '家政', '维修', '餐饮', '教育', '医疗', '美容', '其他'],
      merchantList: [
        {
          id: 1, name: '张姐家政服务', category: '家政服务', rating: '4.9',
          image: 'https://resource.tuniaokj.com/images/avatar/xiong/x2.jpg', address: '小区东门50米', distance: '200m',
          tags: ['保洁', '月嫂', '钟点工'], phone: '13888888888'
        },
        {
          id: 2, name: '老王维修铺', category: '维修服务', rating: '4.8',
          image: 'https://resource.tuniaokj.com/images/avatar/xiong/x5.jpg', address: '小区南门100米', distance: '350m',
          tags: ['水电', '家电', '开锁'], phone: '13999999999'
        },
        {
          id: 3, name: '小厨娘私房菜', category: '美食餐饮', rating: '4.7',
          image: 'https://resource.tuniaokj.com/images/avatar/xiong/x9.jpg', address: '小区内3栋底商', distance: '50m',
          tags: ['外卖', '堂食', '预订'], phone: '13777777777'
        },
        {
          id: 4, name: '阳光幼儿托管', category: '教育培训', rating: '4.9',
          image: 'https://resource.tuniaokj.com/images/avatar/xiong/x13.jpg', address: '小区西门200米', distance: '500m',
          tags: ['托管', '辅导', '兴趣班'], phone: '13666666666'
        }
      ]
    }
  },
  methods: {
    goSearch() { uni.showToast({ title: '搜索功能开发中', icon: 'none' }) },
    goDetail(item) { uni.navigateTo({ url: '/pages/merchant/detail?id=' + item.id }) }
  }
}
</script>

<style lang="scss" scoped>
.container { min-height: 100vh; background: linear-gradient(180deg, #E8F4FD 0%, #D6EBFA 50%, #C4E2F7 100%); }

.nav-bar {
  position: fixed; top: 0; left: 0; right: 0; z-index: 100;
  background: linear-gradient(135deg, #4A90E2, #357ABD);
  .nav-content {
    display: flex; justify-content: space-between; align-items: center;
    height: 88rpx; padding: 0 24rpx;
  }
  .nav-title { font-size: 36rpx; color: #fff; font-weight: bold; }
  .nav-search text { font-size: 40rpx; color: #fff; }
}

.content { padding-bottom: 200rpx; }

.category-scroll {
  background: transparent; white-space: nowrap; padding: 20rpx 0;
  .category-list { display: inline-flex; padding: 0 16rpx; }
  .category-item {
    padding: 14rpx 28rpx; margin: 0 8rpx; font-size: 28rpx;
    color: #666; background: #fff; border-radius: 32rpx;
    &.active { background: linear-gradient(135deg, #5B9FE8, #4A90E2); color: #fff; }
  }
}

.merchant-list {
  padding: 16rpx;
  .merchant-card {
    display: flex; background: #fff; border-radius: 16rpx;
    padding: 20rpx; margin-bottom: 16rpx;
    box-shadow: 0 2rpx 12rpx rgba(0,0,0,0.04);
    .merchant-cover { width: 180rpx; height: 180rpx; border-radius: 12rpx; margin-right: 20rpx; }
    .merchant-info { flex: 1; display: flex; flex-direction: column; justify-content: space-between; }
    .merchant-header { display: flex; justify-content: space-between; align-items: center; }
    .merchant-name { font-size: 32rpx; color: #333; font-weight: 500; }
    .merchant-rating {
      display: flex; align-items: center;
      .rating-score { font-size: 26rpx; color: #FF9500; margin-left: 4rpx; font-weight: 500; }
    }
    .merchant-category { font-size: 26rpx; color: #4A90E2; margin-top: 8rpx; }
    .merchant-tags {
      display: flex; flex-wrap: wrap; gap: 8rpx; margin-top: 8rpx;
      .tag {
        font-size: 22rpx; color: #666; background: #F5F5F5;
        padding: 6rpx 14rpx; border-radius: 4rpx;
      }
    }
    .merchant-location {
      display: flex; align-items: center; margin-top: 8rpx;
      text { font-size: 24rpx; color: #999; &:first-child { margin-right: 6rpx; } }
      .distance { margin-left: auto; color: #4A90E2; }
    }
  }
}
</style>
