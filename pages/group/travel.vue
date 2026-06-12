<template>
  <view class="container">
    <!-- 顶部导航 -->
    <view class="nav-header" :style="{paddingTop: vuex_status_bar_height + 'px'}">
      <view class="nav-bar">
        <text class="tn-icon-left nav-back" @click="goBack"></text>
        <text class="nav-title">周边组团</text>
        <view class="nav-placeholder"></view>
      </view>
    </view>
    
    <!-- 旅游列表 -->
    <view class="travel-list">
      <view class="travel-card" v-for="(item, index) in travelList" :key="index" @click="goDetail(item)">
        <image class="travel-image" :src="item.image" mode="aspectFill"></image>
        <view class="travel-info">
          <view class="travel-header">
            <text class="travel-tag">{{item.tag}}</text>
            <text class="travel-status" :class="item.status">{{item.statusText}}</text>
          </view>
          <text class="travel-title">{{item.title}}</text>
          <text class="travel-desc">{{item.desc}}</text>
          <view class="travel-footer">
            <view class="organizer">
              <image class="organizer-avatar" :src="item.organizerAvatar" mode="aspectFill"></image>
              <text class="organizer-name">{{item.organizer}}</text>
            </view>
            <text class="travel-people">{{item.joined}}/{{item.total}}人</text>
          </view>
        </view>
      </view>
    </view>
  </view>
</template>

<script>
export default {
  data() {
    return {
      travelList: [
        {
          id: 1, tag: '周末露营', title: '大鹏较场尾海边露营',
          desc: '周六下午出发，搭帐篷看日落，晚上BBQ，周日早上看日出',
          image: 'https://picsum.photos/seed/camping/800/400',
          joined: 8, total: 15, status: 'ongoing', statusText: '报名中',
          organizer: '3栋李哥', organizerAvatar: 'https://picsum.photos/seed/user1/100/100'
        },
        {
          id: 2, tag: '爬山徒步', title: '凤凰山登山活动',
          desc: '周日早上8点小区门口集合，一起爬凤凰山，山顶俯瞰深圳',
          image: 'https://picsum.photos/seed/mountain/800/400',
          joined: 12, total: 20, status: 'ongoing', statusText: '报名中',
          organizer: '5栋王姐', organizerAvatar: 'https://picsum.photos/seed/user2/100/100'
        },
        {
          id: 3, tag: '亲子活动', title: '莲花山公园放风筝',
          desc: '带娃一起去莲花山放风筝，草坪野餐，遛娃好去处',
          image: 'https://picsum.photos/seed/park/800/400',
          joined: 6, total: 10, status: 'ongoing', statusText: '报名中',
          organizer: '1栋陈妈', organizerAvatar: 'https://picsum.photos/seed/user3/100/100'
        },
        {
          id: 4, tag: '户外烧烤', title: '光明农场烧烤聚会',
          desc: '自驾去光明农场，食材AA，一起动手烤肉，享受周末时光',
          image: 'https://picsum.photos/seed/bbq/800/400',
          joined: 10, total: 10, status: 'full', statusText: '已满员',
          organizer: '2栋张哥', organizerAvatar: 'https://picsum.photos/seed/user4/100/100'
        },
        {
          id: 5, tag: '骑行运动', title: '深圳湾骑行看日落',
          desc: '傍晚5点深圳湾集合，沿海骑行，看最美日落',
          image: 'https://picsum.photos/seed/cycling/800/400',
          joined: 15, total: 15, status: 'ended', statusText: '已结束',
          organizer: '6栋小刘', organizerAvatar: 'https://picsum.photos/seed/user5/100/100'
        }
      ]
    }
  },
  methods: {
    goBack() { uni.navigateBack() },
    goDetail(item) {
      uni.navigateTo({ url: '/pages/group/travel-detail?id=' + item.id })
    }
  }
}
</script>

<style scoped>
.container { min-height: 100vh; background: #F5F7FA; padding-bottom: 120rpx; }
.nav-header { background: linear-gradient(135deg, #4A90E2, #357ABD); }
.nav-bar { display: flex; align-items: center; justify-content: space-between; padding: 20rpx 24rpx 30rpx; }
.nav-back { font-size: 40rpx; color: #fff; padding: 10rpx; }
.nav-title { font-size: 34rpx; color: #fff; font-weight: 500; }
.nav-placeholder { width: 60rpx; }
.travel-list { padding: 24rpx; }
.travel-card { background: #fff; border-radius: 20rpx; overflow: hidden; margin-bottom: 24rpx; box-shadow: 0 4rpx 16rpx rgba(0,0,0,0.06); }
.travel-image { width: 100%; height: 280rpx; }
.travel-info { padding: 24rpx; }
.travel-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 12rpx; }
.travel-tag { font-size: 22rpx; color: #fff; background: linear-gradient(135deg, #4A90E2, #357ABD); padding: 6rpx 16rpx; border-radius: 6rpx; }
.travel-status { font-size: 22rpx; padding: 6rpx 16rpx; border-radius: 6rpx; }
.travel-status.ongoing { color: #52C41A; background: #F6FFED; }
.travel-status.full { color: #FF9500; background: #FFF7E6; }
.travel-status.ended { color: #999; background: #F5F5F5; }
.travel-title { display: block; font-size: 32rpx; color: #333; font-weight: 500; margin-bottom: 10rpx; }
.travel-desc { display: block; font-size: 26rpx; color: #666; line-height: 1.5; margin-bottom: 16rpx; }
.travel-footer { display: flex; align-items: center; justify-content: space-between; }
.organizer { display: flex; align-items: center; }
.organizer-avatar { width: 48rpx; height: 48rpx; border-radius: 50%; margin-right: 12rpx; }
.organizer-name { font-size: 24rpx; color: #666; }
.travel-people { font-size: 24rpx; color: #4A90E2; }
</style>
