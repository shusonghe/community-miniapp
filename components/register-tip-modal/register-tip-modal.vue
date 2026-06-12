<template>
  <view class="modal-mask" v-if="visible" @click="close">
    <view class="modal-container" @click.stop>
      <!-- 顶部图标 -->
      <view class="modal-icon">
        <text class="tn-icon-tips-fill"></text>
      </view>
      
      <!-- 标题 -->
      <text class="modal-title">温馨提示</text>
      
      <!-- 内容 -->
      <text class="modal-content">请先注册账号后再进行操作</text>
      
      <!-- 按钮组 -->
      <view class="modal-buttons">
        <view class="btn btn-cancel" @click="close">
          <text>取消</text>
        </view>
        <view class="btn btn-confirm" @click="goRegister">
          <text>去注册</text>
        </view>
      </view>
    </view>
  </view>
</template>

<script>
import { auth } from '@/libs/supabase/supabase-mini.js'

export default {
  name: 'RegisterTipModal',
  data() {
    return {
      visible: false
    }
  },
  methods: {
    show() {
      this.visible = true
    },
    close() {
      this.visible = false
    },
    goRegister() {
      this.visible = false
      // 退出微信登录
      auth.signOut()
      // 跳转注册页
      uni.navigateTo({ url: '/pages/login/register' })
    }
  }
}
</script>

<style scoped>
.modal-mask {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  z-index: 9999;
  display: flex;
  align-items: center;
  justify-content: center;
}

.modal-container {
  width: 600rpx;
  background: #fff;
  border-radius: 24rpx;
  padding: 48rpx 40rpx 40rpx;
  display: flex;
  flex-direction: column;
  align-items: center;
  animation: modalIn 0.3s ease;
}

@keyframes modalIn {
  from {
    opacity: 0;
    transform: scale(0.8);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}

.modal-icon {
  width: 120rpx;
  height: 120rpx;
  background: linear-gradient(135deg, #FFD93D, #FF9500);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 32rpx;
  box-shadow: 0 8rpx 24rpx rgba(255, 149, 0, 0.3);
}

.modal-icon text {
  font-size: 64rpx;
  color: #fff;
}

.modal-title {
  font-size: 36rpx;
  color: #333;
  font-weight: 600;
  margin-bottom: 20rpx;
}

.modal-content {
  font-size: 28rpx;
  color: #666;
  text-align: center;
  line-height: 1.6;
  margin-bottom: 40rpx;
  padding: 0 20rpx;
}

.modal-buttons {
  display: flex;
  width: 100%;
  gap: 24rpx;
}

.btn {
  flex: 1;
  height: 88rpx;
  border-radius: 44rpx;
  display: flex;
  align-items: center;
  justify-content: center;
}

.btn text {
  font-size: 30rpx;
  font-weight: 500;
}

.btn-cancel {
  background: #F5F5F5;
}

.btn-cancel text {
  color: #666;
}

.btn-confirm {
  background: linear-gradient(135deg, #4A90E2, #357ABD);
  box-shadow: 0 8rpx 20rpx rgba(74, 144, 226, 0.3);
}

.btn-confirm text {
  color: #fff;
}
</style>
