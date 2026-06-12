<template>
  <view class="container">
    <!-- 顶部图片 -->
    <view class="header-image">
      <image class="cover-image" :src="detail.image" mode="aspectFill"></image>
      <view class="back-btn" :style="{top: (vuex_status_bar_height + 10) + 'px'}" @click="goBack">
        <text class="tn-icon-left"></text>
      </view>
      <view class="image-tag">{{detail.tag}}</view>
    </view>
    
    <!-- 基本信息 -->
    <view class="info-section">
      <view class="info-header">
        <text class="info-title">{{detail.title}}</text>
        <text class="info-status" :class="detail.status">{{detail.statusText}}</text>
      </view>
      <view class="info-meta">
        <view class="meta-item">
          <text class="tn-icon-time meta-icon"></text>
          <text>{{detail.date}}</text>
        </view>
        <view class="meta-item" @click="showMembers">
          <text class="tn-icon-my meta-icon"></text>
          <text class="member-link">已报名 {{detail.joined}}/{{detail.total}} 人 ></text>
        </view>
      </view>
      <!-- 发起人信息 -->
      <view class="organizer-info">
        <image class="organizer-avatar" :src="detail.organizerAvatar" mode="aspectFill"></image>
        <view class="organizer-detail">
          <text class="organizer-name">{{detail.organizer}}</text>
          <text class="organizer-label">发起人</text>
        </view>
        <view class="contact-organizer" @click="contactOrganizer">
          <text class="tn-icon-service"></text>
          <text>联系TA</text>
        </view>
      </view>
    </view>
    
    <!-- 组团成员 -->
    <view class="detail-section" v-if="detail.members && detail.members.length">
      <view class="section-header">
        <text class="section-title">已报名成员</text>
        <text class="view-all" @click="showMembers">查看全部</text>
      </view>
      <view class="member-list">
        <view class="member-item" v-for="(member, index) in detail.members.slice(0, 6)" :key="index">
          <image class="member-avatar" :src="member.avatar" mode="aspectFill"></image>
          <text class="member-name">{{member.name}}</text>
        </view>
        <view class="member-item more" v-if="detail.members.length > 6" @click="showMembers">
          <view class="member-more">+{{detail.members.length - 6}}</view>
          <text class="member-name">更多</text>
        </view>
      </view>
    </view>
    
    <!-- 活动详情 -->
    <view class="detail-section">
      <text class="section-title">活动详情</text>
      <view class="detail-content">
        <text>{{detail.content}}</text>
      </view>
    </view>
    
    <!-- 费用说明 -->
    <view class="detail-section">
      <text class="section-title">费用说明</text>
      <view class="detail-content">
        <text>{{detail.fee}}</text>
      </view>
    </view>
    
    <!-- 注意事项 -->
    <view class="detail-section">
      <text class="section-title">注意事项</text>
      <view class="detail-content">
        <text>{{detail.notice}}</text>
      </view>
    </view>
    
    <!-- 底部按钮 -->
    <view class="bottom-bar">
      <view class="action-btn" @click="showMembers">
        <text class="tn-icon-team"></text>
        <text>成员</text>
      </view>
      <view class="action-btn" @click="shareActivity">
        <text class="tn-icon-share"></text>
        <text>分享</text>
      </view>
      <view class="join-btn" :class="{disabled: detail.status !== 'ongoing'}" @click="joinGroup">
        <text>{{detail.status === 'ended' ? '活动已结束' : detail.status === 'full' ? '已满员' : '立即报名'}}</text>
      </view>
    </view>
    
    <!-- 成员弹窗 -->
    <view class="member-popup" v-if="showMemberPopup" @click="closeMemberPopup">
      <view class="popup-content" @click.stop>
        <view class="popup-header">
          <text class="popup-title">报名成员（{{detail.members.length}}人）</text>
          <text class="tn-icon-close popup-close" @click="closeMemberPopup"></text>
        </view>
        <scroll-view class="popup-body" scroll-y>
          <view class="popup-member" v-for="(member, index) in detail.members" :key="index">
            <image class="popup-avatar" :src="member.avatar" mode="aspectFill"></image>
            <view class="popup-info">
              <text class="popup-name">{{member.name}}</text>
              <text class="popup-building">{{member.building}}</text>
            </view>
            <text class="popup-time">{{member.joinTime}}</text>
          </view>
        </scroll-view>
      </view>
    </view>
    
    <!-- 报名弹窗 -->
    <view class="join-popup" v-if="showJoinPopup" @click="closeJoinPopup">
      <view class="popup-content join-content" @click.stop>
        <view class="popup-header">
          <text class="popup-title">报名参加</text>
          <text class="tn-icon-close popup-close" @click="closeJoinPopup"></text>
        </view>
        <view class="join-form">
          <view class="form-item">
            <text class="form-label">姓名</text>
            <input class="form-input" v-model="joinForm.name" placeholder="请输入姓名" />
          </view>
          <view class="form-item">
            <text class="form-label">手机号</text>
            <input class="form-input" v-model="joinForm.phone" placeholder="请输入手机号" type="number" />
          </view>
          <view class="form-item">
            <text class="form-label">人数</text>
            <view class="number-box">
              <text class="num-btn" @click="changeNum(-1)">-</text>
              <text class="num-value">{{joinForm.num}}</text>
              <text class="num-btn" @click="changeNum(1)">+</text>
            </view>
          </view>
          <view class="form-item">
            <text class="form-label">备注</text>
            <input class="form-input" v-model="joinForm.remark" placeholder="选填，如有特殊需求请注明" />
          </view>
          <view class="submit-btn" @click="submitJoin">
            <text>确认报名</text>
          </view>
        </view>
      </view>
    </view>
  </view>
