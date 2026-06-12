<template>
  <view class="container">
    <view class="header-section" :style="{paddingTop: vuex_status_bar_height + 'px'}">
      <view class="header-bg"></view>
      
      <view class="page-title">
        <!-- <text>我的</text> -->
      </view>
      
      <view class="user-info" v-if="isLogin">
        <view class="avatar-wrapper">
          <image v-if="userInfo.avatar_url" class="user-avatar-img" :src="userInfo.avatar_url" mode="aspectFill"></image>
          <view v-else class="default-avatar logged-in">
            <text class="tn-icon-my-fill"></text>
          </view>
        </view>
        <view class="user-detail">
          <text class="user-name">{{userInfo.nickname || '珈邻用户'}}</text>
          <text class="user-phone">{{formatPhone(userInfo.phone)}}</text>
        </view>
        <view class="edit-btn" @click="editProfile">
          <text class="tn-icon-edit"></text>
        </view>
      </view>
      
      <view class="user-info" v-else @click="goLogin">
        <view class="default-avatar">
          <text class="tn-icon-my-fill"></text>
        </view>
        <view class="user-detail">
          <text class="user-name">点击登录</text>
          <text class="user-phone">登录后享受更多服务</text>
        </view>
      </view>
      
      <view class="func-card" @click="showTip">
        <view class="func-info">
          <text class="func-title">珈邻 · 邻里生活</text>
          <text class="func-desc">智慧社区，便捷生活新体验</text>
        </view>
        <view class="func-btn">
          <text>查看详情</text>
        </view>
      </view>
    </view>
    
    <view class="menu-list">
      <view class="menu-item" @click="goMyPosts">
        <text class="tn-icon-team menu-icon"></text>
        <text class="menu-text">我的动态</text>
        <text class="tn-icon-right menu-arrow"></text>
      </view>
      
      <view class="menu-item" @click="goMyGoods">
        <text class="tn-icon-shopbag menu-icon"></text>
        <text class="menu-text">我的闲置</text>
        <text class="tn-icon-right menu-arrow"></text>
      </view>
      
      <view class="menu-item" @click="goMyGroups">
        <text class="tn-icon-shop menu-icon"></text>
        <text class="menu-text">我的组团</text>
        <text class="tn-icon-right menu-arrow"></text>
      </view>
      
      <view class="menu-item" @click="goReset">
        <text class="tn-icon-lock menu-icon"></text>
        <text class="menu-text">修改密码</text>
        <text class="tn-icon-right menu-arrow"></text>
      </view>
      
      <view class="menu-item">
        <text class="tn-icon-notice menu-icon"></text>
        <text class="menu-text">版本信息</text>
        <text class="menu-value">当前版本v1.1.2</text>
        <text class="tn-icon-right menu-arrow"></text>
      </view>
      
      <view class="menu-item" @click="clearCache">
        <text class="tn-icon-delete menu-icon"></text>
        <text class="menu-text">清除缓存</text>
        <text class="tn-icon-right menu-arrow"></text>
      </view>
      
      <view class="menu-item" @click="logout" v-if="isLogin">
        <text class="tn-icon-logout menu-icon"></text>
        <text class="menu-text">退出登录</text>
        <text class="tn-icon-right menu-arrow"></text>
      </view>
    </view>
    
    <custom-tabbar :current="4"></custom-tabbar>
    <login-modal ref="loginModal"></login-modal>
  </view>
</template>

<script>
import { auth } from '@/libs/supabase'
import authMixin from '@/libs/mixin/auth.mixin.js'
import loginModal from '@/components/login-modal/login-modal.vue'

