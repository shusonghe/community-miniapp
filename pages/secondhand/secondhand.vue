<template>
  <view class="container">
    <!-- 顶部导航 -->
    <view class="nav-bar" :style="{paddingTop: vuex_status_bar_height + 'px'}">
      <view class="nav-content">
        <text class="nav-title">二手闲置</text>
      </view>
    </view>
    
    <view class="content" :style="{paddingTop: (vuex_status_bar_height + 54) + 'px'}">
      <!-- 搜索栏 -->
      <view class="search-bar">
        <view class="search-input-wrap">
          <text class="tn-icon-search"></text>
          <input class="search-input" v-model="keyword" placeholder="搜索闲置宝贝" confirm-type="search" @confirm="onSearch" />
        </view>
      </view>
      
      <!-- 分类筛选 -->
      <scroll-view scroll-x class="category-scroll">
        <view class="category-list">
          <view 
            :class="['category-item', currentCategory === item ? 'active' : '']"
            v-for="(item, index) in categories" 
            :key="index"
            @click="selectCategory(item)"
          >{{item}}</view>
        </view>
      </scroll-view>
      
      <!-- 商品瀑布流 -->
      <view class="goods-waterfall" v-if="goodsList.length > 0">
        <view class="waterfall-column">
          <view class="goods-card" v-for="(item, index) in leftGoods" :key="index" @click="goDetail(item)">
            <image class="goods-img" :src="item.images[0]" mode="widthFix"></image>
            <view class="goods-info">
              <text class="goods-title">{{item.title}}</text>
              <view class="goods-price-row">
                <text class="goods-price">¥{{item.price}}</text>
                <text class="original-price" v-if="item.original_price">¥{{item.original_price}}</text>
              </view>
              <view class="seller-row">
                <image class="seller-avatar" :src="item.avatar_url || defaultAvatar"></image>
                <text class="seller-name">{{item.nickname}}</text>
              </view>
            </view>
          </view>
        </view>
        <view class="waterfall-column">
          <view class="goods-card" v-for="(item, index) in rightGoods" :key="index" @click="goDetail(item)">
            <image class="goods-img" :src="item.images[0]" mode="widthFix"></image>
            <view class="goods-info">
              <text class="goods-title">{{item.title}}</text>
              <view class="goods-price-row">
                <text class="goods-price">¥{{item.price}}</text>
                <text class="original-price" v-if="item.original_price">¥{{item.original_price}}</text>
              </view>
              <view class="seller-row">
                <image class="seller-avatar" :src="item.avatar_url || defaultAvatar"></image>
                <text class="seller-name">{{item.nickname}}</text>
              </view>
            </view>
          </view>
        </view>
      </view>
      
      <!-- 空状态 -->
      <view class="empty-state" v-else-if="!loading">
        <text class="tn-icon-shop"></text>
        <text class="empty-text">暂无闲置商品</text>
      </view>
      
      <!-- 加载更多 -->
      <view class="load-more" v-if="goodsList.length > 0">
        <text v-if="loading">加载中...</text>
        <text v-else-if="noMore">没有更多了</text>
      </view>
    </view>
    
    <!-- 自定义tabbar -->
    <custom-tabbar :current="1"></custom-tabbar>
    
    <!-- 悬浮按钮 -->
    <view class="publish-btn" @click="goPublish" v-if="showFabBtn">
      <text class="tn-icon-add"></text>
    </view>
    
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
      defaultAvatar: 'https://img.icons8.com/?size=100&id=s4mUhvTRUkP2&format=png&color=000000&padding=30',
      currentCategory: '全部',
      categories: ['全部', '家具', '电器', '数码', '服饰', '母婴', '图书', '其他'],
      keyword: '',
      goodsList: [],
      loading: false,
      noMore: false,
      page: 0,
      pageSize: 20
    }
  },
  computed: {
    leftGoods() { return this.goodsList.filter((_, i) => i % 2 === 0) },
    rightGoods() { return this.goodsList.filter((_, i) => i % 2 === 1) },
    showFabBtn() {
      const config = this.vuex_tabbar_config
      return config && Array.isArray(config) && config.length > 1
    }
  },
  onLoad() {
    this.loadData()
  },
  onShow() {
    // 每次显示页面时刷新数据
    this.page = 0
    this.noMore = false
    this.goodsList = []
    this.loadData()
  },
  onPullDownRefresh() {
    this.page = 0
    this.noMore = false
    this.goodsList = []
    this.loadData().then(() => uni.stopPullDownRefresh())
  },
  onReachBottom() {
    if (!this.loading && !this.noMore) {
      this.loadData()
    }
  },
  methods: {
    async loadData() {
      if (this.loading) return
      this.loading = true
      
      try {
        const user = auth.getLocalUser()
        const { data, error } = await supabase.rpc('get_secondhand_items', {
          p_user_id: user ? user.id : null,
          p_category: this.currentCategory === '全部' ? null : this.currentCategory,
          p_keyword: this.keyword || null,
          p_limit: this.pageSize,
          p_offset: this.page * this.pageSize
        })
        
        console.log('闲置列表:', data, error)
        
        if (error) throw error
        
        const items = data || []
        if (items.length < this.pageSize) {
          this.noMore = true
        }
        
        this.goodsList = this.page === 0 ? items : [...this.goodsList, ...items]
        this.page++
      } catch (e) {
        console.error('加载闲置列表失败:', e)
        uni.showToast({ title: '加载失败', icon: 'none' })
      } finally {
        this.loading = false
      }
    },
    selectCategory(category) {
      if (this.currentCategory === category) return
      this.currentCategory = category
      this.page = 0
      this.noMore = false
      this.goodsList = []
      this.loadData()
    },
    onSearch() {
      this.page = 0
      this.noMore = false
      this.goodsList = []
      this.loadData()
    },
    goPublish() {
      // 检查微信用户权限
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
      uni.navigateTo({ url: '/pages/secondhand/publish' })
    },
    goDetail(item) { 
      if (!this.requireLogin()) return
      uni.navigateTo({ url: '/pages/secondhand/detail?id=' + item.id })
    }
  }
}
</script>

