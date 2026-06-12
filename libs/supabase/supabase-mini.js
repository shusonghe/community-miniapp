/**
 * Supabase 小程序适配版 - 珈邻
 * 纯手机号注册登录
 */

// Supabase 项目配置
// 请在 Supabase 控制台 Settings -> API 中获取以下信息
const SUPABASE_URL = 'https://xxx.supabase.co'  // 替换为你的 Project URL
const SUPABASE_ANON_KEY = ''  // 替换为你的 anon public key

const TOKEN_KEY = 'jialing_auth_token'
const USER_KEY = 'jialing_user_info'

// 存储工具
function getStoredToken() {
  try {
    const data = uni.getStorageSync(TOKEN_KEY)
    return data ? JSON.parse(data) : null
  } catch (e) { return null }
}

function setStoredToken(token) {
  try { uni.setStorageSync(TOKEN_KEY, JSON.stringify(token)) } catch (e) {}
}

function clearStoredToken() {
  try { 
    uni.removeStorageSync(TOKEN_KEY)
    uni.removeStorageSync(USER_KEY)
  } catch (e) {}
}

function getStoredUser() {
  try {
    const data = uni.getStorageSync(USER_KEY)
    return data ? JSON.parse(data) : null
  } catch (e) { return null }
}

function setStoredUser(user) {
  try { uni.setStorageSync(USER_KEY, JSON.stringify(user)) } catch (e) {}
}

// 请求封装
function request(endpoint, options = {}) {
  return new Promise((resolve) => {
    const token = getStoredToken()
    // 检查是否是有效的 JWT（包含两个点号分隔的三部分）
    const isValidJWT = token?.access_token && token.access_token.split('.').length === 3
    const authToken = isValidJWT ? token.access_token : SUPABASE_ANON_KEY
    
    const headers = {
      'Content-Type': 'application/json',
      'apikey': SUPABASE_ANON_KEY,
      'Authorization': `Bearer ${authToken}`
    }
    if (options.headers) Object.assign(headers, options.headers)

    // console.log('[Supabase] Request:', options.method || 'GET', endpoint)

    uni.request({
      url: `${SUPABASE_URL}${endpoint}`,
      method: options.method || 'GET',
      header: headers,
      data: options.body,
      success: (res) => {
        // console.log('[Supabase] Response:', res.statusCode, res.data)
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve({ data: res.data, error: null })
        } else if (res.statusCode === 406) {
          // 406 表示没有找到记录（single 模式）
          resolve({ data: null, error: null })
        } else {
          const errorMsg = res.data?.message || res.data?.error || '请求失败'
          resolve({ data: null, error: { message: errorMsg, code: res.statusCode } })
        }
      },
      fail: (err) => {
        console.log('[Supabase] Error:', err)
        resolve({ data: null, error: { message: err.errMsg || '网络错误' } })
      }
    })
  })
}

