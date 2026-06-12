/**
 * 登录权限检查 mixin
 * 未登录时，显示登录弹框
 */
import { auth } from '@/libs/supabase'

export default {
  methods: {
    // 检查登录状态，未登录则显示弹框
    checkLoginAndGo(url) {
      if (!auth.isLoggedIn()) {
        this.showLoginModal()
        return false
      }
      uni.navigateTo({ url })
      return true
    },
    // 检查登录状态（用于需要登录才能执行的操作）
    requireLogin(callback) {
      if (!auth.isLoggedIn()) {
        this.showLoginModal()
        return false
      }
      if (callback) callback()
      return true
    },
    // 显示登录弹框
    showLoginModal() {
      if (this.$refs.loginModal) {
        this.$refs.loginModal.show()
      }
    },
    // 获取当前登录状态
    getLoginStatus() {
      return auth.isLoggedIn()
    },
    // 获取当前用户信息
    getCurrentUser() {
      return auth.getLocalUser()
    }
  }
}
