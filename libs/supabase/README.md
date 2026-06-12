# 珈邻小程序 - Supabase 数据库配置

## SQL 执行顺序

**重要：请严格按照以下顺序在 Supabase SQL Editor 中执行 SQL 文件。**

### 核心表结构（必须按顺序执行）

| 序号 | 文件 | 功能 | 依赖 |
|:----:|------|------|------|
| 1 | `01-users-table.sql` | 用户表 | 无 |
| 2 | `02-users-rpc.sql` | 用户RPC函数 | 01 |
| 3 | `03-users-avatars.sql` | 头像存储Bucket | 01 |
| 4 | `04-posts-table.sql` | 动态表、点赞、评论 | 01 |
| 5 | `05-secondhand-table.sql` | 闲置商品表、收藏表 | 01 |
| 6 | `06-my-content-rpc.sql` | 我的内容管理RPC | 04, 05 |
| 7 | `07-groups-table.sql` | 组团表、参团表 | 01 |
| 8 | `08-wechat-login.sql` | 微信一键登录 | 01 |
| 9 | `09-tabbar-config.sql` | Tabbar动态配置 | 无 |
| 10 | `10-notices-table.sql` | 公告表 | 09 |
| 11 | `11-fix-rls-policies.sql` | RLS策略收紧 | 04, 05, 07 |
| 12 | `12-agreement-config.sql` | 用户协议与隐私政策 | 无 |
| 13 | `12-delete-with-storage.sql` | Storage删除权限 | 03, 04, 05, 07 |

### 可选/补丁文件（按需执行）

| 文件 | 功能 | 说明 |
|------|------|------|
| `07-groups-sort-fix.sql` | 组团排序修复 | 修复热门活动排序，进行中的排前面 |
| `07-groups-category-update.sql` | 组团分类更新 | 如需更新组团分类 |
| `07-groups-phone-update.sql` | 组团联系方式更新 | 如需更新联系方式字段 |
| `07-groups-drop-all.sql` | 删除组团相关表 | ⚠️ 危险操作，会删除所有组团数据 |
| `12-agreement-config-update.sql` | 协议内容更新 | 更新为珈誉府版本协议内容 |

---

## 数据库表结构概览

### 用户模块
- `users` - 用户表（手机号、密码、昵称、头像、openid等）

### 社区模块
- `posts` - 动态表
- `post_likes` - 动态点赞表
- `post_comments` - 动态评论表

### 闲置模块
- `secondhand_items` - 闲置商品表
- `secondhand_favorites` - 闲置收藏表

### 组团模块
- `groups` - 组团表
- `group_members` - 参团成员表

### 系统配置
- `tabbar_config` - 底部导航配置表
- `notices` - 公告表
- `agreement_config` - 协议配置表

### Storage Buckets
- `avatars` - 用户头像
- `posts` - 动态图片
- `secondhand` - 闲置商品图片
- `groups` - 组团图片

---

## RPC 函数列表

### 用户相关
| 函数名 | 功能 |
|--------|------|
| `reset_password(phone, new_password)` | 重置密码 |
| `update_user_profile(user_id, nickname, gender, building, avatar_url)` | 更新用户资料 |
| `wechat_login(code, nickname, avatar_url)` | 微信一键登录 |

### 动态相关
| 函数名 | 功能 |
|--------|------|
| `create_post(user_id, content, images, location, topic)` | 发布动态 |
| `get_posts(user_id, limit, offset, keyword, order_by)` | 获取动态列表 |
| `toggle_like(post_id, user_id)` | 点赞/取消点赞 |
| `add_comment(post_id, user_id, content, parent_id)` | 添加评论 |
| `get_comments(post_id, limit)` | 获取评论列表 |
| `get_my_posts(user_id, limit, offset)` | 获取我的动态 |
| `delete_post(post_id, user_id)` | 删除动态（软删除） |
| `hard_delete_post(post_id, user_id)` | 删除动态（硬删除） |

### 闲置相关
| 函数名 | 功能 |
|--------|------|
| `create_secondhand_item(...)` | 发布闲置 |
| `get_secondhand_items(user_id, category, keyword, limit, offset)` | 获取闲置列表 |
| `get_secondhand_detail(item_id, user_id)` | 获取闲置详情 |
| `toggle_favorite(item_id, user_id)` | 收藏/取消收藏 |
| `get_my_secondhand(user_id, limit, offset)` | 获取我的闲置 |
| `delete_secondhand(item_id, user_id)` | 删除闲置（软删除） |
| `update_secondhand_status(item_id, user_id, status)` | 更新闲置状态 |
| `hard_delete_secondhand(item_id, user_id)` | 删除闲置（硬删除） |