// 认证模块
export const auth = {
  /**
   * 手机号注册
   */
  async signUp(phone, password, metadata = {}) {
    console.log('[Auth] signUp:', phone)
    
    // 检查手机号是否已注册
    const { data: users } = await db.select('users', {
      filter: { phone: { eq: phone } }
    })
    
    if (users && users.length > 0) {
      return { data: null, error: { message: '该手机号已注册' } }
    }

    // 插入新用户
    const { data, error } = await db.insert('users', {
      phone,
      password,
      nickname: metadata.nickname || '珈邻用户',
      building: metadata.building || '',
      user_type: metadata.user_type || 'owner',
      avatar_url: 'https://img.icons8.com/?size=100&id=s4mUhvTRUkP2&format=png&color=000000'
    })
    
    if (error) {
      console.log('[Auth] signUp error:', error)
      return { data: null, error }
    }
    
    // 自动登录
    const user = Array.isArray(data) ? data[0] : data
    if (user) {
      const tokenData = { access_token: 'local_' + user.id, user }
      setStoredToken(tokenData)
      setStoredUser(user)
    }
    
    return { data: user, error: null }
  },

  /**
   * 手机号登录
   */
  async signIn(phone, password) {
    console.log('[Auth] signIn:', phone)
    
    const { data: users, error } = await db.select('users', {
      filter: { phone: { eq: phone } }
    })
    
    if (error) {
      console.log('[Auth] signIn query error:', error)
      return { data: null, error }
    }
    
    if (!users || users.length === 0) {
      return { data: null, error: { message: '该手机号未注册' } }
    }
    
    const user = users[0]
    
    if (user.password !== password) {
      return { data: null, error: { message: '密码错误' } }
    }
    
    const tokenData = { access_token: 'local_' + user.id, user }
    setStoredToken(tokenData)
    setStoredUser(user)
    
    return { data: user, error: null }
  },

  /**
   * 退出登录
   */
  async signOut() {
    clearStoredToken()
    return { error: null }
  },

  /**
   * 获取本地用户信息
   */
  getLocalUser() {
    return getStoredUser()
  },

  /**
   * 检查是否已登录
   */
  isLoggedIn() {
    const token = getStoredToken()
    return !!token?.access_token
  },

  /**
   * 更新用户资料（通过RPC函数）
   */
  async updateProfile(profileData) {
    const user = getStoredUser()
    if (!user?.id) return { data: null, error: { message: '未登录' } }
    
    // 调用 RPC 函数更新用户资料
    const { data, error } = await db.rpc('update_user_profile', {
      p_user_id: user.id,
      p_nickname: profileData.nickname || null,
      p_gender: profileData.gender !== undefined ? profileData.gender : null,
      p_building: profileData.building || null,
      p_avatar_url: profileData.avatar_url || null
    })
    
    if (error) {
      return { data: null, error }
    }
    
    // RPC返回的是JSON对象
    if (data && !data.success) {
      return { data: null, error: { message: data.message } }
    }
    
    // 更新本地存储的用户信息
    if (data && data.user) {
      setStoredUser(data.user)
      return { data: data.user, error: null }
    }
    
    // 如果没有返回用户信息，手动更新本地存储
    const updatedUser = { ...user, ...profileData }
    setStoredUser(updatedUser)
    
    return { data: updatedUser, error: null }
  },

  /**
   * 修改密码（通过RPC函数）
   */
  async updatePassword(phone, newPassword) {
    const { data, error } = await db.rpc('reset_password', {
      p_phone: phone,
      p_new_password: newPassword
    })
    
    if (error) {
      return { data: null, error }
    }
    
    // RPC返回的是JSON对象
    if (data && !data.success) {
      return { data: null, error: { message: data.message } }
    }
    
    return { data, error: null }
  },

  /**
   * 微信一键登录
   * @param {string} code 微信登录凭证
   * @param {object} userInfo 用户信息（昵称、头像）
   */
  async wechatLogin(code, userInfo = {}) {
    console.log('[Auth] wechatLogin:', code)
    
    // 调用后端 RPC 函数处理微信登录
    const { data, error } = await db.rpc('wechat_login', {
      p_code: code,
      p_nickname: userInfo.nickname || '珈邻用户',
      p_avatar_url: userInfo.avatar_url || 'https://img.icons8.com/?size=100&id=s4mUhvTRUkP2&format=png&color=000000'
    })
    
    if (error) {
      console.log('[Auth] wechatLogin error:', error)
      return { data: null, error }
    }
    
    // RPC返回的是JSON对象
    if (data && !data.success) {
      return { data: null, error: { message: data.message || '登录失败' } }
    }
    
    // 保存登录状态
    const user = data.user
    if (user) {
      const tokenData = { access_token: 'wx_' + user.id, user }
      setStoredToken(tokenData)
      setStoredUser(user)
    }
    
    return { data: user, error: null }
  }
}

// 数据库模块
export const db = {
  async select(table, options = {}) {
    let endpoint = `/rest/v1/${table}`
    const params = []
    if (options.select) params.push(`select=${options.select}`)
    if (options.filter) {
      Object.entries(options.filter).forEach(([col, conditions]) => {
        Object.entries(conditions).forEach(([op, val]) => {
          params.push(`${col}=${op}.${val}`)
        })
      })
    }
    if (options.order) params.push(`order=${options.order}`)
    if (options.limit) params.push(`limit=${options.limit}`)
    if (params.length > 0) endpoint += '?' + params.join('&')
    
    // 不使用 single 模式，避免 406 错误，改为返回数组
    return await request(endpoint)
  },

  async insert(table, data) {
    return await request(`/rest/v1/${table}`, {
      method: 'POST', 
      body: data,
      headers: { 'Prefer': 'return=representation' }
    })
  },

  async update(table, data, filter) {
    let endpoint = `/rest/v1/${table}`
    const params = []
    Object.entries(filter).forEach(([col, conditions]) => {
      Object.entries(conditions).forEach(([op, val]) => params.push(`${col}=${op}.${val}`))
    })
    if (params.length > 0) endpoint += '?' + params.join('&')
    return await request(endpoint, {
      method: 'PATCH', 
      body: data,
      headers: { 'Prefer': 'return=representation' }
    })
  },

  async delete(table, filter) {
    let endpoint = `/rest/v1/${table}`
    const params = []
    Object.entries(filter).forEach(([col, conditions]) => {
      Object.entries(conditions).forEach(([op, val]) => params.push(`${col}=${op}.${val}`))
    })
    if (params.length > 0) endpoint += '?' + params.join('&')
    return await request(endpoint, { method: 'DELETE' })
  },

  async rpc(functionName, params = {}) {
    return await request(`/rest/v1/rpc/${functionName}`, {
      method: 'POST',
      body: params
    })
  }
}

