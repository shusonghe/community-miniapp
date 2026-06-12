<template>
  <view class="container">
    <!-- 顶部导航 -->
    <view class="nav-bar" :style="{paddingTop: vuex_status_bar_height + 'px'}">
      <view class="nav-content">
        <text class="nav-cancel" @click="goBack">取消</text>
        <text class="nav-title">发布闲置</text>
        <view class="nav-placeholder"></view>
      </view>
    </view>
    
    <view class="content" :style="{paddingTop: (vuex_status_bar_height + 54) + 'px'}">
      <!-- 图片上传 -->
      <view class="image-section">
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
      
      <!-- 表单 -->
      <view class="form-section">
        <view class="form-item">
          <input class="title-input" v-model="form.title" placeholder="宝贝名称（必填）" maxlength="30" />
        </view>
        
        <view class="form-item">
          <textarea class="desc-input" v-model="form.description" placeholder="描述宝贝的成色、入手渠道、转手原因（必填）" maxlength="500"></textarea>
        </view>
        
        <view class="form-item row">
          <text class="label">分类</text>
          <picker :range="categories" @change="onCategoryChange">
            <view class="picker-value">
              <text>{{form.category || '请选择（必填）'}}</text>
              <text class="tn-icon-right"></text>
            </view>
          </picker>
        </view>
        
        <view class="form-item row">
          <text class="label">价格</text>
          <view class="price-input-wrap">
            <text class="price-symbol">¥</text>
            <input class="price-input" type="digit" v-model="form.price" placeholder="必填" />
          </view>
        </view>
        
        <view class="form-item row">
          <text class="label">原价</text>
          <view class="price-input-wrap">
            <text class="price-symbol">¥</text>
            <input class="price-input" type="digit" v-model="form.originalPrice" placeholder="选填" />
          </view>
        </view>
        
        <view class="form-item row">
          <text class="label">联系方式</text>
          <input class="input" v-model="form.phone" placeholder="手机号（选填）" type="number" maxlength="11" />
        </view>
      </view>
      
      <!-- 发布按钮 -->
      <view class="publish-btn-wrapper">
        <button class="publish-btn" :class="{active: canSubmit}" :loading="submitting" @click="submitGoods">发布闲置</button>
      </view>
    </view>
  </view>
</template>

<script>
import { auth, storage } from '@/libs/supabase/supabase-mini.js'
import { supabase, uploadFile } from '@/libs/supabase/supabase-mini.js'

export default {
  data() {
    return {
      categories: ['家具', '电器', '数码', '服饰', '母婴', '图书', '其他'],
      form: { title: '', description: '', category: '', price: '', originalPrice: '', phone: '' },
      images: [],
      submitting: false
    }
  },
  computed: {
    canSubmit() {
      return this.form.title && this.form.description && this.form.category && this.form.price && this.images.length > 0 && !this.submitting
    }
  },
  methods: {
    goBack() { uni.navigateBack() },
    onCategoryChange(e) { this.form.category = this.categories[e.detail.value] },
    chooseImage() {
      uni.chooseImage({
        count: 6 - this.images.length,
        sizeType: ['compressed'],
        success: (res) => { this.images = [...this.images, ...res.tempFilePaths] }
      })
    },
    removeImage(index) { this.images.splice(index, 1) },
    async submitGoods() {
      if (!this.form.title) return uni.showToast({ title: '请输入标题', icon: 'none' })
      if (!this.form.description) return uni.showToast({ title: '请输入描述', icon: 'none' })
      if (!this.form.category) return uni.showToast({ title: '请选择分类', icon: 'none' })
      if (!this.form.price) return uni.showToast({ title: '请输入价格', icon: 'none' })
      if (this.images.length === 0) return uni.showToast({ title: '请上传图片', icon: 'none' })
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
        uni.showLoading({ title: '上传图片...' })
        const imageUrls = []
        for (let i = 0; i < this.images.length; i++) {
          const filePath = this.images[i]
          const fileName = `${user.id}_${Date.now()}_${i}.jpg`
          const { url, error } = await storage.uploadImage('secondhand', fileName, filePath)
          if (url) imageUrls.push(url)
        }
        
        if (imageUrls.length === 0) {
          throw new Error('图片上传失败')
        }
        
        // 发布闲置
        uni.showLoading({ title: '发布中...' })
        const { data, error } = await supabase.rpc('create_secondhand_item', {
          p_user_id: user.id,
          p_title: this.form.title,
          p_description: this.form.description || '',
          p_images: imageUrls,
          p_category: this.form.category || '其他',
          p_price: parseFloat(this.form.price) || 0,
          p_original_price: parseFloat(this.form.originalPrice) || 0,
          p_phone: this.form.phone || ''
        })
        
        if (error) throw error
        
        uni.hideLoading()
        uni.showToast({ title: '发布成功', icon: 'success' })
        setTimeout(() => uni.navigateBack(), 1500)
      } catch (e) {
        console.error('发布失败:', e)
        uni.hideLoading()
        uni.showToast({ title: e.message || '发布失败', icon: 'none' })
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

.image-section { background: #fff; border-radius: 16rpx; padding: 24rpx; }
.image-grid { display: flex; flex-wrap: wrap; gap: 16rpx; }
.image-item { position: relative; width: 200rpx; height: 200rpx; }
.image-item image { width: 100%; height: 100%; border-radius: 12rpx; }
.delete-btn { position: absolute; top: 8rpx; right: 8rpx; width: 40rpx; height: 40rpx; background: rgba(0,0,0,0.5); border-radius: 50%; display: flex; align-items: center; justify-content: center; }
.delete-btn text { font-size: 22rpx; color: #fff; }
.add-btn { width: 200rpx; height: 200rpx; background: #F7F8FA; border-radius: 12rpx; display: flex; flex-direction: column; align-items: center; justify-content: center; border: 2rpx dashed #ddd; }
.add-btn text { color: #999; }
.add-btn text:first-child { font-size: 56rpx; }
.add-text { font-size: 24rpx; margin-top: 8rpx; }

.form-section { background: #fff; border-radius: 16rpx; margin-top: 16rpx; padding: 0 24rpx; }
.form-item { padding: 24rpx 0; border-bottom: 1rpx solid #F5F5F5; }
.form-item:last-child { border-bottom: none; }
.form-item.row { display: flex; align-items: center; }
.label { font-size: 30rpx; color: #333; width: 160rpx; }
.title-input { font-size: 32rpx; font-weight: 500; }
.desc-input { width: 100%; min-height: 200rpx; font-size: 28rpx; line-height: 1.6; }
.picker-value { flex: 1; display: flex; justify-content: flex-end; align-items: center; }
.picker-value text { font-size: 28rpx; color: #999; }
.picker-value text:last-child { margin-left: 8rpx; }
.price-input-wrap { flex: 1; display: flex; justify-content: flex-end; align-items: center; }
.price-symbol { font-size: 32rpx; color: #4A90E2; font-weight: bold; }
.price-input { width: 200rpx; text-align: right; font-size: 32rpx; color: #4A90E2; font-weight: bold; }
.input { flex: 1; text-align: right; font-size: 28rpx; }

/* 发布按钮 */
.publish-btn-wrapper { padding: 40rpx 0; }
.publish-btn { width: 100%; height: 96rpx; line-height: 96rpx; background: #ccc; color: #fff; font-size: 32rpx; font-weight: 500; border-radius: 48rpx; border: none; }
.publish-btn.active { background: linear-gradient(135deg, #4A90E2, #357ABD); }
.publish-btn::after { border: none; }
</style>
