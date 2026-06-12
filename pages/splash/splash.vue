<template>
  <view class="splash">
    <!-- 背景装饰圆 -->
    <view class="bg-circle circle-1"></view>
    <view class="bg-circle circle-2"></view>
    <view class="bg-circle circle-3"></view>
    
    <view class="content">
      <!-- Logo 动画 -->
      <view class="logo-wrapper" :class="{ 'animate': showAnimation }">
        <view class="logo-icon">
          <text class="tn-icon-home-fill"></text>
        </view>
        <text class="logo-text">珈邻</text>
      </view>
      
      <!-- 欢迎语 -->
      <view class="welcome" :class="{ 'fade-in': showWelcome }">
        <text class="welcome-text">Hi，欢迎你 👋</text>
        <text class="slogan">邻里互助 · 温暖相伴</text>
      </view>
      
      <!-- 加载指示器 -->
      <view class="loading-wrapper" :class="{ 'fade-in': showLoading }">
        <view class="loading-bar">
          <view class="loading-progress"></view>
        </view>
      </view>
    </view>
    
    <!-- 底部 -->
    <view class="footer">
      <text class="version">v1.1.2</text>
    </view>
  </view>
</template>

<script>
import { supabase } from '@/libs/supabase/supabase-mini.js'

export default {
  data() {
    return {
      showAnimation: false,
      showWelcome: false,
      showLoading: false
    }
  },
  onLoad() {
    // 分阶段显示动画
    setTimeout(() => { this.showAnimation = true }, 100)
    setTimeout(() => { this.showWelcome = true }, 400)
    setTimeout(() => { this.showLoading = true }, 600)
    
    // 初始化并跳转
    this.init()
  },
  methods: {
    async init() {
      try {
        const { data, error } = await supabase.rpc('get_tabbar_config')
        
        if (!error && data && data.length > 0) {
          this.$t.vuex('vuex_tabbar_config', data)
          this.$t.vuex('vuex_tabbar_loaded', true)
          
          // 1秒后跳转（配合进度条动画）
          setTimeout(() => {
            if (data.length === 1) {
              uni.switchTab({ url: '/pages/notice/notice' })
            } else {
              uni.switchTab({ url: '/pages/index/index' })
            }
          }, 1000)
          return
        }
        
        setTimeout(() => {
          uni.switchTab({ url: '/pages/index/index' })
        }, 1000)
      } catch (e) {
        console.log('启动页初始化异常:', e)
        setTimeout(() => {
          uni.switchTab({ url: '/pages/index/index' })
        }, 1000)
      }
    }
  }
}
</script>

<style scoped>
.splash {
  min-height: 100vh;
  background: linear-gradient(160deg, #5B9FE8 0%, #4A90E2 30%, #357ABD 70%, #2563A8 100%);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  position: relative;
  overflow: hidden;
}

/* 背景装饰圆 */
.bg-circle {
  position: absolute;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.08);
}

.circle-1 {
  width: 600rpx;
  height: 600rpx;
  top: -200rpx;
  right: -200rpx;
  animation: float 6s ease-in-out infinite;
}

.circle-2 {
  width: 400rpx;
  height: 400rpx;
  bottom: 100rpx;
  left: -150rpx;
  animation: float 8s ease-in-out infinite reverse;
}

.circle-3 {
  width: 300rpx;
  height: 300rpx;
  top: 40%;
  right: -100rpx;
  background: rgba(255, 255, 255, 0.05);
  animation: float 7s ease-in-out infinite 1s;
}

@keyframes float {
  0%, 100% { transform: translateY(0) scale(1); }
  50% { transform: translateY(-30rpx) scale(1.05); }
}

.content {
  display: flex;
  flex-direction: column;
  align-items: center;
  z-index: 1;
}

/* Logo 样式 */
.logo-wrapper {
  display: flex;
  flex-direction: column;
  align-items: center;
  opacity: 0;
  transform: translateY(60rpx);
  transition: all 0.8s cubic-bezier(0.34, 1.56, 0.64, 1);
}

.logo-wrapper.animate {
  opacity: 1;
  transform: translateY(0);
}

.logo-icon {
  width: 160rpx;
  height: 160rpx;
  background: rgba(255, 255, 255, 0.2);
  border-radius: 40rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 32rpx;
  backdrop-filter: blur(10px);
  box-shadow: 0 16rpx 48rpx rgba(0, 0, 0, 0.15);
}

.logo-icon text {
  font-size: 80rpx;
  color: #fff;
}

.logo-text {
  font-size: 72rpx;
  font-weight: 700;
  color: #fff;
  letter-spacing: 12rpx;
  text-shadow: 0 4rpx 24rpx rgba(0, 0, 0, 0.2);
  font-family: -apple-system, BlinkMacSystemFont, 'PingFang SC', 'Helvetica Neue', sans-serif;
}

/* 欢迎语 */
.welcome {
  margin-top: 64rpx;
  display: flex;
  flex-direction: column;
  align-items: center;
  opacity: 0;
  transform: translateY(30rpx);
  transition: all 0.6s ease;
}

.welcome.fade-in {
  opacity: 1;
  transform: translateY(0);
}

.welcome-text {
  font-size: 40rpx;
  color: #fff;
  font-weight: 600;
  margin-bottom: 20rpx;
  font-family: -apple-system, BlinkMacSystemFont, 'PingFang SC', 'Helvetica Neue', sans-serif;
}

.slogan {
  font-size: 28rpx;
  color: rgba(255, 255, 255, 0.75);
  letter-spacing: 4rpx;
  font-family: -apple-system, BlinkMacSystemFont, 'PingFang SC', 'Helvetica Neue', sans-serif;
}

/* 加载指示器 */
.loading-wrapper {
  margin-top: 100rpx;
  width: 200rpx;
  opacity: 0;
  transition: all 0.5s ease;
}

.loading-wrapper.fade-in {
  opacity: 1;
}

.loading-bar {
  width: 100%;
  height: 6rpx;
  background: rgba(255, 255, 255, 0.2);
  border-radius: 3rpx;
  overflow: hidden;
}

.loading-progress {
  width: 0%;
  height: 100%;
  background: linear-gradient(90deg, rgba(255,255,255,0.5), rgba(255,255,255,0.8), #fff);
  border-radius: 3rpx;
  animation: progress 1.2s cubic-bezier(0.25, 0.46, 0.45, 0.94) forwards;
  box-shadow: 0 0 16rpx rgba(255, 255, 255, 0.6);
}

@keyframes progress {
  0% { width: 0%; }
  15% { width: 10%; }
  30% { width: 25%; }
  50% { width: 45%; }
  70% { width: 65%; }
  85% { width: 85%; }
  100% { width: 100%; }
}

/* 底部 */
.footer {
  position: absolute;
  bottom: 80rpx;
  left: 0;
  right: 0;
  text-align: center;
  padding-bottom: env(safe-area-inset-bottom);
}

.version {
  font-size: 24rpx;
  color: rgba(255, 255, 255, 0.4);
  font-family: -apple-system, BlinkMacSystemFont, 'SF Mono', monospace;
}
</style>
