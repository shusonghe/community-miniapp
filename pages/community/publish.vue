<template>
  <view class="container">
    <!-- 顶部导航 -->
    <view class="nav-bar" :style="{paddingTop: vuex_status_bar_height + 'px'}">
      <view class="nav-content">
        <text class="nav-cancel" @click="goBack">取消</text>
        <text class="nav-title">发布动态</text>
        <view class="nav-placeholder"></view>
      </view>
    </view>
    
    <view class="content" :style="{paddingTop: (vuex_status_bar_height + 54) + 'px'}">
      <!-- 输入区域 -->
      <view class="editor-area">
        <textarea 
          class="content-input" 
          v-model="content" 
          placeholder="分享你的邻里生活..."
          maxlength="2000"
          auto-height
          :focus="true"
        ></textarea>
        
        <!-- 图片区域 -->
        <view class="image-grid" v-if="images.length > 0">
          <view class="image-item" v-for="(img, index) in images" :key="index">
            <image :src="img" mode="aspectFill"></image>
            <view class="delete-btn" @click="removeImage(index)">
              <text class="tn-icon-close"></text>
            </view>
          </view>
          <view class="add-btn" @click="chooseImage" v-if="images.length < 6">
            <text class="tn-icon-add"></text>
          </view>
        </view>
      </view>
      
      <!-- 工具栏 -->
      <view class="toolbar">
        <view class="tool-item" @click="chooseImage">
          <text class="tn-icon-image-fill tool-icon" style="color: #43E97B;"></text>
          <text class="tool-text">图片</text>
        </view>
        <view class="tool-item" @click="chooseLocation">
          <text class="tn-icon-location-fill tool-icon" style="color: #4FACFE;"></text>
          <text class="tool-text">{{location || '位置'}}</text>
        </view>
        <view class="tool-item" @click="showTopicPicker">
          <text class="tn-icon-topic tool-icon" style="color: #FA709A;"></text>
          <text class="tool-text">{{topic || '话题'}}</text>
        </view>
      </view>
      
      <!-- 发布按钮 -->
      <view class="publish-btn-wrapper">
        <button class="publish-btn" :class="{active: canPublish}" :loading="publishing" @click="submitPost">发布动态</button>
      </view>
    </view>
    
    <!-- 话题选择弹窗 -->
    <view class="topic-mask" v-if="showTopic" @click="showTopic = false">
      <view class="topic-content" @click.stop>
        <view class="topic-header">
          <text class="topic-title">选择话题</text>
          <text class="topic-close" @click="showTopic = false">×</text>
        </view>
        <view class="topic-list">
          <view 
            class="topic-item" 
            :class="{active: topic === item}"
            v-for="item in topicList" 
            :key="item"
            @click="selectTopic(item)"
          >
            <text>#{{item}}</text>
          </view>
        </view>
      </view>
    </view>
  </view>
</template>

<script>
import { auth, db, storage } from '@/libs/supabase/supabase-mini.js'