export default {
  components: { loginModal },
  mixins: [authMixin],
  data() {
    return {
      isLogin: false,
      userInfo: {}
    }
  },
  onLoad() {
    uni.$on('profileUpdated', () => {
      this.checkLoginStatus()
    })
    uni.$on('loginStatusChanged', () => {
      this.checkLoginStatus()
    })
  },
  onUnload() {
    uni.$off('profileUpdated')
    uni.$off('loginStatusChanged')
  },
  onShow() {
    this.checkLoginStatus()
  },
  methods: {
    checkLoginStatus() {
      this.isLogin = auth.isLoggedIn()
      if (this.isLogin) {
        this.userInfo = auth.getLocalUser() || {}
      }
    },
    formatPhone(phone) {
      if (!phone) return ''
      return phone.replace(/(\d{3})\d{4}(\d{4})/, '$1****$2')
    },
    goLogin() { uni.navigateTo({ url: '/pages/login/login' }) },
    editProfile() { this.checkLoginAndGo('/pages/profile/edit') },
    goMyPosts() { this.checkLoginAndGo('/pages/profile/my-posts') },
    goMyGoods() { this.checkLoginAndGo('/pages/profile/my-goods') },
    goMyGroups() { this.checkLoginAndGo('/pages/profile/my-groups') },
    goReset() { this.checkLoginAndGo('/pages/login/reset') },
    showTip() { uni.showToast({ title: '功能开发中', icon: 'none' }) },
    clearCache() {
      uni.showModal({
        title: '提示',
        content: '确定要清除缓存吗？',
        success: (res) => {
          if (res.confirm) {
            uni.showToast({ title: '清除成功', icon: 'success' })
          }
        }
      })
    },
    async logout() {
      uni.showModal({
        title: '提示',
        content: '确定要退出登录吗？',
        success: async (res) => {
          if (res.confirm) {
            await auth.signOut()
            this.isLogin = false
            this.userInfo = {}
            uni.showToast({ title: '已退出登录', icon: 'success' })
          }
        }
      })
    }
  }
}
</script>

<style scoped>
.container { min-height: 100vh; background: #F5F7FA; padding-bottom: 200rpx; }
.header-section { position: relative; padding-bottom: 60rpx; }
.header-bg { position: absolute; top: 0; left: 0; right: 0; bottom: 0; background: linear-gradient(135deg, #4A90E2, #357ABD); }
.page-title { position: relative; padding: 20rpx 32rpx; text-align: center; }
.page-title text { font-size: 36rpx; color: #fff; font-weight: 500; }
.user-info { position: relative; display: flex; align-items: center; padding: 24rpx 32rpx; }
.user-avatar { width: 120rpx; height: 120rpx; border-radius: 50%; border: 4rpx solid rgba(255,255,255,0.3); background: #fff; }
.user-avatar-img { width: 120rpx; height: 120rpx; border-radius: 50%; border: 4rpx solid rgba(255,255,255,0.3); box-shadow: 0 8rpx 24rpx rgba(0,0,0,0.15);background: #FFFFFF; }
/* 默认头像 - 统一圆形渐变风格 */
.default-avatar { width: 120rpx; height: 120rpx; border-radius: 50%; background: linear-gradient(145deg, #A8D8EA 0%, #7EC8E3 100%); display: flex; align-items: center; justify-content: center; border: 4rpx solid rgba(255,255,255,0.4); box-shadow: 0 8rpx 24rpx rgba(0,0,0,0.12); }
.default-avatar text { font-size: 56rpx; color: #fff; }
/* 已登录默认头像 - 更鲜艳的渐变 */
.default-avatar.logged-in { background: linear-gradient(145deg, #667eea 0%, #764ba2 100%); }
.avatar-wrapper { position: relative; }
.user-detail { flex: 1; margin-left: 28rpx; }
/* 编辑按钮 */
.edit-btn { width: 64rpx; height: 64rpx; border-radius: 50%; background: rgba(255,255,255,0.2); display: flex; align-items: center; justify-content: center; }
.edit-btn text { font-size: 32rpx; color: #fff; }
.user-name { display: block; font-size: 34rpx; color: #fff; font-weight: 500; }
.user-phone { display: block; font-size: 26rpx; color: rgba(255,255,255,0.8); margin-top: 8rpx; }
.func-card { position: relative; margin: 24rpx; background: linear-gradient(135deg, #3A7BD5, #2B5BA8); border-radius: 16rpx; padding: 28rpx 32rpx; display: flex; align-items: center; justify-content: space-between; }
.func-info { }
.func-title { display: block; font-size: 30rpx; color: #fff; font-weight: 500; }
.func-desc { display: block; font-size: 24rpx; color: rgba(255,255,255,0.7); margin-top: 8rpx; }
.func-btn { padding: 14rpx 28rpx; background: rgba(255,255,255,0.2); border-radius: 8rpx; border: 1rpx solid rgba(255,255,255,0.3); }
.func-btn text { font-size: 24rpx; color: #fff; }
.menu-list { background: #fff; margin: 0 24rpx; border-radius: 16rpx; overflow: hidden; }
.menu-item { display: flex; align-items: center; padding: 36rpx 32rpx; border-bottom: 1rpx solid #F5F5F5; }
.menu-item:last-child { border-bottom: none; }
.menu-icon { font-size: 40rpx; color: #4A90E2; margin-right: 24rpx; }
.menu-text { flex: 1; font-size: 30rpx; color: #333; }
.menu-value { font-size: 26rpx; color: #999; margin-right: 12rpx; }
.menu-arrow { font-size: 28rpx; color: #D0D0D0; }
</style>
