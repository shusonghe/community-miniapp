<template>
  <view class="container">
    <!-- 顶部导航 -->
    <view class="nav-bar" :style="{paddingTop: vuex_status_bar_height + 'px'}">
      <view class="nav-content">
        <view class="back-btn" @click="goBack">
          <text class="tn-icon-left"></text>
        </view>
        <text class="nav-title">组团详情</text>
        <view class="nav-placeholder"></view>
      </view>
    </view>
    
    <scroll-view class="content" :style="{paddingTop: (vuex_status_bar_height + 44) + 'px'}" scroll-y>
      <!-- 图片轮播 -->
      <swiper class="image-swiper" indicator-dots indicator-color="rgba(255,255,255,0.5)" indicator-active-color="#fff" circular v-if="group.images && group.images.length">
        <swiper-item v-for="(img, index) in group.images" :key="index">
          <image :src="img" mode="aspectFit" @click="previewImage(index)"></image>
        </swiper-item>
      </swiper>
      <view class="no-image" v-else>
        <text class="tn-icon-image"></text>
      </view>
      
      <view class="detail-content" v-if="group.id">
        <!-- 基本信息 -->
        <view class="info-section">
          <text class="group-title">{{group.title}}</text>
          <view class="group-meta">
            <text class="group-price" v-if="group.price">¥{{group.price}}</text>
            <text class="group-count">{{group.current_count}}/{{group.target_count}}人</text>
          </view>
          <view class="progress-bar">
            <view class="progress-fill" :style="{width: progressPercent + '%'}"></view>
          </view>
          <!-- 倒计时 -->
          <view class="countdown-section" v-if="group.end_time && countdown.total > 0">
            <text class="countdown-label">距结束仅剩</text>
            <view class="countdown-timer">
              <view class="countdown-item">
                <text class="countdown-num">{{countdown.days}}</text>
                <text class="countdown-unit">天</text>
              </view>
              <text class="countdown-colon">:</text>
              <view class="countdown-item">
                <text class="countdown-num">{{countdown.hours}}</text>
                <text class="countdown-unit">时</text>
              </view>
              <text class="countdown-colon">:</text>
              <view class="countdown-item">
                <text class="countdown-num">{{countdown.minutes}}</text>
                <text class="countdown-unit">分</text>
              </view>
              <text class="countdown-colon">:</text>
              <view class="countdown-item">
                <text class="countdown-num">{{countdown.seconds}}</text>
                <text class="countdown-unit">秒</text>
              </view>
            </view>
          </view>
          <view class="countdown-expired" v-else-if="group.end_time && countdown.total <= 0">
            <text>组团已截止</text>
          </view>
        </view>
        
        <!-- 详细描述 -->
        <view class="desc-section">
          <text class="section-title">组团详情</text>
          <text class="desc-text">{{group.description}}</text>
          <view class="info-row" v-if="group.location">
            <text class="info-label">地点：</text>
            <text class="info-value">{{group.location}}</text>
          </view>
          <view class="info-row" v-if="group.end_time">
            <text class="info-label">截止：</text>
            <text class="info-value">{{formatDate(group.end_time)}}</text>
          </view>
          <view class="info-row" v-if="group.phone">
            <text class="info-label">电话：</text>
            <text class="info-value" @click="callPhone(group.phone)">{{group.phone}}</text>
          </view>
        </view>
        
        <!-- 发起人 -->
        <view class="organizer-section">
          <image class="organizer-avatar" :src="group.avatar_url || defaultAvatar"></image>
          <view class="organizer-info">
            <text class="organizer-name">{{group.nickname || '珈邻用户'}}</text>
            <text class="organizer-time">发起于 {{formatTime(group.created_at)}}</text>
          </view>
        </view>
        
        <!-- 参团成员 -->
        <view class="members-section" v-if="members.length > 0">
          <text class="section-title">已参团 ({{members.length}}人)</text>
          <!-- 头像预览行 -->
          <view class="members-avatars">
            <view class="avatar-item" v-for="(m, index) in members.slice(0, 5)" :key="m.id" :style="{zIndex: 5 - index}">
              <image class="avatar-img" :src="m.avatar_url || defaultAvatar"></image>
            </view>
            <view class="avatar-more" v-if="members.length > 5">
              <text>+{{members.length - 5}}</text>
            </view>
          </view>
          <view class="view-all-btn" @click="showAllMembers = !showAllMembers">
            <text>{{showAllMembers ? '收起团员' : '查看全部团员'}}</text>
          </view>
          <!-- 详细成员列表 -->
          <view class="members-detail-list" v-if="showAllMembers">
            <view class="member-card" v-for="m in members" :key="m.id">
              <image class="member-avatar" :src="m.avatar_url || defaultAvatar"></image>
              <view class="member-info">
                <text class="member-name">{{getMemberName(m)}}</text>
                <text class="member-building" v-if="getMemberBuilding(m)">{{getMemberBuilding(m)}}</text>
              </view>
            </view>
          </view>
        </view>
      </view>
    </scroll-view>
    
    <!-- 底部操作栏 -->
    <view class="bottom-bar" v-if="group.id">
      <view class="action-btn delete-btn" v-if="group.is_owner" @click="deleteGroup">
        <text>删除</text>
      </view>
      <view class="action-btn close-btn" v-if="group.is_owner && group.status === 'active'" @click="closeGroup">
        <text>结束组团</text>
      </view>
      <view class="join-btn" v-if="!group.is_owner" @click="toggleJoin">
        <text>{{group.joined ? '退出组团' : '立即参团'}}</text>
      </view>
    </view>
    
    <login-modal ref="loginModal"></login-modal>
    <!-- 注册提示弹框 -->
    <register-tip-modal ref="registerTipModal"></register-tip-modal>
  </view>
