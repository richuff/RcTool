# 02 - 整体架构

本文档梳理 RcTool 的分层结构、状态管理、路由、主题与国际化设计。

## 1. 分层概览

RcTool 采用"页面 / 视图 → 控制器 → 数据层"的轻量级分层，由 GetX 串联：

```
┌─────────────────────────────────────────────┐
│  页面 / 视图 (page, views, widget, components) │  ← UI 层
└───────────────┬─────────────────────────────┘
                │ GetBuilder / .obs 响应式绑定
┌───────────────▼─────────────────────────────┐
│           控制器 (controller)                 │  ← 状态管理层 (GetxController)
│   MusicController / FavoriteController /      │
│   IsDarkController                            │
└───────────────┬─────────────────────────────┘
                │ 调用
┌───────────────▼─────────────────────────────┐
│           数据层 (repository)                 │  ← 持久化层
│   entity/* 实体 + SqlLiteConn/* 数据访问        │
└───────────────┬─────────────────────────────┘
                │ 调用
┌───────────────▼─────────────────────────────┐
│   底层依赖：sqflite / audioplayers /           │
│   flutter_local_notifications / shared_prefs  │
└─────────────────────────────────────────────┘
```

## 2. 入口与启动流程

`lib/main.dart` 中的启动顺序：

1. `WidgetsFlutterBinding.ensureInitialized()` —— 初始化 Flutter 绑定。
2. `NotificationHelper().initialize()` —— 创建 Android 通知通道（新歌发布、播放控制）。
3. `runApp(const MyApp())` —— 进入应用。

`MyApp` 在 `initState` 中完成：

- 启动淡入动画（`AnimationController` + `FadeTransition`）。
- 读取 `SharedPreferences` 配置（语言、播放标记），据此设置 `appLocale`。
- 调用 `PermissionRequest.requestNotificationPermission()` 申请通知权限。
- 通过 `SystemChrome.setPreferredOrientations` 锁定为竖屏。

`MyApp` 使用 `GetBuilder<IsDarkController>` 包裹 `GetMaterialApp`，实现亮 / 暗主题的实时切换；`themeMode` 由 `IsDarkController` 持有。

## 3. 状态管理（GetX）

项目遵循 GetX 模式：

- **响应式状态**：控制器继承 `GetxController`，可变状态用 `.obs`（如 `isplay`、`position`、`playMode`）。
- **视图刷新**：UI 通过 `GetBuilder<Controller>` 或 `Obx` 订阅并自动重绘。
- **依赖注入**：`Get.put(IsDarkController(), permanent: true)` 注册为常驻单例。

主要控制器：

| 控制器 | 职责 |
| --- | --- |
| `MusicController` | 播放列表、播放 / 暂停、上一首 / 下一首、播放模式（循环 / 单曲 / 随机）、进度、缓存播放、通知联动 |
| `FavoriteController` | 收藏歌曲与收藏歌单的增删查、内存索引缓存 |
| `IsDarkController` | 亮 / 暗主题模式管理 |

## 4. 路由

路由集中在 `lib/routers/`，其中 `route_path.dart` 定义路径常量，`Index.dart` 定义 `GetPage` 列表（统一 `Transition.rightToLeft` 右滑进入）。

| 常量 | 路径 | 页面 |
| --- | --- | --- |
| `HOME` | `/` | 首页（欢迎卡片 + 快速开始 + 音乐库入口） |
| `MUSIC` | `/music` | 音乐列表页 |
| `MUSICCHOOSE` | `/musicchoose` | 播放队列（含播放模式图标、清空队列） |
| `RECOMMEND` | `/recommend` | 每日推荐 |
| `RANKING` | `/ranking` | 排行榜 |
| `ALBUM` | `/album` | 歌单列表页 |
| `PLAYLIST` | `/playlist` | 歌单详情页（`arguments` 传 `Playlist`；`id = -1` 表示「我的喜欢」） |
| `HISTORY` | `/history` | 最近播放 |
| `STATS` | `/stats` | 播放统计 |
| `ABOUT` | `/about` | 关于作者 |
| `LIVETOD` | `/livetod` | Live2D 互动页 |

导航示例：`Get.toNamed(RoutePath.MUSIC)`（或 `/music`）。

## 5. 主题系统

主题定义在 `lib/feature/theme/`：