### 组团相关
| 函数名 | 功能 |
|--------|------|
| `create_group(...)` | 发起组团 |
| `get_groups(user_id, limit, offset)` | 获取组团列表 |
| `get_group_detail(group_id, user_id)` | 获取组团详情 |
| `join_group(group_id, user_id, quantity, remark)` | 参加组团 |
| `leave_group(group_id, user_id)` | 退出组团 |
| `get_group_members(group_id)` | 获取参团成员 |
| `get_my_groups(user_id, limit, offset)` | 获取我的组团 |
| `delete_group(group_id, user_id)` | 删除组团（软删除） |
| `update_group_status(group_id, user_id, status)` | 更新组团状态 |
| `hard_delete_group(group_id, user_id)` | 删除组团（硬删除） |

### 系统配置
| 函数名 | 功能 |
|--------|------|
| `get_tabbar_config()` | 获取可见的Tabbar配置 |
| `get_agreement_config(type)` | 获取协议配置（user/privacy） |

---

## Tabbar 动态配置

通过 `tabbar_config` 表控制底部导航栏的显示/隐藏，用于审核期间临时隐藏功能。

### 表结构

| 字段 | 类型 | 说明 |
|------|------|------|
| `tab_key` | VARCHAR | 唯一标识 (home/secondhand/community/group/profile/notice) |
| `tab_name` | VARCHAR | 显示名称 |
| `icon` | VARCHAR | 默认图标 |
| `selected_icon` | VARCHAR | 选中图标 |
| `path` | VARCHAR | 页面路径 |
| `sort_order` | INT | 排序顺序 |
| `is_visible` | BOOLEAN | **是否显示** |
| `is_center` | BOOLEAN | 是否中间凸起样式 |

### 常用操作

```sql
-- 审核期间隐藏社区、组团、闲置
UPDATE tabbar_config SET is_visible = false WHERE tab_key IN ('community', 'group', 'secondhand');

-- 审核通过后恢复显示
UPDATE tabbar_config SET is_visible = true WHERE tab_key IN ('community', 'group', 'secondhand');

-- 只显示首页、公告、我的（审核模式）
UPDATE tabbar_config SET is_visible = false;
UPDATE tabbar_config SET is_visible = true WHERE tab_key IN ('home', 'notice', 'profile');

-- 修改显示名称
UPDATE tabbar_config SET tab_name = '发现' WHERE tab_key = 'community';

-- 查看当前配置
SELECT tab_key, tab_name, is_visible, sort_order FROM tabbar_config ORDER BY sort_order;
```

---

## Storage 图片管理

### 删除流程

用户删除记录时，前端会自动清理 Storage 中的图片：

```
用户点击删除 → 前端删除Storage图片 → 前端调用RPC删除数据库记录
```

### 前端代码示例

```javascript
// 删除动态
async deletePost(item, index) {
  // 1. 先删除 Storage 中的图片
  if (item.images && item.images.length > 0) {
    await storage.deleteImages(item.images)
  }
  
  // 2. 再删除数据库记录
  await supabase.rpc('delete_post', {
    p_post_id: item.id,
    p_user_id: user.id
  })
}
```

### 相关文件

| 文件 | 功能 |
|------|------|
| `supabase-mini.js` | 新增 `storage.deleteImages()` 方法 |
| `pages/profile/my-posts.vue` | 删除动态时清理图片 |
| `pages/profile/my-goods.vue` | 删除闲置时清理图片 |
| `pages/profile/my-groups.vue` | 删除组团时清理图片 |
| `pages/group/detail.vue` | 删除组团时清理图片 |

---

## 小程序后台域名配置

在微信公众平台 → 开发管理 → 开发设置 → 服务器域名 中添加：

- request合法域名: `https://xxx.supabase.co`
- uploadFile合法域名: `https://xxx.supabase.co`
- downloadFile合法域名: `https://xxx.supabase.co`

---

## 常见问题

### 1. 图片无法删除
执行 `12-delete-with-storage.sql` 添加 Storage 删除权限策略。

### 2. RPC 函数权限不足
检查函数是否已授权给 `anon` 和 `authenticated` 角色。

### 3. 表操作被拒绝
执行 `11-fix-rls-policies.sql` 后，部分表操作被禁止，必须通过 RPC 函数操作。

### 4. Tabbar 隐藏后审核仍能看到页面
Tabbar 配置只控制导航栏显示，页面本身仍可通过 URL 直接访问。如需完全隐藏，需要在 `pages.json` 中移除页面配置。
