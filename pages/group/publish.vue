<template>
  <view class="container">
    <!-- 顶部导航 -->
    <view class="nav-bar" :style="{paddingTop: vuex_status_bar_height + 'px'}">
      <view class="nav-content">
        <text class="nav-cancel" @click="goBack">取消</text>
        <text class="nav-title">发起组团</text>
        <view class="nav-placeholder"></view>
      </view>
    </view>
    
    <view class="content" :style="{paddingTop: (vuex_status_bar_height + 54) + 'px'}">
      <!-- 标题和描述 - 放在最上面 -->
      <view class="main-form-section">
        <view class="form-item title-item">
          <input class="title-input" v-model="form.title" placeholder="输入组团标题（必填）" maxlength="50" />
        </view>
        
        <view class="form-item desc-item">
          <textarea class="desc-input" v-model="form.description" placeholder="详细描述组团内容、时间、地点等信息（必填）" maxlength="1000"></textarea>
        </view>
        
        <!-- 图片上传 -->
        <view class="image-upload-area">
          <view class="image-grid">
            <view class="image-item" v-for="(img, index) in images" :key="index">
              <image :src="img" mode="aspectFill"></image>
              <view class="delete-btn" @click="removeImage(index)">
                <text class="tn-icon-close"></text>
              </view>
            </view>
            <view class="add-btn" @click="chooseImage" v-if="images.length < 6">
              <text class="tn-icon-camera"></text>
              <text class="add-text">添加图片</text>
            </view>
          </view>
        </view>
      </view>
      
      <!-- 类型选择 -->
      <view class="category-section">
        <text class="category-label">选择类型</text>
        <view class="category-list">
          <view
            class="category-item"
            :class="{active: form.category === item.value}"
            v-for="item in categoryList"
            :key="item.value"
            @click="form.category = item.value"
          >
            <view class="category-icon" :style="{background: item.color}">
              <text :class="item.icon"></text>
            </view>
            <text class="category-name">{{item.name}}</text>
          </view>
        </view>
      </view>
      
      <!-- 其他表单项 -->
      <view class="form-section">
        <view class="form-item row">
          <text class="label">目标人数</text>
          <input class="input" type="number" v-model="form.targetCount" placeholder="必填" />
        </view>
        
        <view class="form-item row" v-if="form.category !== 'activity'">
          <text class="label">价格</text>
          <view class="price-input-wrap">
            <text class="price-symbol">¥</text>
            <input class="price-input" type="digit" v-model="form.price" placeholder="选填" />
          </view>
        </view>
        
        <view class="form-item row">
          <text class="label">截止时间</text>
          <picker mode="date" @change="onDateChange">
            <view class="picker-value">
              <text>{{form.endDate || '选填'}}</text>
              <text class="tn-icon-right"></text>
            </view>
          </picker>
        </view>
        
        <view class="form-item row">
          <text class="label">地点</text>
          <input class="input" v-model="form.location" placeholder="选填" />
        </view>
        
        <view class="form-item row">
          <text class="label">联系方式</text>
          <input class="input" v-model="form.contact" placeholder="手机号/微信（选填）" />
        </view>
      </view>
      
      <!-- 发布按钮 -->
      <view class="publish-btn-wrapper">
        <button class="publish-btn" :class="{active: canSubmit}" :loading="submitting" @click="submitGroup">发起组团</button>
      </view>
    </view>
  </view>
</template>

<script>
import { auth, storage, supabase } from '@/libs/supabase/supabase-mini.js'

