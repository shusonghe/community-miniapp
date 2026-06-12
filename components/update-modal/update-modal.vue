<template>
  <view class="update-modal" v-if="show">
    <view class="modal-mask"></view>
    <view class="modal-content">
      <view class="modal-header">
        <text class="modal-title">发现新版本</text>
      </view>
      <view class="modal-body">
        <text class="modal-desc">{{desc || '新版本已准备就绪，请更新后使用'}}</text>
      </view>
      <view class="modal-footer">
        <view class="btn-cancel" v-if="!forceUpdate" @click="onCancel">稍后再说</view>
        <view class="btn-confirm" @click="onConfirm">立即更新</view>
      </view>
    </view>
  </view>
</template>

<script>
export default {
  name: 'UpdateModal',
  props: {
    show: { type: Boolean, default: false },
    desc: { type: String, default: '' },
    forceUpdate: { type: Boolean, default: false }
  },
  methods: {
    onCancel() {
      this.$emit('cancel')
      this.$emit('update:show', false)
    },
    onConfirm() {
      this.$emit('confirm')
    }
  }
}
</script>

<style scoped>
.update-modal { position: fixed; top: 0; left: 0; right: 0; bottom: 0; z-index: 9999; }
.modal-mask { position: absolute; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.5); }
.modal-content { position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); width: 560rpx; background: #fff; border-radius: 24rpx; overflow: hidden; }
.modal-header { padding: 40rpx 32rpx 20rpx; text-align: center; }
.modal-title { font-size: 36rpx; font-weight: bold; color: #333; }
.modal-body { padding: 20rpx 32rpx 40rpx; text-align: center; }
.modal-desc { font-size: 28rpx; color: #666; line-height: 1.6; }
.modal-footer { display: flex; border-top: 1rpx solid #f0f0f0; }
.btn-cancel { flex: 1; height: 100rpx; display: flex; align-items: center; justify-content: center; font-size: 32rpx; color: #999; border-right: 1rpx solid #f0f0f0; }
.btn-confirm { flex: 1; height: 100rpx; display: flex; align-items: center; justify-content: center; font-size: 32rpx; color: #4A90E2; font-weight: 500; }
</style>
