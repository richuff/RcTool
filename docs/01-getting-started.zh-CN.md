# 01 - 开发入门

> **语言：** 简体中文 · [English](01-getting-started.md)

本文档帮助你在本地把 RcTool 跑起来，并熟悉项目布局。

## 1. 环境要求

| 工具 | 版本建议 | 说明 |
| --- | --- | --- |
| Flutter SDK | `^3.5.1`（README 标注 3.24.x 经验证可用） | 跨平台编译基础 |
| Dart SDK | 随 Flutter 自带 | — |
| 开发机 | Windows / macOS / Linux | 桌面端需要对应编译工具链 |
| 设备 / 模拟器 | Android / iOS / 桌面 | 运行与调试目标 |

> 安装完 Flutter 后，请先执行 `flutter doctor` 确认环境无缺项（尤其是 Android SDK / Xcode / Visual Studio 等平台依赖）。

## 2. 获取代码

```bash
git clone https://github.com/richuff/RcTool.git
cd rctool
```

## 3. 安装依赖

```bash
flutter pub get
```

依赖清单见根目录 [`pubspec.yaml`](../pubspec.yaml)（核心库：`get`、`audioplayers`、`sqflite` 系列、`flutter_local_notifications`、`webview_flutter` / `webview_windows` 等）。

## 4. 运行项目

```bash
# 连接设备 / 启动模拟器后
flutter run
```

指定平台运行示例：

```bash
flutter run -d android
flutter run -d windows
flutter run -d web
```

## 5. 构建产物

```bash
# Android APK / AppBundle
flutter build apk
flutter build appbundle

# iOS（需 macOS + Xcode）
flutter build ios

# 桌面
flutter build windows
flutter build macos
flutter build linux

# Web
flutter build web
```

## 6. 目录结构

```
rctool/
├── lib/                      # 应用源码（Dart）
│   ├── main.dart             # 入口：GetMaterialApp、主题、权限、竖屏锁定
│   ├── routers/              # 路由表（RoutePath 常量 + GetPage 列表）
│   ├── controller/           # GetX 控制器（music / favorite / is_dark）
│   ├── repository/           # 数据层：entity 实体 + SqlLiteConn 数据库访问
│   ├── views/                # 业务视图（音乐播放器、设置）
│   ├── page/                 # 页面（音乐、推荐、排行榜、专辑、关于、Live2D）
│   ├── widget/               # 通用组件（抽屉、搜索、背景、Live2D、对话框）
│   ├── components/           # 业务组件（歌曲列表、推荐卡片等）
│   ├── feature/              # 主题、设计资产（调色板、图标按钮）
│   ├── iconfont/             # 字体图标封装
│   ├── constant/             # 常量（表名等）
│   └── utils/                # 工具（通知、权限、国际化、通用方法）
├── assets/                   # 静态资源（live2d 模型与 viewer、JSON 配置）
├── image/                    # 背景图、图标、插画
├── fonts/                    # 自定义字体（iconfont.ttf）
├── android/ ios/ macos/ windows/ linux/ web/   # 各平台工程
└── pubspec.yaml              # 依赖与资源声明
```

> 本仓库的 `android/`、`web/`、`windows/`、`macos/` 等平台工程已被 `.gitignore` 忽略，如本地缺失可用 `flutter create .` 重新生成。

## 7. 常见问题

- **首次启动白屏 / 黑屏**：确认 `assets/live2d/viewer/` 与 `assets/live2d/models/` 已随 `pubspec.yaml` 正确声明并打包。
- **桌面端数据库异常**：项目已通过 `sqflite_common_ffi` 在桌面端初始化 FFI，若仍报错请确认目标平台为 Windows / macOS / Linux 之一。
- **通知不显示**：Android 需授予通知权限（`permission_handler` 已在启动期申请）；锁屏控制通道已随 `NotificationHelper.initialize()` 创建。
- **权限被拒**：`headset_connection_event`、`permission_handler` 等需要在各平台工程的 `Info.plist` / `AndroidManifest.xml` 中声明对应权限。

下一篇：[02 - 整体架构](./02-architecture.zh-CN.md)
