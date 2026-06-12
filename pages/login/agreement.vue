<template>
  <view class="container">
    <view class="nav-bar" :style="{paddingTop: vuex_status_bar_height + 'px'}">
      <view class="nav-content">
        <text class="tn-icon-left nav-back" @click="goBack"></text>
        <text class="nav-title">{{title}}</text>
        <view class="nav-placeholder"></view>
      </view>
    </view>
    
    <scroll-view class="content" scroll-y :style="{paddingTop: (vuex_status_bar_height + 44) + 'px'}">
      <!-- 加载中 -->
      <view class="loading-wrap" v-if="loading">
        <text class="loading-text">加载中...</text>
      </view>
      
      <!-- 加载失败，显示默认内容 -->
      <view class="doc" v-else>
        <text class="doc-title">{{docTitle}}</text>
        <text class="doc-date">更新日期：{{updateDate}}</text>
        
        <!-- 动态渲染章节 -->
        <view v-for="(section, index) in sections" :key="index">
          <text class="section-title">{{section.title}}</text>
          <text class="section-text">{{section.text}}</text>
        </view>
      </view>
    </scroll-view>
  </view>
</template>

<script>
import { db } from '@/libs/supabase/index.js'

// 默认用户协议内容
const DEFAULT_USER_AGREEMENT = {
  title: '珈邻用户服务协议',
  updateDate: '2026年1月1日',
  sections: [
    { title: '嗨，欢迎加入珈邻大家庭！', text: '珈邻是一个温暖的邻里社区平台，我们希望每位邻居都能在这里找到归属感。在开始之前，请花几分钟了解一下我们的约定，这能帮助我们一起维护这个美好的社区。' },
    { title: '一、我们能为您做什么', text: '在珈邻，您可以：\n• 分享生活点滴，记录邻里温情\n• 获取社区资讯，不错过身边的精彩\n我们会不断优化服务，让您的邻里生活更便捷。' },
    { title: '二、关于您的账号', text: '• 请使用真实信息注册，这样邻居们才能更好地认识您\n• 妥善保管您的密码，账号安全很重要哦\n• 账号仅限本人使用，不要借给他人' },
    { title: '三、做一个好邻居', text: '好的社区需要大家共同维护，请您：\n• 友善交流，尊重每一位邻居\n• 发布真实、有价值的内容\n• 不发布违法、虚假或伤害他人的信息\n• 交易时诚信为本，互相体谅\n如果有人违反约定，我们可能会采取提醒、限制功能等措施，希望您理解。' },
    { title: '四、关于内容版权', text: '您在珈邻发布的内容，版权归您所有。同时，您授权我们在平台内展示和推广这些内容，让更多邻居看到。珈邻的品牌、设计等知识产权归我们所有。' },
    { title: '五、温馨提示', text: '• 邻居间的交易由双方自行协商，请注意交易安全\n• 如遇网络故障等不可抗力，服务可能暂时中断\n• 我们会尽力审核内容，但无法保证所有信息的准确性，请您自行判断' },
    { title: '六、协议更新', text: '随着社区发展，我们可能会更新本协议。届时会在平台公布，继续使用即表示您同意新的约定。' },
    { title: '七、联系我们', text: '有任何问题或建议，欢迎通过"我的-意见反馈"告诉我们，我们很乐意倾听您的声音！' }
  ]
}

// 默认隐私政策内容
const DEFAULT_PRIVACY_POLICY = {
  title: '珈邻隐私政策',
  updateDate: '2026年1月1日',
  sections: [
    { title: '您的隐私，我们用心守护', text: '珈邻深知隐私对您的重要性。这份政策将帮助您了解我们如何收集、使用和保护您的信息。请放心，我们会像保护自己的隐私一样保护您的信息。' },
    { title: '一、我们收集哪些信息', text: '为了给您提供更好的服务，我们会收集：\n• 注册信息：手机号、昵称、头像（用于识别您的身份）\n• 设备信息：设备型号、系统版本（用于优化使用体验）\n• 使用记录：浏览和发布的内容（用于个性化推荐）\n我们只收集必要的信息，绝不过度索取。' },
    { title: '二、信息用途', text: '您的信息将用于：\n• 提供和改进我们的服务\n• 验证身份，保障账号安全\n• 推送您可能感兴趣的社区动态\n未经您同意，我们不会将信息用于其他目的。' },
    { title: '三、信息共享', text: '我们承诺：\n• 绝不出售您的个人信息\n• 仅在您明确同意、法律要求或保护公众权益时才会共享\n• 如需共享，会提前告知您' },
    { title: '四、信息安全', text: '我们采取多重措施保护您的信息：\n• 数据存储在中国境内的安全服务器\n• 使用加密技术传输和存储敏感信息\n• 严格限制员工访问权限\n如果您注销账号，我们会删除或匿名化处理您的信息。' },
    { title: '五、您的权利', text: '您随时可以：\n• 查看和修改您的个人资料\n• 删除您发布的内容\n• 注销账号并清除数据\n• 撤回之前的授权\n这些操作可在"后台-设置"中完成。' },
    { title: '六、未成年人保护', text: '我们特别关注未成年人的隐私保护。如果您未满14周岁，请在家长陪同下使用珈邻。' },
    { title: '七、政策更新', text: '我们可能会更新本政策。如有重大变更，会通过弹窗等方式通知您，请留意。' },
    { title: '八、联系我们', text: '如果您对隐私有任何疑问，欢迎通过"我的-意见反馈"联系我们，我们会尽快回复！' }
  ]
}