export default {
  data() {
    return {
      categoryList: [
        { name: '邻里活动', value: 'activity', icon: 'tn-icon-team-fill', color: 'linear-gradient(135deg, #43E97B, #38F9D7)' },
        { name: '商家活动', value: 'merchant', icon: 'tn-icon-gift', color: 'linear-gradient(135deg, #FF6B6B, #FF8E53)' },
        { name: '山姆代购', value: 'sams', icon: 'tn-icon-shop-fill', color: 'linear-gradient(135deg, #4A90E2, #357ABD)' }
      ],
      form: {
        category: 'activity',
        title: '',
        description: '',
        targetCount: '',
        price: '',
        endDate: '',
        location: '',
        contact: ''
      },
      images: [],
      submitting: false
    }
  },
  computed: {
    canSubmit() {
      return this.form.title && this.form.description && this.form.targetCount && !this.submitting
    }
  },
  methods: {
    goBack() { uni.navigateBack() },
    onDateChange(e) { this.form.endDate = e.detail.value },
    chooseImage() {
      uni.chooseImage({
        count: 6 - this.images.length,
        sizeType: ['compressed'],
        success: (res) => { this.images = [...this.images, ...res.tempFilePaths] }
      })
    },
    removeImage(index) { this.images.splice(index, 1) },
    async submitGroup() {
      if (!this.form.title) return uni.showToast({ title: '请输入标题', icon: 'none' })
      if (!this.form.description) return uni.showToast({ title: '请输入描述', icon: 'none' })
      if (!this.form.targetCount) return uni.showToast({ title: '请输入目标人数', icon: 'none' })
      if (this.submitting) return
      
      this.submitting = true
      uni.showLoading({ title: '发布中...' })
      
      try {
        const user = auth.getLocalUser()
        if (!user) {
          uni.hideLoading()
          return uni.showToast({ title: '请先登录', icon: 'none' })
        }
        
        // 上传图片
        const imageUrls = []
        if (this.images.length > 0) {
          uni.showLoading({ title: '上传图片...' })
          for (let i = 0; i < this.images.length; i++) {
            const filePath = this.images[i]
            const fileName = `${user.id}_${Date.now()}_${i}.jpg`
            const { url, error } = await storage.uploadImage('groups', fileName, filePath)
            if (url) imageUrls.push(url)
          }
        }
        
        // 发起组团
        uni.showLoading({ title: '发布中...' })
        const { data, error } = await supabase.rpc('create_group', {
          p_user_id: user.id,
          p_title: this.form.title,
          p_description: this.form.description,
          p_images: imageUrls,
          p_target_count: parseInt(this.form.targetCount) || 0,
          p_price: parseFloat(this.form.price) || 0,
          p_end_time: this.form.endDate ? new Date(this.form.endDate + 'T23:59:59').toISOString() : null,
          p_location: this.form.location || '',
          p_contact: this.form.contact || '',
          p_category: this.form.category || 'activity'
        })
        
        if (error) throw error
        
        uni.hideLoading()
        uni.showToast({ title: '发起成功', icon: 'success' })
        setTimeout(() => uni.navigateBack(), 1500)
      } catch (e) {
        console.error('发起失败:', e)
        uni.hideLoading()
        uni.showToast({ title: e.message || '发起失败', icon: 'none' })
      } finally {
        this.submitting = false
      }
    }
  }
}
</script>