</template>

<script>
import authMixin from '@/libs/mixin/auth.mixin.js'
import loginModal from '@/components/login-modal/login-modal.vue'
import registerTipModal from '@/components/register-tip-modal/register-tip-modal.vue'
import { auth, supabase, storage } from '@/libs/supabase/supabase-mini.js'

export default {
  components: { loginModal, registerTipModal },
  mixins: [authMixin],
  data() {
    return {
      defaultAvatar: 'https://img.icons8.com/?size=100&id=s4mUhvTRUkP2&format=png&color=000000&padding=30',
      groupId: null,
      group: {},
      members: [],
      showAllMembers: false,
      countdown: {
        total: 0,
        days: '00',
        hours: '00',
        minutes: '00',
        seconds: '00'
      },
      countdownTimer: null
    }
  },
  computed: {
    progressPercent() {
      if (!this.group.target_count) return 0
      return Math.min(100, (this.group.current_count / this.group.target_count) * 100)
    }
  },
  onLoad(options) {
    if (options.id) {
      this.groupId = options.id
      this.loadDetail()
      this.loadMembers()
    }
  },
  onUnload() {
    // 清除倒计时定时器
    if (this.countdownTimer) {
      clearInterval(this.countdownTimer)
      this.countdownTimer = null
    }
  },
  methods: {
    goBack() { uni.navigateBack() },
    async loadDetail() {
      try {
        const user = auth.getLocalUser()
        const { data, error } = await supabase.rpc('get_group_detail', {
          p_group_id: parseInt(this.groupId),
          p_user_id: user ? user.id : null
        })
        
        if (error) throw error
        if (data) {
          this.group = data
          // 启动倒计时
          if (data.end_time) {
            this.startCountdown()
          }
        }
      } catch (e) {
        console.error('加载详情失败:', e)
        uni.showToast({ title: '加载失败', icon: 'none' })
      }
    },
    async loadMembers() {
      try {
        const { data, error } = await supabase.rpc('get_group_members', {
          p_group_id: parseInt(this.groupId)
        })
        
        if (error) throw error
        this.members = data || []
      } catch (e) {
        console.error('加载成员失败:', e)
      }
    },
    async toggleJoin() {
      const user = auth.getLocalUser()
      if (!user) {
        this.$refs.loginModal.show()
        return
      }
      
      // 微信用户没有手机号，显示注册提示弹框
      if (!user.phone || user.phone === '') {
        this.$refs.registerTipModal.show()
        return
      }
      
      try {
        if (this.group.joined) {
          // 退出组团
          const { data, error } = await supabase.rpc('leave_group', {
            p_group_id: parseInt(this.groupId),
            p_user_id: user.id
          })
          
          if (error || !data.success) {
            uni.showToast({ title: data?.message || '操作失败', icon: 'none' })
            return
          }
          
          this.group.joined = false
          this.group.current_count--
          uni.showToast({ title: '已退出', icon: 'success' })
        } else {
          // 参加组团
          const { data, error } = await supabase.rpc('join_group', {
            p_group_id: parseInt(this.groupId),
            p_user_id: user.id,
            p_quantity: 1,
            p_remark: ''
          })
          
          if (error || !data.success) {
            uni.showToast({ title: data?.message || '操作失败', icon: 'none' })
            return
          }
          
          this.group.joined = true
          this.group.current_count++
          uni.showToast({ title: '参团成功', icon: 'success' })
        }
        
        this.loadMembers()
      } catch (e) {
        console.error('操作失败:', e)
        uni.showToast({ title: '操作失败', icon: 'none' })
      }
    },
    deleteGroup() {
      uni.showModal({
        title: '提示',
        content: '确定要删除这个组团吗？',
        success: async (res) => {
          if (res.confirm) {
            uni.showLoading({ title: '删除中...' })
            
            const user = auth.getLocalUser()
            
            // 1. 先删除 Storage 中的图片
            if (this.group.images && this.group.images.length > 0) {
              console.log('[Delete] 删除图片:', this.group.images)
              await storage.deleteImages(this.group.images)
            }
            
            // 2. 再删除数据库记录
            const { data, error } = await supabase.rpc('delete_group', {
              p_group_id: parseInt(this.groupId),
              p_user_id: user.id
            })
            
            uni.hideLoading()
            
            if (error || !data.success) {
              uni.showToast({ title: data?.message || '删除失败', icon: 'none' })
              return
            }
            
            uni.showToast({ title: '已删除', icon: 'success' })
            setTimeout(() => uni.navigateBack(), 1500)
          }
        }
      })
    },
    closeGroup() {
      uni.showModal({
        title: '提示',
        content: '确定要结束这个组团吗？',
        success: async (res) => {
          if (res.confirm) {
            const user = auth.getLocalUser()
            const { data, error } = await supabase.rpc('update_group_status', {
              p_group_id: parseInt(this.groupId),
              p_user_id: user.id,
              p_status: 'closed'
            })
            
            if (error || !data.success) {
              uni.showToast({ title: data?.message || '操作失败', icon: 'none' })
              return
            }
            
            this.group.status = 'closed'
            uni.showToast({ title: '已结束', icon: 'success' })
          }
        }
      })
    },
    previewImage(index) {
      if (this.group.images && this.group.images.length) {
        uni.previewImage({ urls: this.group.images, current: this.group.images[index] })
      }
    },
    formatTime(time) {
      if (!time) return ''
      const date = new Date(time)
      const now = new Date()
      const diff = (now - date) / 1000
      
      if (diff < 60) return '刚刚'
      if (diff < 3600) return Math.floor(diff / 60) + '分钟前'
      if (diff < 86400) return Math.floor(diff / 3600) + '小时前'
      if (diff < 604800) return Math.floor(diff / 86400) + '天前'
      
      return `${date.getMonth() + 1}月${date.getDate()}日`
    },
    formatDate(time) {
      if (!time) return ''
      const date = new Date(time)
      return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`
    },
    callPhone(phone) {
      if (!phone) return
      uni.makePhoneCall({
        phoneNumber: phone,
        fail: () => {
          uni.setClipboardData({
            data: phone,
            success: () => {
              uni.showToast({ title: '电话已复制', icon: 'success' })
            }
          })
        }
      })
    },
    getMemberName(member) {
      // 显示昵称，如果没有昵称显示珈邻用户
      return member.nickname || '珈邻用户'
    },
    getMemberBuilding(member) {
      // 显示楼栋号
      return member.building || ''
    },
    startCountdown() {
      // 清除之前的定时器
      if (this.countdownTimer) {
        clearInterval(this.countdownTimer)
      }
      // 立即更新一次
      this.updateCountdown()
      // 每秒更新
      this.countdownTimer = setInterval(() => {
        this.updateCountdown()
      }, 1000)
    },
    updateCountdown() {
      if (!this.group.end_time) return
      
      const endTime = new Date(this.group.end_time).getTime()
      const now = Date.now()
      const diff = endTime - now
      
      if (diff <= 0) {
        this.countdown = {
          total: 0,
          days: '00',
          hours: '00',
          minutes: '00',
          seconds: '00'
        }
        // 停止定时器
        if (this.countdownTimer) {
          clearInterval(this.countdownTimer)
          this.countdownTimer = null
        }
        return
      }
      
      const days = Math.floor(diff / (1000 * 60 * 60 * 24))
      const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60))
      const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60))
      const seconds = Math.floor((diff % (1000 * 60)) / 1000)
      
      this.countdown = {
        total: diff,
        days: String(days).padStart(2, '0'),
        hours: String(hours).padStart(2, '0'),
        minutes: String(minutes).padStart(2, '0'),
        seconds: String(seconds).padStart(2, '0')
      }
    }
  }
}
</script>

<style scoped>
.container { min-height: 100vh; background: linear-gradient(180deg, #E8F4FD 0%, #f5f5f5 30%); }

.nav-bar { position: fixed; top: 0; left: 0; right: 0; z-index: 100; background: linear-gradient(135deg, #4A90E2, #357ABD); }
.nav-content { display: flex; justify-content: space-between; align-items: center; height: 88rpx; padding: 0 24rpx; }
.back-btn { width: 60rpx; height: 60rpx; display: flex; align-items: center; justify-content: center; }
.back-btn text { font-size: 36rpx; color: #fff; }
.nav-title { font-size: 34rpx; color: #fff; font-weight: 600; }
.nav-placeholder { width: 60rpx; }

.content { height: 100vh; padding-bottom: 140rpx; box-sizing: border-box; }

.image-swiper { width: 100%; height: 420rpx; background: #f0f0f0; }
.image-swiper image { width: 100%; height: 100%; }
.no-image { width: 100%; height: 320rpx; background: linear-gradient(135deg, #f5f5f5, #e8e8e8); display: flex; align-items: center; justify-content: center; }
.no-image text { font-size: 120rpx; color: #ddd; }

.detail-content { padding: 0 24rpx 24rpx; }

/* 基本信息卡片 */
.info-section { background: #fff; border-radius: 20rpx; padding: 28rpx; margin-top: -40rpx; position: relative; z-index: 10; box-shadow: 0 4rpx 20rpx rgba(0,0,0,0.08); }
.group-title { font-size: 38rpx; color: #333; font-weight: bold; display: block; margin-bottom: 20rpx; line-height: 1.4; }
.group-meta { display: flex; align-items: center; flex-wrap: wrap; gap: 16rpx; margin-bottom: 20rpx; }
.group-price { font-size: 40rpx; color: #FF6B6B; font-weight: bold; }
.group-count { font-size: 26rpx; color: #4A90E2; background: linear-gradient(135deg, #E8F4FD, #D6EBFA); padding: 8rpx 20rpx; border-radius: 20rpx; font-weight: 500; }
.progress-bar { height: 16rpx; background: #E8F4FD; border-radius: 8rpx; overflow: hidden; }
.progress-fill { height: 100%; background: linear-gradient(135deg, #4A90E2, #357ABD); border-radius: 8rpx; transition: width 0.3s ease; }

/* 倒计时样式 */
.countdown-section { margin-top: 28rpx; padding-top: 28rpx; border-top: 2rpx dashed #E8F4FD; text-align: center; }
.countdown-label { font-size: 28rpx; color: #FF6B6B; display: block; margin-bottom: 20rpx; font-weight: 500; }
.countdown-timer { display: flex; justify-content: center; align-items: center; gap: 12rpx; }
.countdown-item { display: flex; align-items: baseline; }
.countdown-num { font-size: 44rpx; font-weight: bold; color: #FF6B6B; background: linear-gradient(135deg, #FFF2F0, #FFE4E1); padding: 12rpx 20rpx; border-radius: 12rpx; min-width: 64rpx; text-align: center; box-shadow: 0 2rpx 8rpx rgba(255,107,107,0.2); }
.countdown-unit { font-size: 24rpx; color: #999; margin-left: 6rpx; }
.countdown-colon { font-size: 36rpx; color: #FF6B6B; font-weight: bold; }
.countdown-expired { margin-top: 28rpx; padding: 20rpx; background: linear-gradient(135deg, #f5f5f5, #eeeeee); border-radius: 12rpx; text-align: center; }
.countdown-expired text { font-size: 28rpx; color: #999; }

/* 详情区域 */
.desc-section { background: #fff; padding: 28rpx; margin-top: 20rpx; border-radius: 20rpx; box-shadow: 0 2rpx 12rpx rgba(0,0,0,0.04); }
.section-title { display: block; font-size: 32rpx; color: #333; font-weight: 600; margin-bottom: 20rpx; padding-left: 16rpx; border-left: 6rpx solid #4A90E2; }
.desc-text { font-size: 28rpx; color: #666; line-height: 1.8; white-space: pre-wrap; display: block; margin-bottom: 20rpx; }
.info-row { display: flex; margin-top: 16rpx; align-items: center; }
.info-label { font-size: 26rpx; color: #999; width: 100rpx; flex-shrink: 0; }
.info-value { font-size: 26rpx; color: #333; flex: 1; line-height: 1.5; }

/* 发起人区域 */
.organizer-section { display: flex; align-items: center; background: #fff; padding: 28rpx; margin-top: 20rpx; border-radius: 20rpx; box-shadow: 0 2rpx 12rpx rgba(0,0,0,0.04); }
.organizer-avatar { width: 100rpx; height: 100rpx; border-radius: 50%; margin-right: 24rpx; background: #f5f5f5; border: 4rpx solid #E8F4FD; }
.organizer-info { flex: 1; }
.organizer-name { display: block; font-size: 32rpx; color: #333; font-weight: 600; }
.organizer-time { display: block; font-size: 24rpx; color: #999; margin-top: 10rpx; }

/* 参团成员区域 */
.members-section { background: #fff; padding: 28rpx; margin-top: 20rpx; border-radius: 20rpx; box-shadow: 0 2rpx 12rpx rgba(0,0,0,0.04); }
.members-avatars { display: flex; justify-content: center; align-items: center; padding: 24rpx 0; }
.avatar-item { width: 96rpx; height: 96rpx; margin-left: -24rpx; border: 4rpx solid #fff; border-radius: 50%; overflow: hidden; background: #f5f5f5; box-shadow: 0 2rpx 8rpx rgba(0,0,0,0.1); }
.avatar-item:first-child { margin-left: 0; }
.avatar-img { width: 100%; height: 100%; }
.avatar-more { width: 96rpx; height: 96rpx; margin-left: -24rpx; border: 4rpx solid #fff; border-radius: 50%; background: rgba(0,0,0,0.6); display: flex; align-items: center; justify-content: center; box-shadow: 0 2rpx 8rpx rgba(0,0,0,0.1); }
.avatar-more text { font-size: 26rpx; color: #fff; font-weight: 600; }
.view-all-btn { text-align: center; padding: 20rpx 0; }
.view-all-btn text { font-size: 28rpx; color: #4A90E2; font-weight: 500; }
.members-detail-list { display: flex; flex-direction: column; gap: 16rpx; margin-top: 20rpx; padding-top: 20rpx; border-top: 2rpx dashed #f0f0f0; }
.member-card { display: flex; align-items: center; background: linear-gradient(135deg, #f8f9fa, #f5f5f5); padding: 24rpx; border-radius: 16rpx; }
.member-avatar { width: 88rpx; height: 88rpx; border-radius: 50%; background: #fff; margin-right: 20rpx; flex-shrink: 0; border: 3rpx solid #E8F4FD; }
.member-info { flex: 1; display: flex; flex-direction: column; }
.member-name { font-size: 30rpx; color: #333; font-weight: 500; }
.member-building { font-size: 26rpx; color: #999; margin-top: 6rpx; }

/* 底部操作栏 */
.bottom-bar { position: fixed; bottom: 0; left: 0; right: 0; display: flex; align-items: center; background: #fff; padding: 20rpx 28rpx; padding-bottom: calc(20rpx + env(safe-area-inset-bottom)); box-shadow: 0 -4rpx 24rpx rgba(0,0,0,0.08); gap: 20rpx; }
.action-btn { padding: 22rpx 36rpx; border-radius: 44rpx; transition: all 0.2s; }
.action-btn:active { transform: scale(0.96); }
.delete-btn { background: linear-gradient(135deg, #FFF2F0, #FFE4E1); border: 2rpx solid #FFD6D6; }
.delete-btn text { color: #FF6B6B; font-size: 28rpx; font-weight: 500; }
.close-btn { background: linear-gradient(135deg, #FFF7E6, #FFEDD5); border: 2rpx solid #FFE4B8; }
.close-btn text { color: #FAAD14; font-size: 28rpx; font-weight: 500; }
.join-btn { flex: 1; background: linear-gradient(135deg, #5B9FE8, #4A90E2); height: 96rpx; border-radius: 48rpx; display: flex; align-items: center; justify-content: center; box-shadow: 0 6rpx 20rpx rgba(74,144,226,0.35); transition: all 0.2s; }
.join-btn:active { transform: scale(0.98); box-shadow: 0 2rpx 10rpx rgba(74,144,226,0.3); }
.join-btn text { font-size: 34rpx; color: #fff; font-weight: 600; }
</style>