export default {
  data() {
    return {
      content: '',
      images: [],
      location: '',
      topic: '',
      showTopic: false,
      topicList: ['邻里互助', '社区活动', '美食分享', '宠物日常', '育儿交流', '生活妙招', '二手闲置', '拼车出行'],
      publishing: false
    }
  },
  computed: {
    canPublish() {
      return this.content.trim().length > 0 && !this.publishing
    }
  },
  methods: {
    goBack() {
      uni.navigateBack()
    },
    chooseImage() {
      const remaining = 6 - this.images.length
      if (remaining <= 0) {
        return uni.showToast({ title: '最多上传6张图片', icon: 'none' })
      }
      uni.chooseImage({
        count: remaining,
        sizeType: ['compressed'],
        success: (res) => {
          this.images = [...this.images, ...res.tempFilePaths]
        }
      })
    },
    removeImage(index) {
      this.images.splice(index, 1)
    },
    chooseLocation() {
      uni.chooseLocation({
        success: (res) => {
          this.location = res.name || res.address || ''
        },
        fail: () => {
          uni.showToast({ title: '获取位置失败', icon: 'none' })
        }
      })
    },
    showTopicPicker() {
      this.showTopic = true
    },
    selectTopic(item) {
      this.topic = this.topic === item ? '' : item
      this.showTopic = false
    },
    async uploadImages() {
      if (this.images.length === 0) return []
      
      const user = auth.getLocalUser()
      const uploadedUrls = []
      
      for (let i = 0; i < this.images.length; i++) {
        const filePath = this.images[i]
        const fileName = `${user.id}_${Date.now()}_${i}.jpg`
        
        const { url, error } = await storage.uploadImage('posts', fileName, filePath)
        if (error) {
          throw new Error(`图片${i + 1}上传失败`)
        }
        uploadedUrls.push(url)
      }
      
      return uploadedUrls
    },
    async submitPost() {
      if (!this.canPublish) return
      
      const user = auth.getLocalUser()
      if (!user) {
        return uni.showToast({ title: '请先登录', icon: 'none' })
      }
      
      this.publishing = true
      uni.showLoading({ title: '发布中...' })
      
      try {
        // 上传图片
        let imageUrls = []
        if (this.images.length > 0) {
          uni.showLoading({ title: '上传图片...' })
          imageUrls = await this.uploadImages()
        }
        
        // 发布动态
        uni.showLoading({ title: '发布中...' })
        const { data, error } = await db.rpc('create_post', {
          p_user_id: user.id,
          p_content: this.content.trim(),
          p_images: imageUrls,
          p_location: this.location,
          p_topic: this.topic
        })
        
        uni.hideLoading()
        
        if (error || (data && !data.success)) {
          throw new Error(error?.message || data?.message || '发布失败')
        }
        
        uni.showToast({ title: '发布成功', icon: 'success' })
        
        // 通知社区页面刷新
        uni.$emit('postPublished')
        
        setTimeout(() => uni.navigateBack(), 1500)
      } catch (e) {
        uni.hideLoading()
        uni.showToast({ title: e.message || '发布失败', icon: 'none' })
      } finally {
        this.publishing = false
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

.editor-area { background: #fff; border-radius: 16rpx; padding: 24rpx; min-height: 400rpx; }
.content-input { width: 100%; min-height: 200rpx; font-size: 32rpx; line-height: 1.7; color: #333; }

.image-grid { display: flex; flex-wrap: wrap; gap: 16rpx; margin-top: 24rpx; padding-top: 24rpx; border-top: 1rpx solid #f5f5f5; }
.image-item { position: relative; width: 200rpx; height: 200rpx; }
.image-item image { width: 100%; height: 100%; border-radius: 12rpx; }
.delete-btn { position: absolute; top: 8rpx; right: 8rpx; width: 40rpx; height: 40rpx; background: rgba(0,0,0,0.5); border-radius: 50%; display: flex; align-items: center; justify-content: center; }
.delete-btn text { font-size: 22rpx; color: #fff; }
.add-btn { width: 200rpx; height: 200rpx; background: #F7F8FA; border-radius: 12rpx; display: flex; flex-direction: column; align-items: center; justify-content: center; border: 2rpx dashed #ddd; }
.add-btn text { font-size: 56rpx; color: #ccc; }

.toolbar { display: flex; margin-top: 24rpx; padding: 28rpx 24rpx; background: #fff; border-radius: 16rpx; }
.tool-item { display: flex; align-items: center; margin-right: 48rpx; }
.tool-icon { font-size: 40rpx; margin-right: 8rpx; }
.tool-text { font-size: 26rpx; color: #666; max-width: 150rpx; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }

/* 发布按钮 */
.publish-btn-wrapper { padding: 40rpx 0; }
.publish-btn { width: 100%; height: 96rpx; line-height: 96rpx; background: #ccc; color: #fff; font-size: 32rpx; font-weight: 500; border-radius: 48rpx; border: none; }
.publish-btn.active { background: linear-gradient(135deg, #4A90E2, #357ABD); }
.publish-btn::after { border: none; }

/* 话题弹窗 */
.topic-mask { position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.5); z-index: 1000; display: flex; align-items: flex-end; }
.topic-content { width: 100%; background: #fff; border-radius: 24rpx 24rpx 0 0; padding-bottom: env(safe-area-inset-bottom); }
.topic-header { display: flex; justify-content: space-between; align-items: center; padding: 32rpx; border-bottom: 1rpx solid #f5f5f5; }
.topic-title { font-size: 32rpx; color: #333; font-weight: 500; }
.topic-close { font-size: 48rpx; color: #999; line-height: 1; }
.topic-list { display: flex; flex-wrap: wrap; padding: 24rpx; gap: 20rpx; }
.topic-item { padding: 16rpx 28rpx; background: #F7F8FA; border-radius: 32rpx; }
.topic-item text { font-size: 28rpx; color: #666; }
.topic-item.active { background: #E8F4FD; }
.topic-item.active text { color: #4A90E2; }
</style>
