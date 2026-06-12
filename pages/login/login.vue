<template>
  <view class="container">
    <!-- 顶部装饰背景 -->
    <view class="header-bg">
      <view class="bg-circle circle-1"></view>
      <view class="bg-circle circle-2"></view>
      <view class="bg-circle circle-3"></view>
    </view>
    
    <view class="login-content">
      <!-- Logo区域 -->
      <view class="logo-section" :style="{ paddingTop: (statusBarHeight + 30) + 'px' }">
        <view class="logo-wrapper">
          <view class="logo-circle">
            <text class="logo-text">珈邻</text>
          </view>
          <view class="logo-glow"></view>
        </view>
        <!-- <text class="app-name">您的邻里生活服务平台</text> -->
        <text class="app-slogan">您的邻里生活服务平台</text>
      </view>
      
      <!-- 登录表单卡片 -->
      <view class="login-form">
        <view class="form-title">账号登录</view>
        
        <view class="form-item" :class="{ 'form-item-focus': phoneFocus }">
          <view class="form-icon">
            <text class="tn-icon-my"></text>
          </view>
          <input
            class="input"
            v-model="form.phone"
            placeholder="请输入手机号"
            type="number"
            maxlength="11"
            @focus="phoneFocus = true"
            @blur="phoneFocus = false"
          />
          <view class="input-clear" v-if="form.phone" @click="form.phone = ''">
            <text class="tn-icon-close-circle-fill"></text>
          </view>
        </view>
        
        <view class="form-item" :class="{ 'form-item-focus': passwordFocus }">
          <view class="form-icon">
            <text class="tn-icon-lock"></text>
          </view>
          <input
            class="input"
            v-model="form.password"
            placeholder="请输入密码"
            :password="!showPassword"
            @focus="passwordFocus = true"
            @blur="passwordFocus = false"
          />
          <view class="password-toggle" @click="showPassword = !showPassword">
            <text :class="showPassword ? 'tn-icon-eye' : 'tn-icon-eye-hide'"></text>
          </view>
        </view>
        
        <button class="login-btn" @click="login" :disabled="loading">
          <text v-if="!loading">登 录</text>
          <view v-else class="loading-wrap">
            <view class="loading-spinner"></view>
            <text>登录中...</text>
          </view>
        </button>
        
        <view class="login-links">
          <view class="link-item" @click="goRegister">
            <text class="tn-icon-add-circle"></text>
            <text>新用户注册</text>
          </view>
          <view class="link-item" @click="goReset">
            <text class="tn-icon-help"></text>
            <text>忘记密码</text>
          </view>
        </view>
        
        <!-- 分割线 -->
        <view class="divider">
          <view class="divider-line"></view>
          <text class="divider-text">快捷入口</text>
          <view class="divider-line"></view>
        </view>
        
        <!-- 游客浏览入口 -->
        <view class="guest-section">
          <view class="guest-card" @click="wechatLogin">
            <view class="guest-icon-wrap">
              <view class="guest-icon">
                <text class="tn-icon-wechat-fill"></text>
              </view>
            </view>
            <view class="guest-info">
              <text class="guest-title">游客浏览</text>
              <text class="guest-desc">使用微信快速进入，仅支持浏览内容</text>
            </view>
            <view class="guest-arrow">
              <text class="tn-icon-right"></text>
            </view>
          </view>
        </view>
        
        <!-- 协议勾选 -->
        <view class="agreement">
          <view class="check-wrap" @click="agreed = !agreed">
            <view :class="['checkbox', agreed ? 'checked' : '']">
              <text class="tn-icon-success" v-if="agreed"></text>
            </view>
          </view>
          <view class="agreement-text">
            <text>登录即表示同意</text>
            <text class="link" @click.stop="goAgreement('user')">《用户协议》</text>
            <text>和</text>
            <text class="link" @click.stop="goAgreement('privacy')">《隐私政策》</text>
          </view>
        </view>
      </view>
      
      <!-- 底部版权 -->
      <view class="footer">
        <text>© 2026 珈邻 版权所有</text>
      </view>
    </view>
  </view>