// 存储模块
export const storage = {
  /**
   * 压缩图片 - 核心优化函数
   * 将图片压缩到指定大小以内，节省存储空间
   * @param {string} filePath 原图路径
   * @param {number} maxSize 最大文件大小(KB)，默认100KB
   * @param {number} quality 初始质量(0-100)，默认80
   * @returns {Promise<string>} 压缩后的图片路径
   */
  compressImage(filePath, maxSize = 100, quality = 80) {
    return new Promise((resolve) => {
      // 先获取图片信息
      uni.getImageInfo({
        src: filePath,
        success: (info) => {
          // 计算压缩后的尺寸，最大宽度800px
          let targetWidth = info.width
          let targetHeight = info.height
          const maxWidth = 800
          
          if (targetWidth > maxWidth) {
            targetHeight = Math.round(targetHeight * maxWidth / targetWidth)
            targetWidth = maxWidth
          }
          
          // 使用 canvas 压缩（兼容性更好）
          uni.compressImage({
            src: filePath,
            quality: quality,
            compressedWidth: targetWidth,
            compressedHeight: targetHeight,
            success: (res) => {
              console.log('[Storage] 图片压缩成功:', res.tempFilePath)
              resolve(res.tempFilePath)
            },
            fail: (err) => {
              console.log('[Storage] 压缩失败，使用原图:', err)
              resolve(filePath)
            }
          })
        },
        fail: () => {
          // 获取信息失败，直接压缩
          uni.compressImage({
            src: filePath,
            quality: quality,
            success: (res) => resolve(res.tempFilePath),
            fail: () => resolve(filePath)
          })
        }
      })
    })
  },

  /**
   * 上传头像到 Supabase Storage
   * 使用固定文件名，自动覆盖旧头像，节省存储空间
   * @param {number} userId 用户ID
   * @param {string} filePath 本地文件路径
   */
  async uploadAvatar(userId, filePath) {
    // 先压缩图片，头像压缩到50KB以内
    const compressedPath = await this.compressImage(filePath, 50, 70)
    
    // 固定文件名，覆盖旧头像（x-upsert: true）
    const fileName = `avatars/${userId}.jpg`
    
    return new Promise((resolve) => {
      uni.uploadFile({
        url: `${SUPABASE_URL}/storage/v1/object/${fileName}`,
        filePath: compressedPath,
        name: 'file',
        header: {
          'apikey': SUPABASE_ANON_KEY,
          'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
          'x-upsert': 'true'
        },
        success: (res) => {
          console.log('[Storage] Upload response:', res.statusCode, res.data)
          if (res.statusCode >= 200 && res.statusCode < 300) {
            // 添加时间戳防止缓存
            const publicUrl = `${SUPABASE_URL}/storage/v1/object/public/${fileName}?t=${Date.now()}`
            resolve({ url: publicUrl, error: null })
          } else {
            let errorMsg = '上传失败'
            try {
              const data = JSON.parse(res.data)
              errorMsg = data.message || data.error || errorMsg
            } catch (e) {}
            resolve({ url: null, error: { message: errorMsg } })
          }
        },
        fail: (err) => {
          console.log('[Storage] Upload error:', err)
          resolve({ url: null, error: { message: err.errMsg || '上传失败' } })
        }
      })
    })
  },

  /**
   * 获取公开访问URL
   */
  getPublicUrl(path) {
    return `${SUPABASE_URL}/storage/v1/object/public/${path}`
  },

  /**
   * 上传图片到指定 bucket（带压缩）
   * @param {string} bucket bucket名称（posts/secondhand/groups等）
   * @param {string} fileName 文件名
   * @param {string} filePath 本地文件路径
   * @param {boolean} compress 是否压缩，默认true
   */
  async uploadImage(bucket, fileName, filePath, compress = true) {
    // 压缩图片，目标100KB以内
    const finalPath = compress ? await this.compressImage(filePath, 100, 75) : filePath
    
    return new Promise((resolve) => {
      const fullPath = `${bucket}/${fileName}`
      uni.uploadFile({
        url: `${SUPABASE_URL}/storage/v1/object/${fullPath}`,
        filePath: finalPath,
        name: 'file',
        header: {
          'apikey': SUPABASE_ANON_KEY,
          'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
          'x-upsert': 'true'
        },
        success: (res) => {
          console.log('[Storage] Upload:', fullPath, res.statusCode)
          if (res.statusCode >= 200 && res.statusCode < 300) {
            const publicUrl = `${SUPABASE_URL}/storage/v1/object/public/${fullPath}`
            resolve({ url: publicUrl, error: null })
          } else {
            let errorMsg = '上传失败'
            try {
              const data = JSON.parse(res.data)
              errorMsg = data.message || data.error || errorMsg
            } catch (e) {}
            resolve({ url: null, error: { message: errorMsg } })
          }
        },
        fail: (err) => {
          console.log('[Storage] Upload error:', err)
          resolve({ url: null, error: { message: err.errMsg || '上传失败' } })
        }
      })
    })
  },

  /**
   * 删除 Storage 中的文件
   * Supabase Storage API: DELETE /storage/v1/object/{bucket_id}
   * Body: { "prefixes": ["filename1.jpg", "filename2.jpg"] }
   * @param {string} bucket bucket名称
   * @param {string[]} filePaths 文件路径数组（不含bucket前缀，只是文件名）
   */
  async deleteFiles(bucket, filePaths) {
    if (!filePaths || filePaths.length === 0) {
      return { data: null, error: null }
    }
    
    console.log('[Storage] deleteFiles - bucket:', bucket, 'files:', filePaths)
    
    return new Promise((resolve) => {
      // Supabase Storage 批量删除 API
      // DELETE /storage/v1/object/{bucket_id}
      // Body: { "prefixes": ["file1.jpg", "file2.jpg"] }
      uni.request({
        url: `${SUPABASE_URL}/storage/v1/object/${bucket}`,
        method: 'DELETE',
        header: {
          'Content-Type': 'application/json',
          'apikey': SUPABASE_ANON_KEY,
          'Authorization': `Bearer ${SUPABASE_ANON_KEY}`
        },
        data: { prefixes: filePaths },
        success: (res) => {
          console.log('[Storage] Delete result:', res.statusCode, JSON.stringify(res.data))
          if (res.statusCode >= 200 && res.statusCode < 300) {
            console.log('[Storage] Delete success!')
            resolve({ data: res.data, error: null })
          } else {
            console.log('[Storage] Delete failed:', res.statusCode, JSON.stringify(res.data))
            resolve({ data: null, error: { message: res.data?.message || res.data?.error || '删除失败' } })
          }
        },
        fail: (err) => {
          console.log('[Storage] Delete network error:', err)
          resolve({ data: null, error: { message: err.errMsg || '删除失败' } })
        }
      })
    })
  },

  /**
   * 从图片URL中提取文件路径
   * @param {string} imageUrl 完整的图片URL
   * @returns {string|null} 文件路径（不含bucket）
   */
  extractFilePath(imageUrl) {
    if (!imageUrl) return null
    // URL格式: https://xxx.supabase.co/storage/v1/object/public/bucket-name/path/to/file.jpg
    const match = imageUrl.match(/\/storage\/v1\/object\/public\/[^/]+\/(.+?)(?:\?|$)/)
    return match ? match[1] : null
  },

  /**
   * 从图片URL数组中提取bucket和文件路径
   * @param {string[]} imageUrls 图片URL数组
   * @returns {{ bucket: string, paths: string[] }|null}
   */
  extractBucketAndPaths(imageUrls) {
    if (!imageUrls || imageUrls.length === 0) return null
    
    const paths = []
    let bucket = null
    
    for (const url of imageUrls) {
      if (!url) continue
      // 提取 bucket 和 path
      const match = url.match(/\/storage\/v1\/object\/public\/([^/]+)\/(.+?)(?:\?|$)/)
      if (match) {
        if (!bucket) bucket = match[1]
        paths.push(match[2])
      }
    }
    
    return bucket && paths.length > 0 ? { bucket, paths } : null
  },

  /**
   * 删除图片数组中的所有文件
   * @param {string[]} imageUrls 图片URL数组
   */
  async deleteImages(imageUrls) {
    const info = this.extractBucketAndPaths(imageUrls)
    if (!info) {
      console.log('[Storage] No images to delete')
      return { data: null, error: null }
    }
    
    console.log('[Storage] Deleting images from bucket:', info.bucket, 'paths:', info.paths)
    return await this.deleteFiles(info.bucket, info.paths)
  }
}

// 便捷上传函数
export async function uploadFile(filePath, bucket, fileName) {
  const { url, error } = await storage.uploadImage(bucket, fileName, filePath)
  if (error) {
    console.error('上传失败:', error)
    return null
  }
  return url
}

// 创建 supabase 兼容对象
export const supabase = {
  rpc: (name, params) => db.rpc(name, params),
  from: (table) => ({
    select: (cols) => db.select(table, { select: cols }),
    insert: (data) => db.insert(table, data),
    update: (data) => ({ eq: (col, val) => db.update(table, data, { [col]: { eq: val } }) }),
    delete: () => ({ eq: (col, val) => db.delete(table, { [col]: { eq: val } }) })
  })
}

export default { auth, db, storage }
