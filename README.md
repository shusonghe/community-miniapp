# 🏘️ 珈誉邻里 — 小区社区服务小程序

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![uni-app](https://img.shields.io/badge/uni--app-2.x-green.svg)](https://uniapp.dcloud.io/)
[![Vue](https://img.shields.io/badge/vue-2.x-brightgreen.svg)](https://vuejs.org/)
[![Supabase](https://img.shields.io/badge/Supabase-BaaS-3ECF8E.svg)](https://supabase.com/)

基于 **uni-app (Vue 2) + 图鸟 UI + Supabase** 构建的微信小程序，为小区居民提供社区公告、邻里动态、二手闲置交易、组团出行等一站式社区服务。

已稳定服务 **10,000+** 用户，适合作为微信小程序全栈开发的**生产级参考项目**。

---

## 📸 预览

| 首页 | 社区动态 | 二手闲置 |
|------|---------|----------|
| ![首页](static/screenshots/home.png) | ![社区动态](static/screenshots/community.png) | ![二手闲置](static/screenshots/secondhand.png) |

| 组团 | 公告 | 个人中心 |
|------|------|----------|
| ![组团](static/screenshots/group.png) | ![公告](static/screenshots/notice.png) | ![个人中心](static/screenshots/profile.png) |

> 💡 截图占位，请用微信开发者工具或真机截图替换 `static/screenshots/` 目录下的图片。详见 [截图说明](static/screenshots/README.md)。

---

## 📱 功能模块

| 模块 | 功能描述 |
|------|----------|
| 🏠 **首页** | 小区概览，快捷入口聚合 |
| 📰 **社区动态** | 发布/浏览邻里动态，支持点赞、评论、图片上传 |
| 🔄 **二手闲置** | 闲置物品发布、分类浏览、收藏、状态管理 |
| 🚌 **组团出行** | 发起组团、参加/退出、周边活动发现、旅游拼团 |
| 📢 **公告通知** | 小区公告发布与查看，支持富文本详情 |
| 👤 **用户系统** | 手机号注册/登录、微信一键登录、密码重置 |
| ⚙️ **个人中心** | 资料编辑、我的动态/闲置/组团管理 |

### 🎯 特色设计

- **Tabbar 动态配置** — 通过 Supabase 远程控制底部导航栏的显示/隐藏，方便微信审核期间临时隐藏 UGC 模块
- **图片智能压缩** — 上传前自动压缩（头像 ≤50KB，内容图 ≤100KB），节省存储成本
- **RLS 安全策略** — 数据库行级安全，所有数据操作通过 RPC 函数，防止越权访问
- **Storage 联动清理** — 删除内容时自动清理关联的图片文件，避免存储垃圾
- **微信更新检测** — 启动时自动检测新版本并提示用户重启更新

---

## 🛠️ 技术栈

```
前端框架：    uni-app (Vue 2)
UI 组件库：   图鸟 UI (TuniaoUI)
状态管理：    Vuex
后端服务：    Supabase (BaaS)
  - 数据库：  PostgreSQL (REST API + RPC)
  - 存储：    Supabase Storage
  - 认证：    自建手机号 + 微信 OAuth
样式预处理：  SCSS
目标平台：    微信小程序 (mp-weixin)
```

### 项目架构

```
community-miniapp/
├── pages/                    # 页面
│   ├── index/                # 首页
│   ├── community/            # 社区动态（发布/列表）
│   ├── secondhand/           # 二手闲置（发布/列表/详情）
│   ├── group/                # 组团（列表/详情/发布/周边/旅游）
│   ├── notice/               # 公告（列表/详情）
│   ├── login/                # 登录/注册/重置密码/协议
│   ├── profile/              # 个人中心（资料/我的动态/闲置/组团）
│   ├── splash/               # 启动页
│   └── merchant/             # 商家模块（预留）
├── components/               # 公共组件
├── libs/
│   ├── supabase/             # Supabase 小程序适配层
│   │   ├── supabase-mini.js  # 核心 SDK（auth/db/storage）
│   │   ├── *.sql             # 数据库建表 & RPC 函数
│   │   └── README.md         # 数据库配置文档
│   └── mixin/                # 全局混入
├── store/                    # Vuex 状态管理
├── tuniao-ui/                # 图鸟 UI 组件库
├── static/                   # 静态资源
├── App.vue                   # 应用入口
├── main.js                   # 主入口
├── pages.json                # 页面路由 & 全局配置
├── manifest.json             # 应用配置
└── uni.scss                  # 全局 SCSS 变量
```

---

## 🚀 快速开始

### 前置要求

- [HBuilderX](https://www.dcloud.io/hbuilderx.html) 或 Node.js 16+
- [Supabase](https://supabase.com/) 账号（免费套餐即可）
- [微信开发者工具](https://developers.weixin.qq.com/miniprogram/dev/devtools/download.html)
- 微信小程序 AppID（[注册小程序](https://mp.weixin.qq.com/)）

### 1. 克隆项目

```bash
git clone https://github.com/shusonghe/community-miniapp.git
cd community-miniapp
```

### 2. 配置 Supabase

1. 在 [Supabase 控制台](https://app.supabase.com/) 创建项目
2. 进入 Settings → API，复制 `Project URL` 和 `anon public key`
3. 打开 `libs/supabase/supabase-mini.js`，替换配置：

```javascript
const SUPABASE_URL = 'https://your-project.supabase.co'  // 你的 Project URL
const SUPABASE_ANON_KEY = 'your-anon-key'                  // 你的 anon key
```

4. 在 Supabase SQL Editor 中，按顺序执行 `libs/supabase/` 下的 SQL 文件（详见 [`libs/supabase/README.md`](libs/supabase/README.md)）

### 3. 配置微信小程序

1. 打开 `manifest.json`，将 `mp-weixin.appid` 改为你的小程序 AppID
2. 在微信公众平台 → 开发管理 → 服务器域名中添加：
   - `request` 合法域名：`https://your-project.supabase.co`
   - `uploadFile` 合法域名：`https://your-project.supabase.co`
   - `downloadFile` 合法域名：`https://your-project.supabase.co`

### 4. 运行项目

**方式一：HBuilderX（推荐）**

1. 用 HBuilderX 打开项目
2. 点击 运行 → 运行到小程序模拟器 → 微信开发者工具

**方式二：CLI**

```bash
npm install
npm run dev:mp-weixin
```

然后在微信开发者工具中导入 `dist/dev/mp-weixin` 目录。

---

## 📦 Supabase 数据库配置

项目使用 Supabase 作为后端，数据库表结构、RPC 函数、RLS 策略的详细文档：

👉 **[数据库配置文档](libs/supabase/README.md)**

### 数据表总览

| 模块 | 表名 | 说明 |
|------|------|------|
| 用户 | `users` | 手机号、密码、昵称、头像、微信 openid |
| 社区 | `posts` / `post_likes` / `post_comments` | 动态、点赞、评论 |
| 闲置 | `secondhand_items` / `secondhand_favorites` | 闲置商品、收藏 |
| 组团 | `groups` / `group_members` | 组团活动、参团成员 |
| 系统 | `tabbar_config` / `notices` / `agreement_config` | 导航配置、公告、协议 |

---

## 🧩 核心依赖

| 依赖 | 版本 | 说明 |
|------|------|------|
| uni-app | 2.x | 跨平台前端框架 |
| Vue | 2.x | 渐进式框架 |
| Vuex | 3.x | 状态管理 |
| 图鸟 UI (TuniaoUI) | - | 小程序 UI 组件库 |
| Supabase | - | 开源 BaaS 平台 |

---

## ⭐ Star History

[![Star History Chart](https://api.star-history.com/svg?repos=shusonghe/community-miniapp&type=Date)](https://star-history.com/#shusonghe/community-miniapp&Date)

---

## 📄 License

MIT © [shusonghe](https://github.com/shusonghe)

---

## 🙏 致谢

- [uni-app](https://uniapp.dcloud.io/) — 跨平台开发框架
- [图鸟 UI](https://tuniaoui.dcloud.net.cn/) — 优质小程序组件库
- [Supabase](https://supabase.com/) — 开源 Firebase 替代方案

---

## ⚠️ 注意事项

- 本项目中的 `manifest.json` 已包含示例微信 AppID，使用前请替换为你自己的 AppID
- `libs/supabase/supabase-mini.js` 中的 Supabase 连接信息为占位符，请替换为你的实际配置
- **永远不要**将 Supabase 的 `service_role key` 提交到代码仓库
- 本项目采用自建手机号认证方案（密码存储为明文），生产环境建议启用 Supabase Auth 或对密码进行哈希处理
- Tabbar 动态审核模式适用于微信小程序 UGC 内容审核场景，可根据实际需求调整
