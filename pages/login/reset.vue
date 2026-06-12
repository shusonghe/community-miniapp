<template>
  <view class="container">
    <view class="nav-bar" :style="{paddingTop: vuex_status_bar_height + 'px'}">
      <view class="nav-content">
        <text class="tn-icon-left nav-back" @click="goBack"></text>
        <text class="nav-title">重置密码</text>
        <view class="nav-placeholder"></view>
      </view>
    </view>
    
    <view class="content" :style="{paddingTop: (vuex_status_bar_height + 54) + 'px'}">
      <view class="form-section">
        <view class="form-item">
          <text class="label">手机号</text>
          <input class="input" v-model="form.phone" placeholder="请输入注册时的手机号" type="number" maxlength="11" />
        </view>
        
        <view class="form-item">
          <text class="label">新密码</text>
          <input class="input" v-model="form.newPassword" placeholder="请设置6-20位新密码" password />
        </view>
        
        <view class="form-item">
          <text class="label">确认密码</text>
          <input class="input" v-model="form.confirmPassword" placeholder="请再次输入新密码" password />
        </view>
      </view>
      
      <button class="submit-btn" @click="resetPassword" :disabled="loading">{{loading ? '重置中...' : '确认重置'}}</button>
    </view>
  </view>
</template>

<script>
import { auth } from '@/libs/supabase'

export default {
  data() {
    return {
      form: { phone: '', newPassword: '', confirmPassword: '' },
      loading: false
    }
  },
  methods: {
    goBack() { uni.navigateBack() },
    
    async resetPassword() {
      if (!this.form.phone || this.form.phone.length !== 11) {
        return uni.showToast({ title: '请输入正确的手机号', icon: 'none' })
      }
      if (!this.form.newPassword || this.form.newPassword.length < 6) {
        return uni.showToast({ title: '新密码至少6位', icon: 'none' })
      }
      if (this.form.newPassword !== this.form.confirmPassword) {
        return uni.showToast({ title: '两次密码不一致', icon: 'none' })
      }
      
      this.loading = true
      uni.showLoading({ title: '重置中...' })
      
      const { data, error } = await auth.updatePassword(this.form.phone, this.form.newPassword)
      
      uni.hideLoading()
      this.loading = false
      
      if (error) {
        return uni.showToast({ title: error.message || '重置失败', icon: 'none' })
      }
      
      uni.showToast({ title: '重置成功', icon: 'success' })
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
.submit-btn { margin-top: 48rpx; background: linear-gradient(135deg, #5B9FE8, #4A90E2); color: #fff; border-radius: 48rpx; font-size: 34rpx; height: 96rpx; line-height: 96rpx; }
.submit-btn[disabled] { opacity: 0.7; }
</style>
