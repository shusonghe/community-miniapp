<template>
  <view class="container">
    <view class="nav-bar" :style="{paddingTop: vuex_status_bar_height + 'px'}">
      <view class="nav-content">
        <text class="tn-icon-left nav-back" @click="goBack"></text>
        <text class="nav-title">注册账号</text>
        <view class="nav-placeholder"></view>
      </view>
    </view>
    
    <view class="content" :style="{paddingTop: (vuex_status_bar_height + 54) + 'px'}">
      <view class="form-section">
        <view class="form-item">
          <text class="label">昵称</text>
          <input class="input" v-model="form.nickname" placeholder="请输入昵称" maxlength="20" />
        </view>
        
        <view class="form-item">
          <text class="label">手机号</text>
          <input class="input" v-model="form.phone" placeholder="请输入手机号" type="number" maxlength="11" />
        </view>
        
        <view class="form-item">
          <text class="label">密码</text>
          <input class="input" v-model="form.password" placeholder="请设置6-20位密码" password />
        </view>
        
        <view class="form-item">
          <text class="label">确认密码</text>
          <input class="input" v-model="form.confirmPassword" placeholder="请再次输入密码" password />
        </view>
        
        <view class="form-item">
          <text class="label">楼栋</text>
          <input class="input" v-model="form.building" placeholder="选填，如：3栋1单元" />
        </view>
        
        <view class="form-item">
          <text class="label">用户类型</text>
          <view class="type-selector">
            <view class="type-item" :class="{active: form.userType === 'owner'}" @click="form.userType = 'owner'">
              <text class="tn-icon-home"></text>
              <text>业主</text>
            </view>
            <view class="type-item" :class="{active: form.userType === 'visitor'}" @click="form.userType = 'visitor'">
              <text class="tn-icon-my"></text>
              <text>商家</text>
            </view>
          </view>
        </view>
      </view>
      
      <button class="submit-btn" @click="register" :disabled="loading">{{loading ? '注册中...' : '注 册'}}</button>
      
      <view class="agreement">
        <text>注册即表示同意</text>
        <text class="link" @click="goAgreement('user')">《用户协议》</text>
        <text>和</text>
        <text class="link" @click="goAgreement('privacy')">《隐私政策》</text>
      </view>
    </view>
  </view>
</template>

<script>
import { auth } from '@/libs/supabase'

export default {
  data() {
    return {
      form: { nickname: '', phone: '', password: '', confirmPassword: '', building: '', userType: 'owner' },
      loading: false
    }
  },
  methods: {
    goBack() { uni.navigateBack() },
    goAgreement(type) { uni.navigateTo({ url: '/pages/login/agreement?type=' + type }) },
    
    async register() {
      if (!this.form.nickname) {
        return uni.showToast({ title: '请输入昵称', icon: 'none' })
      }
      if (!this.form.phone || this.form.phone.length !== 11) {
        return uni.showToast({ title: '请输入正确的手机号', icon: 'none' })
      }
      if (!this.form.password || this.form.password.length < 6) {
        return uni.showToast({ title: '密码至少6位', icon: 'none' })
      }
      if (this.form.password !== this.form.confirmPassword) {
        return uni.showToast({ title: '两次密码不一致', icon: 'none' })
      }
      
      this.loading = true
      uni.showLoading({ title: '注册中...' })
      
      const { data, error } = await auth.signUp(this.form.phone, this.form.password, {
        nickname: this.form.nickname,
        building: this.form.building,
        user_type: this.form.userType
      })
      
      uni.hideLoading()
      this.loading = false
      
      if (error) {
        let msg = '注册失败'
        if (error.message?.includes('已注册')) msg = error.message
        else if (error.message?.includes('already')) msg = '该手机号已注册'
        return uni.showToast({ title: msg, icon: 'none' })
      }
      
      uni.showToast({ title: '注册成功，请登录', icon: 'success' })
      setTimeout(() => uni.navigateBack(), 1500)
    }
  }
}
</script>

<style scoped>
.container { min-height: 100vh; background: linear-gradient(180deg, #E8F4FD 0%, #D6EBFA 50%, #C4E2F7 100%); }
.nav-bar { position: fixed; top: 0; left: 0; right: 0; z-index: 100; background: linear-gradient(135deg, #4A90E2, #357ABD); }
.nav-content { display: flex; justify-content: space-between; align-items: center; height: 88rpx; padding: 0 24rpx; }
.nav-back { font-size: 40rpx; color: #fff; }
.nav-title { font-size: 34rpx; color: #fff; font-weight: 500; }
.nav-placeholder { width: 40rpx; }
.content { padding: 24rpx; }
.form-section { background: #fff; border-radius: 16rpx; padding: 0 24rpx; }
.form-item { display: flex; align-items: center; padding: 28rpx 0; border-bottom: 1rpx solid #F5F5F5; }
.form-item:last-child { border-bottom: none; }
.label { font-size: 30rpx; color: #333; width: 160rpx; }
.input { flex: 1; font-size: 28rpx; text-align: right; }
.type-selector { flex: 1; display: flex; justify-content: flex-end; gap: 20rpx; }
.type-item { display: flex; align-items: center; padding: 16rpx 28rpx; background: #F5F5F5; border-radius: 32rpx; }
.type-item text { font-size: 26rpx; color: #666; }
.type-item text:first-child { font-size: 28rpx; margin-right: 8rpx; }
.type-item.active { background: linear-gradient(135deg, #5B9FE8, #4A90E2); }
.type-item.active text { color: #fff; }
.submit-btn { margin-top: 48rpx; background: linear-gradient(135deg, #5B9FE8, #4A90E2); color: #fff; border-radius: 48rpx; font-size: 34rpx; height: 96rpx; line-height: 96rpx; }
.submit-btn[disabled] { opacity: 0.7; }
.agreement { text-align: center; margin-top: 32rpx; font-size: 24rpx; color: #999; }
.link { color: #4A90E2; }
</style>
