<template>
  <view class="container">
    <view class="nav-bar" :style="{paddingTop: vuex_status_bar_height + 'px'}">
      <view class="nav-content">
        <text class="tn-icon-left nav-back" @click="goBack"></text>
        <text class="nav-title">编辑资料</text>
        <text class="nav-save" @click="saveProfile">保存</text>
      </view>
    </view>
    
    <view class="content" :style="{paddingTop: (vuex_status_bar_height + 54) + 'px'}">
      <!-- 头像 - 使用微信头像选择组件 -->
      <view class="edit-item avatar-item">
        <text class="item-label">头像</text>
        <view class="item-value">
          <button class="avatar-btn" open-type="chooseAvatar" @chooseavatar="onChooseAvatar">
            <image v-if="localAvatar" class="avatar-img" :src="localAvatar" mode="aspectFill"></image>
            <view v-else class="avatar-preview">
              <text class="tn-icon-my-fill"></text>
            </view>
          </button>
          <text class="tn-icon-right"></text>
        </view>
      </view>
      
      <!-- 昵称 - 使用微信昵称输入组件 -->
      <view class="edit-item">
        <text class="item-label">昵称</text>
        <view class="item-value">
          <input class="item-input" type="nickname" v-model="form.nickname" placeholder="请输入昵称" maxlength="20" @blur="onNicknameBlur" />
          <text class="tn-icon-right"></text>
        </view>
      </view>
      
      <!-- 性别 -->
      <view class="edit-item" @click="showGenderPicker = true">
        <text class="item-label">性别</text>
        <view class="item-value">
          <text class="value-text">{{genderText}}</text>
          <text class="tn-icon-right"></text>
        </view>
      </view>
      
      <!-- 楼栋 -->
      <view class="edit-item">
        <text class="item-label">楼栋</text>
        <view class="item-value">
          <input class="item-input" v-model="form.building" placeholder="如：3栋1单元" maxlength="20" />
          <text class="tn-icon-right"></text>
        </view>
      </view>
      
      <!-- 手机号（不可编辑） -->
      <view class="edit-item disabled">
        <text class="item-label">手机号</text>
        <view class="item-value">
          <text class="value-text">{{formatPhone(form.phone)}}</text>
        </view>
      </view>
      
      <!-- 确认按钮 -->
      <view class="btn-wrapper">
        <button class="save-btn" :loading="loading" @click="saveProfile">确认修改</button>
      </view>
    </view>
    
    <!-- 性别选择弹窗 -->
    <view class="picker-mask" v-if="showGenderPicker" @click="showGenderPicker = false">
      <view class="picker-content" @click.stop>
        <view class="picker-header">
          <text class="picker-cancel" @click="showGenderPicker = false">取消</text>
          <text class="picker-title">选择性别</text>
          <text class="picker-confirm" @click="confirmGender">确定</text>
        </view>
        <view class="picker-options">
          <view 
            class="picker-option" 
            :class="{active: tempGender === item.value}"
            v-for="item in genderOptions" 
            :key="item.value"
            @click="tempGender = item.value"
          >
            <text>{{item.label}}</text>
            <text class="tn-icon-success" v-if="tempGender === item.value"></text>
          </view>
        </view>
      </view>
    </view>
  </view>
</template>

<script>
import { auth, storage } from '@/libs/supabase'

export default {
  data() {
    return {
      form: {
        nickname: '',
        gender: '',
        building: '',
        phone: '',
        avatar_url: ''
      },
      localAvatar: '',
      tempAvatarPath: '',
      showGenderPicker: false,
      tempGender: '',
      genderOptions: [
        { label: '男', value: 'male' },
        { label: '女', value: 'female' },
        { label: '保密', value: '' }
      ],
      loading: false
    }
  },
  computed: {
    genderText() {
      const item = this.genderOptions.find(g => g.value === this.form.gender)
      return item ? item.label : '请选择'
    }
  },
  onLoad() {
    this.loadUserInfo()
  },
  methods: {
    loadUserInfo() {
      const user = auth.getLocalUser()
      if (user) {
        this.form = {
          nickname: user.nickname || '',
          gender: user.gender || '',
          building: user.building || '',
          phone: user.phone || '',
          avatar_url: user.avatar_url || ''
        }
        this.tempGender = this.form.gender
        // 显示已有头像
        if (user.avatar_url && user.avatar_url.startsWith('http')) {
          this.localAvatar = user.avatar_url
        }
      }
    },
    formatPhone(phone) {
      if (!phone) return ''
      return phone.replace(/(\d{3})\d{4}(\d{4})/, '$1****$2')
    },
    goBack() {
      uni.navigateBack()
    },
    // 微信头像选择回调（open-type="chooseAvatar"）
    onChooseAvatar(e) {
      const avatarUrl = e.detail.avatarUrl
      if (avatarUrl) {
        this.localAvatar = avatarUrl
        this.tempAvatarPath = avatarUrl
        uni.showToast({ title: '头像已选择，保存后生效', icon: 'none' })
      }
    },
    // 微信昵称输入回调（type="nickname"）
    onNicknameBlur(e) {
      const nickname = e.detail.value
      if (nickname) {
        this.form.nickname = nickname
      }
    },
    // 备用：从相册选择头像
    chooseAvatar() {
      uni.chooseImage({
        count: 1,
        sizeType: ['compressed'],
        sourceType: ['album', 'camera'],
        success: (res) => {
          const tempPath = res.tempFilePaths[0]
          this.localAvatar = tempPath
          this.tempAvatarPath = tempPath
          uni.showToast({ title: '头像已选择，保存后生效', icon: 'none' })
        }
      })
    },
    confirmGender() {
      this.form.gender = this.tempGender
      this.showGenderPicker = false
    },
    async saveProfile() {
      if (!this.form.nickname.trim()) {
        return uni.showToast({ title: '请输入昵称', icon: 'none' })
      }
      
      this.loading = true
      uni.showLoading({ title: '保存中...' })
      
      const user = auth.getLocalUser()
      let avatarUrl = this.form.avatar_url
      
      // 如果有新选择的头像，先上传
      if (this.tempAvatarPath) {
        uni.showLoading({ title: '上传头像...' })
        const { url, error } = await storage.uploadAvatar(user.id, this.tempAvatarPath)
        if (error) {
          uni.hideLoading()
          this.loading = false
          return uni.showToast({ title: error.message || '头像上传失败', icon: 'none' })
        }
        avatarUrl = url
        uni.showLoading({ title: '保存中...' })
      }
      
      const updateData = {
        nickname: this.form.nickname.trim(),
        gender: this.form.gender,
        building: this.form.building.trim(),
        avatar_url: avatarUrl
      }
      
      const { data, error } = await auth.updateProfile(updateData)
      
      uni.hideLoading()
      this.loading = false
      
      if (error) {
        return uni.showToast({ title: error.message || '保存失败', icon: 'none' })
      }
      
      uni.showToast({ title: '保存成功', icon: 'success' })
      
      // 通知 profile 页面刷新
      uni.$emit('profileUpdated')
      
      setTimeout(() => {
        uni.navigateBack()
      }, 1500)
    }
  }
}
</script>