</template>

<script>
import { auth } from '@/libs/supabase'

export default {
  data() {
    return {
      form: { phone: '', password: '' },
      loading: false,
      wxLoading: false,
      agreed: false,
      phoneFocus: false,
      passwordFocus: false,
      showPassword: false,
      statusBarHeight: 0
    }
  },
  onLoad() {
    // 获取系统信息，适配刘海屏
    const systemInfo = uni.getSystemInfoSync()
    this.statusBarHeight = systemInfo.statusBarHeight || 20
  },
  methods: {
    checkAgreement() {
      if (!this.agreed) {
        uni.showToast({ title: '请先同意用户协议和隐私政策', icon: 'none' })
        return false
      }
      return true
    },
    async login() {
      if (!this.form.phone || this.form.phone.length !== 11) {
        return uni.showToast({ title: '请输入正确的手机号', icon: 'none' })
      }
      if (!this.form.password) {
        return uni.showToast({ title: '请输入密码', icon: 'none' })
      }
      if (!this.checkAgreement()) return
      
      this.loading = true
      uni.showLoading({ title: '登录中...' })
      
      const { data, error } = await auth.signIn(this.form.phone, this.form.password)
      
      uni.hideLoading()
      this.loading = false
      
      if (error) {
        return uni.showToast({ title: error.message || '登录失败', icon: 'none' })
      }
      
      uni.$emit('loginStatusChanged', { isLogin: true })
      uni.showToast({ title: '登录成功', icon: 'success' })
      setTimeout(() => this.goBackOrHome(), 1500)
    },
    
    async wechatLogin() {
      if (!this.checkAgreement()) return
      
      this.wxLoading = true
      uni.showLoading({ title: '登录中...' })
      
      try {
        // 获取微信登录凭证
        const loginRes = await new Promise((resolve, reject) => {
          uni.login({
            provider: 'weixin',
            success: resolve,
            fail: reject
          })
        })
        
        if (!loginRes.code) {
          throw new Error('获取微信授权失败')
        }
        
        // 获取用户信息（头像昵称）
        let userInfo = { nickName: '珈邻用户', avatarUrl: '' }
        try {
          const profileRes = await new Promise((resolve, reject) => {
            uni.getUserProfile({
              desc: '用于完善用户资料',
              success: resolve,
              fail: reject
            })
          })
          userInfo = profileRes.userInfo
        } catch (e) {
          console.log('用户拒绝授权，使用默认信息')
        }
        
        // 调用后端微信登录
        const { data, error } = await auth.wechatLogin(loginRes.code, {
          nickname: userInfo.nickName,
          avatar_url: userInfo.avatarUrl
        })
        
        uni.hideLoading()
        this.wxLoading = false
        
        if (error) {
          return uni.showToast({ title: error.message || '登录失败', icon: 'none' })
        }
        
        uni.$emit('loginStatusChanged', { isLogin: true })
        uni.showToast({ title: '登录成功', icon: 'success' })
        setTimeout(() => this.goBackOrHome(), 1500)
        
      } catch (e) {
        uni.hideLoading()
        this.wxLoading = false
        console.error('微信登录失败:', e)
        uni.showToast({ title: e.message || '微信登录失败', icon: 'none' })
      }
    },
    
    goBackOrHome() {
      // 获取页面栈
      const pages = getCurrentPages()
      if (pages.length > 1) {
        // 有上一页，直接返回
        uni.navigateBack()
      } else {
        // 没有上一页，根据tabbar配置跳转
        const tabbarConfig = this.$t.vuex_tabbar_config
        if (tabbarConfig && tabbarConfig.length === 1 && tabbarConfig[0].tab_key === 'notice') {
          uni.switchTab({ url: '/pages/notice/notice' })
        } else {
          uni.switchTab({ url: '/pages/index/index' })
        }
      }
    },
    goRegister() { uni.navigateTo({ url: '/pages/login/register' }) },
    goReset() { uni.navigateTo({ url: '/pages/login/reset' }) },
    goAgreement(type) { uni.navigateTo({ url: '/pages/login/agreement?type=' + type }) }
  }
}
</script>