</template>

<script>
export default {
  data() {
    return {
      showMemberPopup: false,
      showJoinPopup: false,
      joinForm: { name: '', phone: '', num: 1, remark: '' },
      detail: {
        id: 1, tag: '周末露营', title: '大鹏较场尾海边露营',
        image: 'https://picsum.photos/seed/camping/800/400',
        joined: 8, total: 15, status: 'ongoing', statusText: '报名中',
        date: '1月18日(周六) 15:00',
        organizer: '3栋李哥', organizerAvatar: 'https://picsum.photos/seed/user1/100/100',
        content: '【活动安排】\n\n15:00 小区门口集合，拼车出发\n17:00 抵达较场尾，选址搭帐篷\n18:30 海边看日落\n19:30 BBQ烧烤晚餐\n21:00 沙滩游戏/聊天\n\n次日：\n06:30 早起看日出\n08:00 早餐后自由活动\n11:00 收拾返程',
        fee: '费用AA制，预计人均150-200元\n包含：露营场地费、BBQ食材、早餐\n自备：帐篷睡袋（没有的可以租）',
        notice: '1. 请自行准备防蚊虫用品\n2. 带好换洗衣物和洗漱用品\n3. 有帐篷的邻居请备注\n4. 活动前一天如遇恶劣天气将取消',
        members: []
      }
    }
  },
  onLoad(options) {
    if (options.id) { this.loadDetail(options.id) }
  },
  methods: {
    goBack() { uni.navigateBack() },
    loadDetail(id) {
      const membersData = [
        { avatar: 'https://picsum.photos/seed/member1/100/100', name: '王先生', building: '1栋2单元', joinTime: '1月10日' },
        { avatar: 'https://picsum.photos/seed/member2/100/100', name: '张姐', building: '5栋1单元', joinTime: '1月11日' },
        { avatar: 'https://picsum.photos/seed/member3/100/100', name: '刘哥', building: '2栋3单元', joinTime: '1月11日' },
        { avatar: 'https://picsum.photos/seed/member4/100/100', name: '陈阿姨', building: '6栋1单元', joinTime: '1月11日' },
        { avatar: 'https://picsum.photos/seed/member5/100/100', name: '赵妈', building: '4栋2单元', joinTime: '1月12日' },
        { avatar: 'https://picsum.photos/seed/member6/100/100', name: '孙先生', building: '3栋3单元', joinTime: '1月12日' },
        { avatar: 'https://picsum.photos/seed/member7/100/100', name: '周姐', building: '1栋1单元', joinTime: '1月12日' }
      ]
      const dataMap = {
        '1': {
          id: 1, tag: '周末露营', title: '大鹏较场尾海边露营',
          image: 'https://picsum.photos/seed/camping/800/400',
          joined: 8, total: 15, status: 'ongoing', statusText: '报名中',
          date: '1月18日(周六) 15:00',
          organizer: '3栋李哥', organizerAvatar: 'https://picsum.photos/seed/user1/100/100',
          content: '【活动安排】\n\n15:00 小区门口集合，拼车出发\n17:00 抵达较场尾，选址搭帐篷\n18:30 海边看日落\n19:30 BBQ烧烤晚餐\n21:00 沙滩游戏/聊天\n\n次日：\n06:30 早起看日出\n08:00 早餐后自由活动\n11:00 收拾返程',
          fee: '费用AA制，预计人均150-200元\n包含：露营场地费、BBQ食材、早餐\n自备：帐篷睡袋（没有的可以租）',
          notice: '1. 请自行准备防蚊虫用品\n2. 带好换洗衣物和洗漱用品\n3. 有帐篷的邻居请备注\n4. 活动前一天如遇恶劣天气将取消',
          members: membersData.slice(0, 8)
        },
        '2': {
          id: 2, tag: '爬山徒步', title: '凤凰山登山活动',
          image: 'https://picsum.photos/seed/mountain/800/400',
          joined: 12, total: 20, status: 'ongoing', statusText: '报名中',
          date: '1月19日(周日) 08:00',
          organizer: '5栋王姐', organizerAvatar: 'https://picsum.photos/seed/user2/100/100',
          content: '【活动安排】\n\n08:00 小区门口集合出发\n09:00 抵达凤凰山入口\n09:30 开始登山\n11:30 山顶合影、休息\n12:30 下山\n14:00 预计返回小区',
          fee: '费用AA制，预计人均30元\n包含：往返拼车费用\n自备：登山鞋、饮用水、干粮',
          notice: '1. 请穿运动鞋，带足饮用水\n2. 量力而行，不要逞强\n3. 有心脏病高血压者慎重参加\n4. 请自备午餐或山顶购买',
          members: membersData.slice(0, 6)
        },
        '3': {
          id: 3, tag: '亲子活动', title: '莲花山公园放风筝',
          image: 'https://picsum.photos/seed/park/800/400',
          joined: 6, total: 10, status: 'ongoing', statusText: '报名中',
          date: '1月19日(周日) 14:00',
          organizer: '1栋陈妈', organizerAvatar: 'https://picsum.photos/seed/user3/100/100',
          content: '【活动安排】\n\n14:00 莲花山公园南门集合\n14:30 草坪放风筝\n16:00 野餐时间\n17:30 活动结束，自行返回',
          fee: '费用自理\n风筝可自带或现场购买（约20-50元）\n野餐食物各家自备',
          notice: '1. 适合3岁以上小朋友\n2. 请自备野餐垫和食物\n3. 注意看管好小朋友\n4. 如遇下雨活动取消',
          members: membersData.slice(0, 4)
        },
        '4': {
          id: 4, tag: '户外烧烤', title: '光明农场烧烤聚会',
          image: 'https://picsum.photos/seed/bbq/800/400',
          joined: 10, total: 10, status: 'full', statusText: '已满员',
          date: '1月18日(周六) 10:00',
          organizer: '2栋张哥', organizerAvatar: 'https://picsum.photos/seed/user4/100/100',
          content: '【活动安排】\n\n10:00 小区门口集合，自驾出发\n11:00 抵达光明农场\n11:30 准备食材，生火\n12:00 开始烧烤\n15:00 收拾场地\n16:00 返程',
          fee: '费用AA制，预计人均80-100元\n包含：场地费、食材、饮料\n自驾油费另算',
          notice: '1. 需要自驾，请有车的邻居报名\n2. 食材统一采购\n3. 请注意防火安全\n4. 垃圾请带走',
          members: membersData
        },
        '5': {
          id: 5, tag: '骑行运动', title: '深圳湾骑行看日落',
          image: 'https://picsum.photos/seed/cycling/800/400',
          joined: 15, total: 15, status: 'ended', statusText: '已结束',
          date: '1月12日(周日) 17:00',
          organizer: '6栋小刘', organizerAvatar: 'https://picsum.photos/seed/user5/100/100',
          content: '【活动回顾】\n\n活动已圆满结束！\n感谢15位邻居的参与，我们一起骑行了深圳湾，看到了超美的日落。\n\n下次活动敬请期待～',
          fee: '本次活动费用：人均35元\n包含：共享单车费用、饮料',
          notice: '活动已结束，感谢参与！',
          members: membersData.slice(0, 7)
        }
      }
      if (dataMap[id]) { this.detail = dataMap[id] }
    },
    showMembers() { this.showMemberPopup = true },
    closeMemberPopup() { this.showMemberPopup = false },
    contactOrganizer() {
      uni.showToast({ title: '请在小区群联系发起人', icon: 'none', duration: 2000 })
    },
    shareActivity() {
      uni.showToast({ title: '功能开发中，敬请期待', icon: 'none' })
    },
    joinGroup() {
      if (this.detail.status !== 'ongoing') return
      this.showJoinPopup = true
    },
    closeJoinPopup() { this.showJoinPopup = false },
    changeNum(delta) {
      const newNum = this.joinForm.num + delta
      if (newNum >= 1 && newNum <= 5) { this.joinForm.num = newNum }
    },
    submitJoin() {
      if (!this.joinForm.name) {
        return uni.showToast({ title: '请输入姓名', icon: 'none' })
      }
      if (!this.joinForm.phone || this.joinForm.phone.length !== 11) {
        return uni.showToast({ title: '请输入正确的手机号', icon: 'none' })
      }
      uni.showToast({ title: '报名成功！', icon: 'success' })
      this.closeJoinPopup()
      this.detail.joined += this.joinForm.num
      this.joinForm = { name: '', phone: '', num: 1, remark: '' }
    }
  }
}
</script>