<style lang="scss" scoped>
.container { min-height: 100vh; background: linear-gradient(180deg, #E8F4FD 0%, #D6EBFA 50%, #C4E2F7 100%); }

.nav-bar {
  position: fixed; top: 0; left: 0; right: 0; z-index: 100;
  background: linear-gradient(135deg, #4A90E2, #357ABD);
  .nav-content {
    display: flex; justify-content: center; align-items: center;
    height: 88rpx; padding: 0 24rpx;
  }
  .nav-title { font-size: 36rpx; color: #fff; font-weight: bold; }
}

.content { padding-bottom: 200rpx; }

.search-bar {
  padding: 16rpx 24rpx;
  .search-input-wrap {
    display: flex; align-items: center; background: #fff;
    border-radius: 36rpx; padding: 0 24rpx; height: 72rpx;
    text { font-size: 32rpx; color: #999; margin-right: 12rpx; }
    .search-input { flex: 1; font-size: 28rpx; }
  }
}

.category-scroll {
  background: transparent; white-space: nowrap; padding: 8rpx 0 20rpx;
  .category-list { display: inline-flex; padding: 0 16rpx; }
  .category-item {
    padding: 14rpx 28rpx; margin: 0 8rpx; font-size: 28rpx;
    color: #666; background: #fff; border-radius: 32rpx;
  }
  .category-item.active { background: linear-gradient(135deg, #5B9FE8, #4A90E2); color: #fff; }
}

.goods-waterfall {
  display: flex; padding: 16rpx; gap: 16rpx;
  .waterfall-column { flex: 1; display: flex; flex-direction: column; gap: 16rpx; }
  .goods-card {
    background: #fff; border-radius: 16rpx; overflow: hidden;
    box-shadow: 0 2rpx 12rpx rgba(0,0,0,0.04);
    .goods-img { width: 100%; height: auto; min-height: 200rpx; max-height: 400rpx; }
    .goods-info { padding: 16rpx; }
    .goods-title {
      font-size: 28rpx; color: #333; line-height: 1.4;
      display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;
    }
    .goods-price-row { margin-top: 12rpx; }
    .goods-price { font-size: 36rpx; color: #4A90E2; font-weight: bold; }
    .original-price { font-size: 24rpx; color: #999; text-decoration: line-through; margin-left: 8rpx; }
    .seller-row {
      display: flex; align-items: center; margin-top: 12rpx;
      .seller-avatar { width: 36rpx; height: 36rpx; border-radius: 50%; margin-right: 8rpx; }
      .seller-name { font-size: 24rpx; color: #999; }
    }
  }
}

.empty-state {
  display: flex; flex-direction: column; align-items: center;
  padding: 120rpx 0;
  text { color: #ccc; }
  text:first-child { font-size: 120rpx; }
  .empty-text { font-size: 28rpx; margin-top: 20rpx; }
}

.load-more {
  text-align: center; padding: 30rpx;
  text { font-size: 26rpx; color: #999; }
}

.publish-btn {
  position: fixed; right: 32rpx; bottom: 260rpx;
  width: 100rpx; height: 100rpx;
  background: linear-gradient(135deg, #5B9FE8, #4A90E2);
  border-radius: 50%; display: flex; align-items: center; justify-content: center;
  box-shadow: 0 8rpx 24rpx rgba(74, 144, 226, 0.4);
  text { font-size: 44rpx; color: #fff; }
}
</style>