- `app_theme.dart`：基于 Material 3 的 `ColorScheme`，提供 `AppTheme.light` 与 `AppTheme.dark` 两套。
- 主色为**淡粉色（玫瑰粉，`pink500` = `#C8567F`）**，按 60-30-10 原则组织色彩（中性 surface 打底，少量 primary 强调）。
- `color_value.dart` / `type_value.dart`：集中存放颜色与类型常量，避免散落的硬编码。
- `RcSemanticColors`：通过 `ThemeExtension` 补充 ColorScheme 缺省的 success / warning / info 语义色，使用方式 `Theme.of(context).extension<RcSemanticColors>()!.success`。

## 6. 国际化

`lib/utils/my_message.dart` 中的 `MyMessage` 继承 `Translations`，提供中（`zh_CN`）/ 英（`en_US`）双语映射。UI 通过 `.tr` 调用，如 `'欢迎使用Rctool'.tr`。应用默认语言与回退语言在 `GetMaterialApp` 中设置，用户语言偏好持久化于 `SharedPreferences`。

## 7. 资源与字体

- 自定义字体图标：`fonts/iconfont.ttf`，在 `pubspec.yaml` 注册为 `RcIcon` 字体族，`lib/iconfont/rc_icon.dart` 进行封装。
- 静态图片与 Live2D 资源：`image/`（背景、插画）与 `assets/live2d/`（模型 + viewer），均在 `pubspec.yaml` 的 `assets` 段声明。

## 8. 共享 UI 组件（重构后）

为避免各页面重复编写脚手架与列表行，项目抽取了以下共享组件（`lib/widget/`）：

- **`AppScaffold`**：统一页面外壳，封装 `Scaffold` + `Drawer`（主菜单）+ `AppBar`（菜单按钮 + 全局设置入口 `SearchWidget`）+ 背景装饰。音乐页、推荐、排行榜、歌单、歌单详情、选曲等均已改用它，消除了原本逐字重复的脚手架代码。
- **`SongRow`**：统一的"渐变条 + 封面 + 标题 + 播放/移除"横向歌曲卡片，替换了推荐、选曲、歌单详情三处原本重复的"大行"实现，并修复了亮色主题下白色图标不可见的问题，播放/暂停图标带切换动画；传入 `index` 时会在封面左侧显示序号，供播放队列使用；传入 `onMore` 时右侧多一个「…」按钮。
- **`SongActionsSheet`**（`lib/widget/song_actions_sheet.dart`）：`showSongActions()` 打开歌曲操作面板，提供「添加到歌单」（列出「我的喜欢」与全部自建歌单，可直接新建）、「收藏 / 取消收藏」，并可按场景追加一项移除操作。推荐、队列、歌单详情、最近播放的「…」都用它。
- **`SlideFadeIn`**：列表/卡片入场动画（淡入 + 上滑，支持延迟形成错落效果），排行榜、每日推荐、关于作者等页面已使用。
- **`SettingsSection` / `SettingsHeader` / `SettingsChoiceTile` / `SettingsSwitchTile` / `SettingsActionTile`**（`lib/widget/settings_ui.dart`）：设置界面通用组件。全局快捷面板（`search_widget`）、完整设置弹窗（`setting_dialog`）与设置页内容（`main_settings`）共用同一套分组卡片、图标容器与选中/开关样式，保证两处入口视觉完全一致。
- **`NowPlayingBar`**（`lib/widget/now_playing_bar.dart`）：迷你播放条，固定在非播放页底部（每日推荐、首页、歌单详情已接入），展示当前歌曲封面、标题、实时进度与播放/暂停，队列为空时自动隐藏。
- **`PlaylistDetailPage`**（`lib/page/AlbumPage/playlist_detail_page.dart`）：歌单详情页，`id = -1` 时为内置「我的喜欢」默认歌单（数据来源 `favorite_music` 表），其余为普通歌单（`playlist_music` 表），两者共用同一套详情 UI。
- **`DeviceInfoPanel`**（`lib/widget/device_info_panel.dart`）：设备信息卡，数据经 `lib/utils/device_info.dart` 汇总原生通道与 `/proc` 信息后展示。
- **`AppInfo`**（`lib/constant/app_info.dart`）：应用名、版本、仓库地址、作者等常量，供首页 / 关于页 / 设备信息复用。
- **动画与样式**：播放/暂停按钮采用 `AnimatedSwitcher` 缩放切换；`MSCard`（正在播放卡片）改为封面铺满 + 底部渐隐蒙层、尺寸随可用空间自适应；`music_list` 底部播放条压缩为单行紧凑布局（封面 42px + 细进度条），整体高度约为原来的一半。

下一篇：[03 - 功能模块](./03-features.md)