<style scoped>
.container { min-height: 100vh; background: #F5F7FA; padding-bottom: 140rpx; }
.header-image { position: relative; width: 100%; height: 400rpx; }
.cover-image { width: 100%; height: 100%; }
.back-btn { position: absolute; left: 24rpx; width: 64rpx; height: 64rpx; background: rgba(0,0,0,0.4); border-radius: 50%; display: flex; align-items: center; justify-content: center; }
.back-btn text { font-size: 36rpx; color: #fff; }
.image-tag { position: absolute; bottom: 20rpx; left: 20rpx; font-size: 24rpx; color: #fff; background: linear-gradient(135deg, #4A90E2, #357ABD); padding: 8rpx 20rpx; border-radius: 8rpx; }
.info-section { background: #fff; margin: -40rpx 24rpx 24rpx; border-radius: 20rpx; padding: 28rpx; position: relative; box-shadow: 0 4rpx 16rpx rgba(0,0,0,0.08); }
.info-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 16rpx; }
.info-title { font-size: 36rpx; color: #333; font-weight: 600; flex: 1; }
.info-status { font-size: 22rpx; padding: 6rpx 16rpx; border-radius: 6rpx; margin-left: 16rpx; }
.info-status.ongoing { color: #52C41A; background: #F6FFED; }
.info-status.full { color: #FF9500; background: #FFF7E6; }
.info-status.ended { color: #999; background: #F5F5F5; }
.info-meta { display: flex; flex-wrap: wrap; gap: 24rpx; margin-bottom: 24rpx; padding-bottom: 24rpx; border-bottom: 1rpx solid #F0F0F0; }
.meta-item { display: flex; align-items: center; font-size: 26rpx; color: #666; }
.meta-icon { font-size: 28rpx; margin-right: 8rpx; color: #4A90E2; }
.member-link { color: #4A90E2; }
.organizer-info { display: flex; align-items: center; }
.organizer-avatar { width: 80rpx; height: 80rpx; border-radius: 50%; }
.organizer-detail { flex: 1; margin-left: 16rpx; }
.organizer-name { display: block; font-size: 28rpx; color: #333; font-weight: 500; }
.organizer-label { display: block; font-size: 22rpx; color: #999; margin-top: 4rpx; }
.contact-organizer { display: flex; align-items: center; padding: 12rpx 20rpx; background: #F0F7FF; border-radius: 8rpx; }
.contact-organizer text { font-size: 24rpx; color: #4A90E2; }
.contact-organizer text:first-child { font-size: 28rpx; margin-right: 6rpx; }
.detail-section { background: #fff; margin: 0 24rpx 24rpx; border-radius: 16rpx; padding: 28rpx; }
.section-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 20rpx; padding-bottom: 16rpx; border-bottom: 1rpx solid #F0F0F0; }
.section-title { font-size: 30rpx; color: #333; font-weight: 500; }
.view-all { font-size: 26rpx; color: #4A90E2; }
.member-list { display: flex; flex-wrap: wrap; gap: 24rpx; }
.member-item { display: flex; flex-direction: column; align-items: center; width: 100rpx; }
.member-avatar { width: 80rpx; height: 80rpx; border-radius: 50%; }
.member-name { font-size: 22rpx; color: #666; margin-top: 8rpx; }
.member-more { width: 80rpx; height: 80rpx; border-radius: 50%; background: #F0F0F0; display: flex; align-items: center; justify-content: center; font-size: 24rpx; color: #999; }
.detail-content { font-size: 28rpx; color: #666; line-height: 1.8; white-space: pre-wrap; }
.bottom-bar { position: fixed; bottom: 0; left: 0; right: 0; background: #fff; padding: 20rpx 24rpx; padding-bottom: calc(20rpx + env(safe-area-inset-bottom)); display: flex; align-items: center; box-shadow: 0 -4rpx 16rpx rgba(0,0,0,0.06); }
.action-btn { display: flex; flex-direction: column; align-items: center; padding: 0 24rpx; color: #666; font-size: 22rpx; }
.action-btn text:first-child { font-size: 40rpx; margin-bottom: 4rpx; }
.join-btn { flex: 1; height: 88rpx; background: linear-gradient(135deg, #4A90E2, #357ABD); border-radius: 44rpx; display: flex; align-items: center; justify-content: center; margin-left: 20rpx; }
.join-btn text { font-size: 32rpx; color: #fff; font-weight: 500; }
.join-btn.disabled { background: #ccc; }
.member-popup { position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.5); z-index: 1000; display: flex; align-items: flex-end; }
.popup-content { background: #fff; width: 100%; border-radius: 32rpx 32rpx 0 0; max-height: 70vh; }
.popup-header { display: flex; align-items: center; justify-content: space-between; padding: 32rpx; border-bottom: 1rpx solid #F0F0F0; }
.popup-title { font-size: 32rpx; color: #333; font-weight: 500; }
.popup-close { font-size: 36rpx; color: #999; padding: 10rpx; }
.popup-body { padding: 0 32rpx 32rpx; max-height: 50vh; }
.popup-member { display: flex; align-items: center; padding: 24rpx 0; border-bottom: 1rpx solid #F5F5F5; }
.popup-avatar { width: 80rpx; height: 80rpx; border-radius: 50%; }
.popup-info { flex: 1; margin-left: 20rpx; }
.popup-name { display: block; font-size: 28rpx; color: #333; }
.popup-building { display: block; font-size: 24rpx; color: #999; margin-top: 6rpx; }
.popup-time { font-size: 24rpx; color: #999; }
.join-popup { position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.5); z-index: 1000; display: flex; align-items: flex-end; }
.join-content { padding-bottom: env(safe-area-inset-bottom); }
.join-form { padding: 32rpx; }
.form-item { display: flex; align-items: center; padding: 24rpx 0; border-bottom: 1rpx solid #F5F5F5; }
.form-label { width: 140rpx; font-size: 28rpx; color: #333; }
.form-input { flex: 1; font-size: 28rpx; color: #333; }
.number-box { display: flex; align-items: center; }
.num-btn { width: 60rpx; height: 60rpx; background: #F5F5F5; border-radius: 8rpx; display: flex; align-items: center; justify-content: center; font-size: 36rpx; color: #666; }
.num-value { width: 80rpx; text-align: center; font-size: 32rpx; color: #333; }
.submit-btn { height: 88rpx; background: linear-gradient(135deg, #4A90E2, #357ABD); border-radius: 44rpx; display: flex; align-items: center; justify-content: center; margin-top: 40rpx; }
.submit-btn text { font-size: 32rpx; color: #fff; font-weight: 500; }
</style>