<style scoped>
.container { min-height: 100vh; background: linear-gradient(180deg, #E8F4FD 0%, #D6EBFA 50%, #C4E2F7 100%); }

.nav-bar { position: fixed; top: 0; left: 0; right: 0; z-index: 100; background: linear-gradient(135deg, #4A90E2, #357ABD); }
.nav-content { display: flex; justify-content: space-between; align-items: center; height: 88rpx; padding: 0 24rpx; }
.nav-cancel { font-size: 30rpx; color: rgba(255,255,255,0.9); padding: 10rpx; }
.nav-title { font-size: 34rpx; color: #fff; font-weight: 500; }
.nav-placeholder { width: 80rpx; }

.content { padding: 24rpx; }

/* 主表单区域 - 标题、描述、图片 */
.main-form-section { background: #fff; border-radius: 20rpx; padding: 32rpx; box-shadow: 0 4rpx 20rpx rgba(74, 144, 226, 0.08); }
.main-form-section .form-item { border-bottom: none; padding: 0; }
.main-form-section .title-item { margin-bottom: 20rpx; padding-bottom: 20rpx; border-bottom: 1rpx solid #f0f0f0; }
.main-form-section .desc-item { margin-bottom: 20rpx; }
.main-form-section .title-input {
  font-size: 34rpx;
  font-weight: 600;
  color: #333;
  width: 100%;
}
.main-form-section .desc-input {
  width: 100%;
  min-height: 180rpx;
  font-size: 28rpx;
  line-height: 1.8;
  color: #666;
}

/* 图片上传区域 */
.image-upload-area { padding-top: 16rpx; border-top: 1rpx solid #f5f5f5; }
.image-grid { display: flex; flex-wrap: wrap; gap: 16rpx; }
.image-item { position: relative; width: 160rpx; height: 160rpx; }
.image-item image { width: 100%; height: 100%; border-radius: 12rpx; object-fit: cover; }
.delete-btn { position: absolute; top: -12rpx; right: -12rpx; width: 44rpx; height: 44rpx; background: #FF5252; border-radius: 50%; display: flex; align-items: center; justify-content: center; box-shadow: 0 4rpx 12rpx rgba(255, 82, 82, 0.3); }
.delete-btn text { font-size: 24rpx; color: #fff; }
.add-btn { width: 160rpx; height: 160rpx; background: linear-gradient(135deg, #f8f9fa, #f0f2f5); border-radius: 12rpx; display: flex; flex-direction: column; align-items: center; justify-content: center; border: 2rpx dashed #d0d0d0; transition: all 0.2s; }
.add-btn:active { background: linear-gradient(135deg, #e8eaed, #e0e2e5); }
.add-btn text { color: #999; }
.add-btn text:first-child { font-size: 48rpx; color: #4A90E2; }
.add-text { font-size: 22rpx; margin-top: 8rpx; color: #999; }

/* 类型选择 */
.category-section { background: #fff; border-radius: 20rpx; margin-top: 20rpx; padding: 28rpx; box-shadow: 0 4rpx 20rpx rgba(74, 144, 226, 0.08); }
.category-label { font-size: 30rpx; color: #333; font-weight: 600; display: block; margin-bottom: 24rpx; }
.category-list { display: flex; justify-content: space-between; gap: 20rpx; }
.category-item { flex: 1; display: flex; flex-direction: column; align-items: center; padding: 24rpx 12rpx; border-radius: 20rpx; background: #f8f9fa; border: 3rpx solid transparent; transition: all 0.3s; }
.category-item:active { transform: scale(0.98); }
.category-item.active { background: linear-gradient(135deg, #E8F4FD, #D6EBFA); border-color: #4A90E2; box-shadow: 0 4rpx 16rpx rgba(74, 144, 226, 0.2); }
.category-icon { width: 88rpx; height: 88rpx; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin-bottom: 16rpx; box-shadow: 0 6rpx 16rpx rgba(0, 0, 0, 0.15); }
.category-icon text { font-size: 40rpx; color: #fff; }
.category-name { font-size: 26rpx; color: #666; }
.category-item.active .category-name { color: #4A90E2; font-weight: 600; }

/* 其他表单项 */
.form-section { background: #fff; border-radius: 20rpx; margin-top: 20rpx; padding: 8rpx 28rpx; box-shadow: 0 4rpx 20rpx rgba(74, 144, 226, 0.08); }
.form-item { padding: 28rpx 0; border-bottom: 1rpx solid #F5F5F5; }
.form-item:last-child { border-bottom: none; }
.form-item.row { display: flex; align-items: center; }
.label { font-size: 30rpx; color: #333; width: 180rpx; font-weight: 500; }
.picker-value { flex: 1; display: flex; justify-content: flex-end; align-items: center; }
.picker-value text { font-size: 28rpx; color: #999; }
.picker-value text:last-child { margin-left: 8rpx; color: #ccc; }
.price-input-wrap { flex: 1; display: flex; justify-content: flex-end; align-items: center; }
.price-symbol { font-size: 32rpx; color: #4A90E2; font-weight: bold; }
.price-input { width: 200rpx; text-align: right; font-size: 32rpx; color: #4A90E2; font-weight: bold; }
.input { flex: 1; text-align: right; font-size: 28rpx; color: #666; }

/* 发布按钮 */
.publish-btn-wrapper { padding: 40rpx 0 60rpx; }
.publish-btn { width: 100%; height: 100rpx; line-height: 100rpx; background: linear-gradient(135deg, #ccc, #bbb); color: #fff; font-size: 34rpx; font-weight: 600; border-radius: 50rpx; border: none; box-shadow: 0 8rpx 24rpx rgba(0, 0, 0, 0.1); transition: all 0.3s; }
.publish-btn.active { background: linear-gradient(135deg, #4A90E2, #357ABD); box-shadow: 0 8rpx 24rpx rgba(74, 144, 226, 0.4); }
.publish-btn:active { transform: scale(0.98); }
.publish-btn::after { border: none; }
</style>