export default {
  data() {
    return {
      type: 'user',
      title: '用户协议',
      loading: true,
      docTitle: '',
      updateDate: '',
      sections: []
    }
  },
  onLoad(options) {
    this.type = options.type || 'user'
    this.title = this.type === 'user' ? '用户协议' : '隐私政策'
    this.loadAgreement()
  },
  methods: {
    goBack() { 
      uni.navigateBack() 
    },
    
    // 从 Supabase 加载协议内容
    async loadAgreement() {
      this.loading = true
      
      try {
        // 调用 RPC 函数获取协议配置
        const agreementType = this.type === 'user' ? 'user' : 'privacy'
        const { data, error } = await db.rpc('get_agreement_config', {
          p_type: agreementType
        })
        
        if (error) {
          console.log('[Agreement] 加载失败，使用默认内容:', error)
          this.useDefaultContent()
          return
        }
        
        // RPC 返回的是数组
        if (data && data.length > 0) {
          const config = data[0]
          this.docTitle = config.title
          this.updateDate = config.update_date
          
          // 解析 JSON 格式的内容
          try {
            this.sections = typeof config.content === 'string' 
              ? JSON.parse(config.content) 
              : config.content
          } catch (e) {
            console.log('[Agreement] 解析内容失败:', e)
            this.useDefaultContent()
            return
          }
        } else {
          console.log('[Agreement] 未找到配置，使用默认内容')
          this.useDefaultContent()
        }
      } catch (e) {
        console.log('[Agreement] 请求异常:', e)
        this.useDefaultContent()
      } finally {
        this.loading = false
      }
    },
    
    // 使用默认内容（当网络请求失败或未配置时）
    useDefaultContent() {
      const defaultData = this.type === 'user' ? DEFAULT_USER_AGREEMENT : DEFAULT_PRIVACY_POLICY
      this.docTitle = defaultData.title
      this.updateDate = defaultData.updateDate
      this.sections = defaultData.sections
    }
  }
}
</script>

<style scoped>
.container { min-height: 100vh; background: #fff; }
.nav-bar { position: fixed; top: 0; left: 0; right: 0; z-index: 100; background: #fff; border-bottom: 1rpx solid #f0f0f0; }
.nav-content { display: flex; justify-content: space-between; align-items: center; height: 88rpx; padding: 0 24rpx; }
.nav-back { font-size: 40rpx; color: #333; }
.nav-title { font-size: 34rpx; color: #333; font-weight: 500; }
.nav-placeholder { width: 40rpx; }

.content { height: 100vh; padding: 32rpx; box-sizing: border-box; }

.loading-wrap { 
  display: flex; 
  justify-content: center; 
  align-items: center; 
  padding: 100rpx 0; 
}
.loading-text { 
  font-size: 28rpx; 
  color: #999; 
}

.doc { padding-bottom: 60rpx; }
.doc-title { display: block; font-size: 40rpx; font-weight: bold; color: #333; text-align: center; margin-bottom: 16rpx; }
.doc-date { display: block; font-size: 24rpx; color: #999; text-align: center; margin-bottom: 48rpx; }
.section-title { display: block; font-size: 30rpx; font-weight: 600; color: #4A90E2; margin: 36rpx 0 16rpx; }
.section-text { display: block; font-size: 28rpx; color: #666; line-height: 1.8; white-space: pre-wrap; }
</style>
