<template>
  <view class="container">
    <!-- 顶部导航 -->
    <view class="nav-bar" :style="{paddingTop: vuex_status_bar_height + 'px'}">
      <view class="nav-content">
        <text class="tn-icon-left nav-back" @click="goBack"></text>
        <text class="nav-title">商家管理</text>
        <view class="nav-save" @click="submitForm">保存</view>
      </view>
    </view>
    
    <view class="content" :style="{paddingTop: (vuex_status_bar_height + 54) + 'px'}">
      <!-- 权限提示 -->
      <view class="tip-card" v-if="!isAuthorized">
        <text class="tn-icon-warning"></text>
        <view class="tip-content">
          <text class="tip-title">暂无编辑权限</text>
          <text class="tip-desc">请联系管理员授权后再进行编辑</text>
        </view>
      </view>
      
      <template v-else>
        <!-- 图片上传 -->
        <view class="section">
          <text class="section-title">商家图片</text>
          <view class="image-grid">
            <view class="image-item" v-for="(img, index) in images" :key="index">
              <image :src="img" mode="aspectFill"></image>
              <view class="delete-btn" @click="removeImage(index)">
                <text class="tn-icon-close"></text>
              </view>
            </view>
            <view class="add-btn" @click="chooseImage" v-if="images.length < 9">
              <text class="tn-icon-camera"></text>
              <text class="add-text">添加图片</text>
            </view>
          </view>
        </view>
        
        <!-- 基本信息 -->
        <view class="section">
          <text class="section-title">基本信息</text>
          <view class="form-card">
            <view class="form-item">
              <text class="label">商家名称</text>
              <input class="input" v-model="form.name" placeholder="请输入商家名称" maxlength="20" />
            </view>
            
            <view class="form-item">
              <text class="label">商家分类</text>
              <picker :range="categories" @change="onCategoryChange">
                <view class="picker-value">
                  <text>{{form.category || '请选择'}}</text>
                  <text class="tn-icon-right"></text>
                </view>
              </picker>
            </view>
            
            <view class="form-item">
              <text class="label">服务标签</text>
              <input class="input" v-model="form.tagsStr" placeholder="多个标签用逗号分隔" />
            </view>
            
            <view class="form-item">
              <text class="label">联系电话</text>
              <input class="input" v-model="form.phone" placeholder="请输入联系电话" type="number" maxlength="11" />
            </view>
            
            <view class="form-item">
              <text class="label">门店地址</text>
              <input class="input" v-model="form.address" placeholder="请输入门店地址" />
            </view>
          </view>
        </view>
        
        <!-- 商家介绍 -->
        <view class="section">
          <text class="section-title">商家介绍</text>
          <view class="form-card">
            <textarea class="desc-input" v-model="form.description" placeholder="请输入商家介绍、服务项目、营业时间等信息..." maxlength="500"></textarea>
            <view class="char-count">{{form.description.length}}/500</view>
          </view>
        </view>
      </template>
    </view>
  </view>
</template>

<script>
export default {
  data() {
    return {
      isAuthorized: true,
      categories: ['家政服务', '维修服务', '美食餐饮', '教育培训', '医疗健康', '美容美发', '其他'],
      form: { name: '', category: '', tagsStr: '', phone: '', address: '', description: '' },
      images: []
    }
  },
  methods: {
    goBack() { uni.navigateBack() },
    onCategoryChange(e) { this.form.category = this.categories[e.detail.value] },
    chooseImage() {
      uni.chooseImage({
        count: 9 - this.images.length,
        success: (res) => { this.images = [...this.images, ...res.tempFilePaths] }
      })
    },
    removeImage(index) { this.images.splice(index, 1) },
    submitForm() {
      if (!this.form.name) return uni.showToast({ title: '请输入商家名称', icon: 'none' })
      if (!this.form.category) return uni.showToast({ title: '请选择分类', icon: 'none' })
      if (!this.form.phone) return uni.showToast({ title: '请输入联系电话', icon: 'none' })
      if (!this.form.address) return uni.showToast({ title: '请输入门店地址', icon: 'none' })
      
      uni.showLoading({ title: '保存中...' })
      setTimeout(() => {
        uni.hideLoading()
        uni.showToast({ title: '保存成功', icon: 'success' })
        setTimeout(() => uni.navigateBack(), 1500)
      }, 1000)
    }
  }
}
</script>

<style lang="scss" scoped>
.container { min-height: 100vh; background: linear-gradient(180deg, #E8F4FD 0%, #D6EBFA 50%, #C4E2F7 100%); }

.nav-bar {
  position: fixed; top: 0; left: 0; right: 0; z-index: 100;
  background: linear-gradient(135deg, #4A90E2, #357ABD);
  .nav-content {
    display: flex; justify-content: space-between; align-items: center;
    height: 88rpx; padding: 0 24rpx;
  }
  .nav-back { font-size: 40rpx; color: #fff; }
  .nav-title { font-size: 34rpx; color: #fff; font-weight: 500; }
  .nav-save { font-size: 30rpx; color: #fff; font-weight: 500; }
}

.content { padding: 24rpx; }

.tip-card {
  display: flex; align-items: center; background: #FFF8E6;
  border-radius: 16rpx; padding: 32rpx;
  text:first-child { font-size: 48rpx; color: #FF9500; margin-right: 20rpx; }
  .tip-content { flex: 1; }
  .tip-title { display: block; font-size: 30rpx; color: #333; font-weight: 500; }
  .tip-desc { display: block; font-size: 26rpx; color: #999; margin-top: 8rpx; }
}

.section {
  margin-bottom: 24rpx;
  .section-title { display: block; font-size: 28rpx; color: #999; margin-bottom: 16rpx; padding-left: 8rpx; }
}

.image-grid {
  display: flex; flex-wrap: wrap; gap: 16rpx;
  background: #fff; border-radius: 16rpx; padding: 24rpx;
  .image-item {
    position: relative; width: 180rpx; height: 180rpx;
    image { width: 100%; height: 100%; border-radius: 12rpx; }
    .delete-btn {
      position: absolute; top: -12rpx; right: -12rpx;
      width: 44rpx; height: 44rpx; background: rgba(0,0,0,0.6);
      border-radius: 50%; display: flex; align-items: center; justify-content: center;
      text { font-size: 24rpx; color: #fff; }
    }
  }
  .add-btn {
    width: 180rpx; height: 180rpx; background: #F7F7F7;
    border-radius: 12rpx; display: flex; flex-direction: column;
    align-items: center; justify-content: center;
    text { color: #999; &:first-child { font-size: 48rpx; } }
    .add-text { font-size: 24rpx; margin-top: 8rpx; }
  }
}

.form-card {
  background: #fff; border-radius: 16rpx; padding: 0 24rpx;
  .form-item {
    display: flex; align-items: center; padding: 28rpx 0;
    border-bottom: 1rpx solid #F5F5F5;
    &:last-child { border-bottom: none; }
    .label { font-size: 30rpx; color: #333; width: 160rpx; }
    .input { flex: 1; font-size: 28rpx; text-align: right; }
    .picker-value {
      flex: 1; display: flex; justify-content: flex-end; align-items: center;
      text { font-size: 28rpx; color: #999; &:last-child { margin-left: 8rpx; } }
    }
  }
  .desc-input { width: 100%; min-height: 200rpx; font-size: 28rpx; line-height: 1.6; padding: 24rpx 0; }
  .char-count { text-align: right; font-size: 24rpx; color: #ccc; padding-bottom: 16rpx; }
}
</style>