<style scoped>
.container { min-height: 100vh; background: #F5F7FA; }
.nav-bar { position: fixed; top: 0; left: 0; right: 0; z-index: 100; background: linear-gradient(135deg, #4A90E2, #357ABD); }
.nav-content { display: flex; justify-content: space-between; align-items: center; height: 88rpx; padding: 0 24rpx; }
.nav-back { font-size: 40rpx; color: #fff; padding: 10rpx; }
.nav-title { font-size: 34rpx; color: #fff; font-weight: 500; }
.nav-save { font-size: 28rpx; color: #fff; padding: 10rpx 20rpx; }
.content { padding: 24rpx; }
.edit-item { display: flex; align-items: center; justify-content: space-between; background: #fff; padding: 32rpx 24rpx; margin-bottom: 2rpx; }
.edit-item:first-child { border-radius: 16rpx 16rpx 0 0; }
.edit-item:last-child { border-radius: 0 0 16rpx 16rpx; margin-bottom: 0; }
.edit-item.disabled { opacity: 0.7; }
.avatar-item { padding: 24rpx; }
.item-label { font-size: 30rpx; color: #333; width: 160rpx; }
.item-value { flex: 1; display: flex; align-items: center; justify-content: flex-end; }
.item-input { flex: 1; font-size: 28rpx; color: #333; text-align: right; }
.value-text { font-size: 28rpx; color: #666; }
.item-value .tn-icon-right { font-size: 28rpx; color: #ccc; margin-left: 12rpx; }
.avatar-preview { width: 80rpx; height: 80rpx; border-radius: 50%; background: linear-gradient(145deg, #667eea 0%, #764ba2 100%); display: flex; align-items: center; justify-content: center; }
.avatar-preview text { font-size: 40rpx; color: #fff; }
.avatar-img { width: 80rpx; height: 80rpx; border-radius: 50%; }
/* 微信头像选择按钮 */
.avatar-btn { padding: 0; margin: 0; margin-right: 12rpx; background: transparent; border: none; line-height: 1; width: 80rpx; height: 80rpx; border-radius: 50%; overflow: hidden; }
.avatar-btn::after { border: none; }
/* 性别选择弹窗 */
.picker-mask { position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.5); z-index: 1000; display: flex; align-items: flex-end; }
.picker-content { width: 100%; background: #fff; border-radius: 24rpx 24rpx 0 0; }
.picker-header { display: flex; justify-content: space-between; align-items: center; padding: 28rpx 32rpx; border-bottom: 1rpx solid #f0f0f0; }
.picker-cancel { font-size: 28rpx; color: #999; }
.picker-title { font-size: 32rpx; color: #333; font-weight: 500; }
.picker-confirm { font-size: 28rpx; color: #4A90E2; }
.picker-options { padding: 20rpx 0; padding-bottom: calc(20rpx + env(safe-area-inset-bottom)); }
.picker-option { display: flex; justify-content: space-between; align-items: center; padding: 32rpx; }
.picker-option text:first-child { font-size: 30rpx; color: #333; }
.picker-option .tn-icon-success { font-size: 36rpx; color: #4A90E2; }
.picker-option.active { background: #F0F7FF; }
/* 确认按钮 */
.btn-wrapper { padding: 60rpx 0 40rpx; }
.save-btn { width: 100%; height: 96rpx; line-height: 96rpx; background: linear-gradient(135deg, #4A90E2, #357ABD); color: #fff; font-size: 32rpx; font-weight: 500; border-radius: 48rpx; border: none; }
.save-btn::after { border: none; }
</style>