<style scoped>
.container {
  min-height: 100vh;
  background: linear-gradient(180deg, #E8F4FD 0%, #F0F7FC 50%, #F8FBFE 100%);
  overflow-y: auto;
}

/* 顶部装饰背景 */
.header-bg {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 400rpx;
  background: linear-gradient(135deg, #667eea 0%, #5B9FE8 50%, #4A90E2 100%);
  border-radius: 0 0 50% 50% / 0 0 100rpx 100rpx;
  overflow: hidden;
}

/* 背景装饰圆 */
.bg-circle {
  position: absolute;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.1);
}
.circle-1 { width: 180rpx; height: 180rpx; top: -40rpx; right: -20rpx; }
.circle-2 { width: 120rpx; height: 120rpx; top: 150rpx; left: -30rpx; }
.circle-3 { width: 80rpx; height: 80rpx; top: 60rpx; right: 100rpx; background: rgba(255, 255, 255, 0.08); }

.login-content {
  position: relative;
  padding: 0 32rpx;
  padding-bottom: 40rpx;
}

/* Logo区域 */
.logo-section {
  text-align: center;
  margin-bottom: 36rpx;
}

.logo-wrapper {
  position: relative;
  display: inline-block;
}

.logo-circle {
  width: 140rpx;
  height: 140rpx;
  background: linear-gradient(135deg, #fff 0%, #f8f9fa 100%);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 12rpx 40rpx rgba(74, 144, 226, 0.35);
  position: relative;
  z-index: 2;
}

.logo-glow {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 180rpx;
  height: 180rpx;
  background: radial-gradient(circle, rgba(255,255,255,0.25) 0%, transparent 70%);
  border-radius: 50%;
  z-index: 1;
}

.logo-text {
  font-size: 44rpx;
  font-weight: bold;
  background: linear-gradient(135deg, #4A90E2, #667eea);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.app-name {
  display: block;
  font-size: 32rpx;
  font-weight: 600;
  color: #fff;
  margin-top: 20rpx;
  letter-spacing: 3rpx;
  text-shadow: 0 2rpx 6rpx rgba(0,0,0,0.1);
}

.app-slogan {
  display: block;
  font-size: 26rpx;
  color: rgba(255,255,255,0.9);
  margin-top: 16rpx;
  letter-spacing: 2rpx;
}

/* 登录表单卡片 */
.login-form {
  background: #fff;
  border-radius: 24rpx;
  padding: 40rpx 36rpx 36rpx;
  box-shadow: 0 12rpx 48rpx rgba(74, 144, 226, 0.1);
}

.form-title {
  font-size: 36rpx;
  font-weight: 600;
  color: #333;
  text-align: center;
  margin-bottom: 40rpx;
}

/* 输入框 */
.form-item {
  display: flex;
  align-items: center;
  background: #F7F8FA;
  border-radius: 12rpx;
  padding: 0 24rpx;
  margin-bottom: 24rpx;
  border: 2rpx solid #F0F1F3;
  transition: all 0.3s ease;
}

.form-item-focus {
  border-color: #4A90E2;
  background: #fff;
  box-shadow: 0 4rpx 12rpx rgba(74, 144, 226, 0.12);
}

.form-icon {
  width: 44rpx;
  height: 44rpx;
  display: flex;
  align-items: center;
  justify-content: center;
}

.form-icon text {
  font-size: 34rpx;
  color: #C0C4CC;
  transition: color 0.3s;
}

.form-item-focus .form-icon text {
  color: #4A90E2;
}

.input {
  flex: 1;
  height: 96rpx;
  font-size: 30rpx;
  color: #333;
  padding: 0 20rpx;
}

.input-clear, .password-toggle {
  width: 44rpx;
  height: 44rpx;
  display: flex;
  align-items: center;
  justify-content: center;
}

.input-clear text, .password-toggle text {
  font-size: 30rpx;
  color: #C0C4CC;
}

/* 登录按钮 */
.login-btn {
  background: linear-gradient(135deg, #667eea 0%, #5B9FE8 50%, #4A90E2 100%);
  color: #fff;
  border-radius: 12rpx;
  font-size: 32rpx;
  font-weight: 500;
  height: 96rpx;
  line-height: 96rpx;
  margin-top: 16rpx;
  box-shadow: 0 10rpx 28rpx rgba(74, 144, 226, 0.3);
  border: none;
  transition: all 0.3s;
}

.login-btn::after {
  border: none;
}

.login-btn[disabled] {
  opacity: 0.7;
  box-shadow: none;
}

.loading-wrap {
  display: flex;
  align-items: center;
  justify-content: center;
}

.loading-spinner {
  width: 28rpx;
  height: 28rpx;
  border: 3rpx solid rgba(255,255,255,0.3);
  border-top-color: #fff;
  border-radius: 50%;
  margin-right: 12rpx;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

/* 链接 */
.login-links {
  display: flex;
  justify-content: space-between;
  margin-top: 32rpx;
  padding: 0 8rpx;
}

.link-item {
  display: flex;
  align-items: center;
  padding: 10rpx 0;
}

.link-item text:first-child {
  font-size: 28rpx;
  color: #4A90E2;
  margin-right: 8rpx;
}

.link-item text:last-child {
  font-size: 28rpx;
  color: #666;
}

/* 分割线 */
.divider {
  display: flex;
  align-items: center;
  margin: 36rpx 0 32rpx;
}

.divider-line {
  flex: 1;
  height: 1rpx;
  background: linear-gradient(90deg, transparent, #E8E8E8, transparent);
}

.divider-text {
  font-size: 24rpx;
  color: #999;
  padding: 0 20rpx;
}

/* 游客浏览区域 */
.guest-section {
  margin-top: 8rpx;
}

.guest-card {
  display: flex;
  align-items: center;
  background: linear-gradient(135deg, #f8fdf9 0%, #f0faf2 100%);
  border: 2rpx solid #e8f5eb;
  border-radius: 16rpx;
  padding: 28rpx 24rpx;
  transition: all 0.3s;
}

.guest-card:active {
  transform: scale(0.98);
  background: linear-gradient(135deg, #f0faf2 0%, #e8f5eb 100%);
}

.guest-icon-wrap {
  margin-right: 16rpx;
}

.guest-icon {
  width: 72rpx;
  height: 72rpx;
  background: linear-gradient(135deg, #2DC84D, #07C160);
  border-radius: 16rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 6rpx 16rpx rgba(7, 193, 96, 0.2);
}

.guest-icon text {
  font-size: 40rpx;
  color: #fff;
}

.guest-info {
  flex: 1;
}

.guest-title {
  display: block;
  font-size: 30rpx;
  font-weight: 600;
  color: #333;
  margin-bottom: 8rpx;
}

.guest-desc {
  display: block;
  font-size: 24rpx;
  color: #888;
  line-height: 1.4;
}

.guest-arrow {
  width: 40rpx;
  height: 40rpx;
  display: flex;
  align-items: center;
  justify-content: center;
}

.guest-arrow text {
  font-size: 26rpx;
  color: #07C160;
}

.guest-notice {
  display: none;
}

/* 协议勾选 */
.agreement {
  display: flex;
  align-items: center;
  justify-content: center;
  margin-top: 36rpx;
  padding: 0 16rpx;
}

.check-wrap {
  padding: 6rpx 12rpx 6rpx 0;
}

.checkbox {
  width: 36rpx;
  height: 36rpx;
  border: 2rpx solid #ddd;
  border-radius: 6rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
}

.checkbox.checked {
  background: linear-gradient(135deg, #5B9FE8, #4A90E2);
  border-color: #4A90E2;
}

.checkbox text {
  font-size: 22rpx;
  color: #fff;
}

.agreement-text {
  font-size: 26rpx;
  color: #999;
  line-height: 1.6;
}

.agreement-text .link {
  color: #4A90E2;
}

/* 底部版权 */
.footer {
  text-align: center;
  margin-top: 40rpx;
  padding-bottom: 40rpx;
}

.footer text {
  font-size: 24rpx;
  color: #C0C4CC;
}
</style>
