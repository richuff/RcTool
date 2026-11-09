# RcTool 文档中心

> **语言：** 简体中文 · [English](README.md)

欢迎来到 **RcTool** 的官方文档。RcTool 是一个基于 Flutter 的跨平台音乐播放器，并集成了 Live2D 角色互动能力，支持 Android / iOS / Windows / macOS / Linux / Web 多端运行。

本目录下的文档帮助你从零了解项目、快速上手开发，并深入掌握各模块的设计细节。

## 文档导航

| 文档 | 内容概要 | 适合人群 |
| --- | --- | --- |
| [01 - 开发入门](./01-getting-started.zh-CN.md) | 环境搭建、依赖安装、目录结构、运行与构建 | 新接手项目的开发者 |
| [02 - 整体架构](./02-architecture.zh-CN.md) | 分层设计、状态管理、路由、主题、国际化 | 需要理解全局结构的开发者 |
| [03 - 功能模块](./03-features.zh-CN.md) | 音乐播放、收藏、推荐、排行榜、Live2D 等模块说明 | 想知道"能做什么"的人 |
| [04 - 数据库设计](./04-database.zh-CN.md) | SQLite 表结构、实体类、数据访问层 | 涉及数据存储改动的开发者 |
| [05 - Live2D 集成](./05-live2d.zh-CN.md) | 模型资源、WebView 承载方案、平台适配 | 维护 Live2D 互动的开发者 |

## 文档语言

每份文档都有中英两个版本：无后缀的路径为英文（默认），在 `.md` 前加 `.zh-CN` 即中文版，例如 `03-features.md` 与 `03-features.zh-CN.md`。每页顶部都有指向另一语言的链接，页内链接也始终留在同一语言内。

## 技术栈速览

- **框架**：Flutter（SDK `^3.5.1`）
- **状态管理 & 路由**：GetX（`get ^4.6.1`）
- **音频播放**：`audioplayers`（配合 `flutter_cache_manager` 做缓存播放）
- **本地存储**：`sqflite` + `sqflite_common_ffi` / `sqflite_common_ffi_web`（桌面/Web 走 FFI）
- **本地通知 / 锁屏控制**：`flutter_local_notifications`
- **权限申请**：`permission_handler`
- **蓝牙耳机断连检测**：`headset_connection_event`
- **Live2D 渲染**：`webview_flutter` + `webview_windows`（基于 Web 的 Live2D）
- **配置持久化**：`shared_preferences`

## 项目目标

- 提供流畅的音乐播放与控制体验
- 支持播放列表管理与多种播放模式
- 集成 Live2D 角色互动（触摸、动画）
- 通过通知栏与锁屏控制实现系统集成
- 本地数据持久化（收藏、歌单、推荐历史）

> 更多背景可回到项目根目录的 [README](../README.zh-CN.md)。
