<script>
  import Vue from 'vue'
  import store from './store/index.js'
  import updateCustomBarInfo from './tuniao-ui/libs/function/updateCustomBarInfo.js'
  
	export default {
		onLaunch: function() {
			uni.getSystemInfo({
			  success: function(e) {
			    // #ifndef H5
			    // 获取手机系统版本
			    const system = e.system.toLowerCase()
			    const platform = e.platform.toLowerCase()
			    // 判断是否为ios设备
			    if (platform.indexOf('ios') != -1 && (system.indexOf('ios') != -1 || system.indexOf('macos') != -1)) {
			      Vue.prototype.SystemPlatform = 'apple'
			    } else if (platform.indexOf('android') != -1 && (system.indexOf('android') != -1)) {
			      Vue.prototype.SystemPlatform = 'android'
			    } else {
			      Vue.prototype.SystemPlatform = 'devtools'
			    }
			    // #endif
			  }
			})
      
      // 获取设备的状态栏信息和自定义顶栏信息
      // store.dispatch('updateCustomBarInfo')
      updateCustomBarInfo().then((res) => {
        store.commit('$tStore', {
          name: 'vuex_status_bar_height',
          value: res.statusBarHeight
        })
        store.commit('$tStore', {
          name: 'vuex_custom_bar_height',
          value: res.customBarHeight
        })
      })
			
			// #ifdef MP-WEIXIN
			// 微信小程序更新检测
			if (wx.canIUse('getUpdateManager')) {
			  const updateManager = wx.getUpdateManager()
			  
			  // 检查是否有新版本
			  updateManager.onCheckForUpdate((res) => {
			    console.log('检查更新结果:', res.hasUpdate)
			  })
			  
			  // 新版本下载完成
			  updateManager.onUpdateReady(() => {
			    uni.showModal({
			      title: '更新提示',
			      content: '新版本已经准备好，是否重启应用？',
			      success: (res) => {
			        if (res.confirm) {
			          updateManager.applyUpdate()
			        }
			      }
			    })
			  })
			  
			  // 新版本下载失败
			  updateManager.onUpdateFailed(() => {
			    uni.showModal({
			      title: '更新提示',
			      content: '新版本下载失败，请删除小程序后重新搜索打开',
			      showCancel: false
			    })
			  })
			}
			// #endif
		},
		onShow: function() {
			// console.log('App Show')
		},
		onHide: function() {
			// console.log('App Hide')
		}
	}
</script>

<style lang="scss">
  /* 注意要写在第一行，同时给style标签加入lang="scss"属性 */
  @import './tuniao-ui/index.scss';
  @import './tuniao-ui/iconfont.css';
  @import './tuniao-ui/TnDouble.css';
  /* 全局背景颜色 - 渐变蓝色 */
  page {
      background: linear-gradient(180deg, #E8F4FD 0%, #D6EBFA 50%, #C4E2F7 100%);
      min-height: 100vh;
  }
</style>
