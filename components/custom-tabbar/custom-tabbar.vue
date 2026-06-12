<template>
  <view class="tabbar-wrapper" v-if="visibleTabs.length > 0">
    <view class="tabbar">
      <view 
        class="tabbar-item" 
        v-for="(item, index) in visibleTabs" 
        :key="index"
        @tap="handleTap(index)"
      >
        <!-- 中间凸起按钮 -->
        <view v-if="item.is_center" class="center-btn">
          <text :class="[item.selected_icon || item.icon, 'center-btn-icon']"></text>
        </view>
        <text v-if="item.is_center" class="tabbar-text-center">{{item.tab_name || item.text}}</text>
        <!-- 普通按钮 -->
        <view v-if="!item.is_center" class="icon-wrapper">
          <text :class="[isActive(item) ? (item.selected_icon || item.icon) : item.icon, isActive(item) ? 'tab-icon-active' : 'tab-icon']"></text>
        </view>
        <text v-if="!item.is_center" :class="isActive(item) ? 'tabbar-text-active' : 'tabbar-text'">{{item.tab_name || item.text}}</text>
      </view>
    </view>
  </view>
</template>

<script>
import { supabase } from '@/libs/supabase/supabase-mini.js'

export default {
  name: 'CustomTabbar',
  props: { current: { type: Number, default: 0 } },
  data() {
    return {
      centerPressed: false,
      currentPath: '',
      defaultTabList: [
        { tab_key: 'home', tab_name: '首页', icon: 'tn-icon-home', selected_icon: 'tn-icon-home-fill', path: '/pages/index/index', is_center: false },
        { tab_key: 'secondhand', tab_name: '闲置', icon: 'tn-icon-shopbag', selected_icon: 'tn-icon-shopbag-fill', path: '/pages/secondhand/secondhand', is_center: false },
        { tab_key: 'community', tab_name: '社区', icon: 'tn-icon-team', selected_icon: 'tn-icon-team-fill', path: '/pages/community/community', is_center: true },
        { tab_key: 'group', tab_name: '组团', icon: 'tn-icon-shop', selected_icon: 'tn-icon-shop-fill', path: '/pages/group/group', is_center: false },
        { tab_key: 'profile', tab_name: '我的', icon: 'tn-icon-my', selected_icon: 'tn-icon-my-fill', path: '/pages/profile/profile', is_center: false },
        { tab_key: 'notice', tab_name: '公告', icon: 'tn-icon-notice', selected_icon: 'tn-icon-notice-fill', path: '/pages/notice/notice', is_center: false }
      ]
    }
  },
  computed: {
    visibleTabs() {
      const config = this.vuex_tabbar_config
      if (config && Array.isArray(config) && config.length > 0) {
        return config
      }
      return this.defaultTabList
    }
  },
  created() {
    this.loadTabbarConfig()
  },
  mounted() {
    // console.log('[Tabbar] mounted, visibleTabs:', JSON.stringify(this.visibleTabs))
  },
  watch: {
    visibleTabs: {
      handler(val) {
        // console.log('[Tabbar] visibleTabs changed:', JSON.stringify(val))
      },
      immediate: true
    }
  },
  methods: {
    getCurrentPath() {
      const pages = getCurrentPages()
      if (pages.length > 0) {
        return '/' + pages[pages.length - 1].route
      }
      return ''
    },
    async loadTabbarConfig() {
      if (this.vuex_tabbar_loaded && this.vuex_tabbar_config) return
      
      try {
        const { data, error } = await supabase.rpc('get_tabbar_config')
        
        if (error) {
          console.log('加载tabbar配置失败，使用默认配置:', error)
          return
        }
        
        if (data && data.length > 0) {
          this.$t.vuex('vuex_tabbar_config', data)
          this.$t.vuex('vuex_tabbar_loaded', true)
        }
      } catch (e) {
        console.log('tabbar配置请求异常:', e)
      }
    },
    isActive(item) {
      const current = this.getCurrentPath()
      return item.path === current
    },
    handleTap(index) {
      const item = this.visibleTabs[index]
      // console.log('[Tabbar] handleTap index:', index, 'item:', item)
      if (!item || !item.path) {
        // console.log('[Tabbar] item or path is empty')
        return
      }
      const current = this.getCurrentPath()
      // console.log('[Tabbar] current:', current, 'target:', item.path)
      if (item.path === current) {
        // console.log('[Tabbar] same page, skip')
        return
      }
      // console.log('[Tabbar] switching to:', item.path)
      uni.switchTab({ 
        url: item.path,
        success: () => console.log('[Tabbar] switch success'),
        fail: (err) => console.log('[Tabbar] switch fail:', err)
      })
    }
  }
}
</script>

<style scoped>
.tabbar-wrapper {
  position: fixed; bottom: 0; left: 0; right: 0; z-index: 999;
  background: #fff; padding-bottom: env(safe-area-inset-bottom);
  box-shadow: 0 -4rpx 20rpx rgba(0, 0, 0, 0.06);
}
.tabbar {
  display: flex; justify-content: space-around; align-items: flex-end;
  height: 120rpx; background: #fff;
}
.tabbar-item {
  flex: 1; display: flex; flex-direction: column; align-items: center;
  justify-content: flex-end; height: 100%; padding-bottom: 16rpx;
}
.icon-wrapper {
  width: 56rpx; height: 56rpx; display: flex; align-items: center; justify-content: center;
  margin-bottom: 4rpx;
}
.tab-icon { font-size: 48rpx; color: #BFBFBF; transition: all 0.2s; }
.tab-icon-active { font-size: 48rpx; color: #4A90E2; transition: all 0.2s; }
.tabbar-text { font-size: 22rpx; color: #BFBFBF; transition: all 0.2s; }
.tabbar-text-active { font-size: 22rpx; color: #4A90E2; font-weight: 500; transition: all 0.2s; }
.tabbar-text-center { font-size: 22rpx; color: #4A90E2; font-weight: 500; }
.center-btn {
  width: 108rpx; height: 108rpx; border-radius: 50%;
  background: linear-gradient(145deg, #5B9FE8, #4A90E2);
  display: flex; align-items: center; justify-content: center;
  margin-top: -54rpx; margin-bottom: 6rpx;
  box-shadow: 0 8rpx 24rpx rgba(74, 144, 226, 0.45);
  transition: all 0.15s ease;
  border: 4rpx solid #fff;
}
.center-btn-pressed {
  transform: scale(0.92);
  box-shadow: 0 4rpx 12rpx rgba(74, 144, 226, 0.35);
}
.center-btn-icon { font-size: 48rpx; color: #fff; }
</style>
