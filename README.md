# rctool

![Static Badge](https://img.shields.io/badge/flutter-3.24.1-blue)
![GitHub commit activity](https://img.shields.io/github/commit-activity/w/richuff/RcAdmin)

一个基于 **Flutter** 和 **Get** 的音乐播放器及 Live2D 项目。

## 项目介绍

rctool 是一个跨平台的音乐播放器应用，支持 Android端 设备
项目结合了 Flutter 的高性能 UI 渲染能力和 Get 的状态管理功能，同时集成了 Live2D 技术，为用户提供更多互动体验。

项目的主要目标是：
- 提供流畅的音乐播放体验
- 支持本地音乐库管理和播放
- 集成 Live2D 角色互动功能
- 提供通知和锁屏控制

## 功能特点

### 音乐播放功能
- 流畅的音乐播放和暂停控制
- 支持播放列表管理和切换
- 音乐搜索和分类浏览
- 锁屏控制和通知显示
- 歌词同步显示

### Live2D 互动
- 集成 Live2D 角色显示
- 角色动画随音乐节奏变化
- 触摸交互触发角色动作
- 多角色切换功能

### 数据管理
- 本地音乐库扫描和管理
- 播放历史记录
- 收藏功能
- 数据持久化存储

### 系统集成
- 通知中心集成
- 蓝牙耳机断连检测
- 权限管理（存储、通知等）

## 技术栈

### 核心框架
- **Flutter**：用于跨平台 UI 开发
- **Get**：用于状态管理和路由导航

### 依赖库
- **audioplayers**: 音频播放功能
- **flutter_cache_manager**: 缓存管理
- **flutter_local_notifications**: 本地通知
- **permission_handler**: 权限管理
- **sqflite**: 本地数据库存储
- **path**: 文件路径处理
- **headset_connection_event**: 蓝牙耳机断连检测
- **fluttertoast**: 提示信息显示
- **cupertino_icons**: iOS 风格图标库

### 开发工具
- **Flutter SDK**: Flutter 开发环境
- **flutter_lints**: 代码规范检查

## Getting Started

### 安装 Flutter

1. 访问 [Flutter 官方网站](https://docs.flutter.dev/) 下载并安装 Flutter SDK。
2. 配置环境变量，确保 `flutter` 命令可以在终端中使用。
3. 运行 `flutter doctor` 检查安装状态并解决可能的依赖问题。

### 克隆项目

```bash
git clone https://github.com/richuff/RcTool.git
cd rctool
```

### 运行项目

1. 确保已连接设备或启动模拟器。
2. 运行以下命令启动应用：

```bash
flutter run
```

### 依赖管理

项目使用 `pubspec.yaml` 文件管理依赖项。添加或更新依赖后，运行以下命令：

```bash
flutter pub get
```

## 资源链接

- [Flutter 官方文档](https://docs.flutter.dev/)
- [Get 官方文档](https://pub.dev/packages/get)

## 贡献指南

欢迎贡献代码！请遵循以下步骤：

1. Fork 项目到你的仓库。
2. 创建一个新的分支：`git checkout -b feature/your-feature`
3. 提交你的更改：`git commit -m "Add some feature"`
4. 推送分支到远程仓库：`git push origin feature/your-feature`
5. 提交 Pull Request

## 许可证

本项目采用 MIT 许可证，详情请参阅 [LICENSE](LICENSE) 文件。
