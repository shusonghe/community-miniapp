<template>
  <view class="modal-mask" v-if="visible" @click="close">
    <view class="modal-content" @click.stop :class="{'modal-show': showAnim}">
      <view class="modal-icon">
        <text class="modal-icon-text tn-icon-my-fill"></text>
      </view>
      <text class="modal-title">登录提示</text>
      <text class="modal-desc">登录后即可使用完整功能</text>
      <view class="modal-btns">
        <button class="btn-cancel" @click="close">暂不登录</button>
        <button class="btn-confirm" @click="goLogin">立即登录</button>
      </view>
    </view>
  </view>
</template>

<script>
export default {
  name: 'LoginModal',
  data() {
    return {
      visible: false,
      showAnim: false
    }
  },
  methods: {
    show() {
      this.visible = true
      setTimeout(() => {
        this.showAnim = true
      }, 10)
    },
    close() {
      this.showAnim = false
      setTimeout(() => {
        this.visible = false
      }, 200)
    },
    goLogin() {
      this.close()
      setTimeout(() => {
        uni.navigateTo({ url: '/pages/login/login' })
      }, 200)
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
.modal-content {
  width: 580rpx;
  background: #fff;
  border-radius: 32rpx;
  padding: 56rpx 48rpx;
  display: flex;
  flex-direction: column;
  align-items: center;
  transform: scale(0.8);
  opacity: 0;
  transition: all 0.2s ease-out;
}
.modal-content.modal-show {
  transform: scale(1);
  opacity: 1;
}
.modal-icon {
  width: 140rpx;
  height: 140rpx;
  border-radius: 50%;
  background: linear-gradient(145deg, #5B9FE8, #4A90E2);
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 36rpx;
  box-shadow: 0 12rpx 32rpx rgba(74, 144, 226, 0.35);
}
.modal-icon-text {
  font-size: 70rpx;
  color: #fff;
}
.modal-title {
  font-size: 38rpx;
  color: #333;
  font-weight: 600;
  margin-bottom: 16rpx;
}
.modal-desc {
  font-size: 28rpx;
  color: #999;
  margin-bottom: 48rpx;
}
.modal-btns {
  display: flex;
  width: 100%;
}
.btn-cancel {
  flex: 1;
  height: 92rpx;
  line-height: 92rpx;
  font-size: 30rpx;
  color: #666;
  background: #F5F6F7;
  border-radius: 46rpx;
  border: none;
  margin-right: 24rpx;
}
.btn-cancel::after {
  border: none;
}
.btn-confirm {
  flex: 1;
  height: 92rpx;
  line-height: 92rpx;
  font-size: 30rpx;
  color: #fff;
  background: linear-gradient(135deg, #5B9FE8, #4A90E2);
  border-radius: 46rpx;
  border: none;
  font-weight: 500;
}
.btn-confirm::after {
  border: none;
}
</style>
