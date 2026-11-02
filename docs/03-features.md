# 03 - 功能模块

本文档逐一介绍 RcTool 的业务功能及其实现要点。

## 0. 首页

`/`（`lib/page/home_page.dart`，`main.dart` 只负责 `home: const HomePage()`）由三部分组成：

- **渐变欢迎卡**：应用 Logo、欢迎语、副标题与版本号（`AppInfo.version`）。
- **快速开始**：听音乐 / Live2D 两张渐变大卡，点击直达对应页面。
- **音乐库**：每日推荐、排行榜、我的喜欢、歌单、播放统计五个入口，使用统一的分组卡片。
- 底部 `NowPlayingBar`：有播放队列时常驻，可直接暂停/切歌并进入播放页。

## 1. 音乐播放

核心由 `MusicController`（`lib/controller/music_controller.dart`）驱动，关键能力：

- **播放列表**：`musiclist`（`RxList`）保存当前播放队列，支持追加、去重。
- **播放 / 暂停**：`playLocal()` / `onPause()`；同一首歌再次点击会触发暂停。
- **上一首 / 下一首**：`skipPrevious()` / `skipNext()`，结合播放模式计算目标索引。
- **播放模式**（`enum PlayMode`）：只在「播放队列」页以紧凑图标切换，设置页不再提供该项。
  - `loop`：列表循环
  - `single`：单曲循环
  - `random`：随机（线性同余生成器产生伪随机序列，避免相邻重复）
- **进度控制**：`setPosition(double)` 将 0–100 的滑块值映射为 `Duration` 并 `seek`。
- **缓存播放**：`playCachedAudio()` 默认先用 `flutter_cache_manager` 把音频 URL 下载到本地缓存文件，再交给 `audioplayers` 播放；关闭“缓存优先”后直接播放网络地址。
- **缓存占用显示**：设置页的「缓存优先」与「清除音乐缓存」会显示当前缓存大小（`lib/utils/cache_size.dart` 直接统计缓存目录文件总大小，格式化后以 MB/KB 展示），清除后自动刷新为 0。
- **完成监听**：`onPlayerComplete` 自动续播下一首（`playNextLocal()`）。
- **播放设置**：音量、播放模式、通知开关、缓存优先都会持久化到 `SharedPreferences`，启动时由 `MusicController` 恢复。

> 数据模型上，一首 `Music` 持有 `url`（音频地址）、`imageUrl`（封面）、`songName`（歌名）、`decoration`（描述 / 歌手等），因此播放既支持远程 URL，也兼容本地路径。

## 2. 收藏

`FavoriteController`（`lib/controller/favorite_controller.dart`）管理两类收藏：

- **收藏歌曲**：`toggle/add/remove` 操作 `favorite_music` 表，并维护内存集合 `_favoriteMusicIds` 加速判断。
- **收藏歌单**：`togglePlaylist/addPlaylist/removePlaylist` 操作 `favorite_playlist` 表。
- **懒加载**：`ensureLoaded()` 保证首次使用前从数据库刷新；所有写操作后调用 `refresh()` 同步内存与 UI。

相关页面：**「我的喜欢」是内置的默认歌单**，不再单独占用一个页面，在歌单列表置顶展示，点进去与其他歌单共用同一个详情页（`/playlist`，`id = -1` 时数据源为 `favorite_music`）。

## 3. 每日推荐

`/recommend`（每日推荐）基于 `recommend_history` 与 `recommend_history_music` 两张表记录"某天推荐了哪些歌"，避免重复推荐。组件层见 `lib/components/RecommendCP/everyday_recommend.dart`。

页面细节：

- **操作栏**：播放全部 / 历史 / 收藏三个按钮统一为 `46px` 高度，通过 `SizedBox` 固定高度解决此前"带文字按钮比图标按钮高"的错位问题。
- **爱心收藏**：点击后**爱心图标本身变红填充**（按钮底色保持主题表面色，仅描边转为主色/红色），再次点击取消收藏。收藏语义是"把今日推荐这批歌曲加入「我的喜欢」默认歌单"，判断标准为这批歌是否全部已在收藏中。
- **底部播放条**：页面底部常驻 `NowPlayingBar`（`lib/widget/now_playing_bar.dart`），点击任意歌曲开始播放后出现，显示封面、歌名、实时进度与播放/暂停、下一首；队列为空时自动隐藏。
- **入场动画**：歌曲行使用 `SlideFadeIn` 错落淡入。

## 4. 排行榜 / 歌单

- `/ranking`（排行榜）：聚合热度 / 排序展示。
- `/album`（歌单列表）：与设置页同一套分组卡片样式。
  - **新建**：点右上角 `+` 或列表底部「新建歌单」，弹出输入框（含名称必填、重名校验），确认后创建。
  - **删除**：每个歌单行右侧的删除按钮才会触发删除，并需二次确认（输入框不再内嵌在列表里）。
  - **不展示歌曲**：列表只显示歌单名、创建日期与歌曲数；点击整行进入 `/playlist` 歌单详情页（歌单信息卡 + `SongRow` 歌曲列表 + 底部 `NowPlayingBar`）。
  - **我的喜欢**：作为默认歌单固定置顶，不可删除。
  - 每日推荐生成的内部歌单（`每日推荐 yyyy-MM-dd`）不会出现在列表中。

两者页面分别位于 `lib/page/RankingPage/` 与 `lib/page/AlbumPage/`。

## 5. 全局快捷面板

页面 `AppBar` 右侧挂载 `SearchWidget`（`lib/widget/search_widget.dart`），底部卡片包含：

- **设备信息**（`lib/widget/device_info_panel.dart`）：机型、Android 版本/API、CPU 核心数与最高主频、ABI、内存占用、屏幕分辨率、应用版本，可手动刷新。
- **主题 / 语言 / 播放**设置项，以及「完整设置」入口。

设备数据优先通过 Android 原生通道 `rctool/device_info`（`MainActivity.kt`）读取 `Build`、`ActivityManager`、`Runtime` 信息；CPU 型号、主频与内存总量再用 `/proc/cpuinfo`、`/sys/.../cpuinfo_max_freq`、`/proc/meminfo` 兜底，不依赖第三方插件。

两处设置界面共用 `lib/widget/settings_ui.dart` 中的组件（`SettingsSection` / `SettingsHeader` / `SettingsChoiceTile` / `SettingsSwitchTile` / `SettingsActionTile` / `SettingsInfoTile`），因此分组卡片、图标容器、选中标记与开关配色完全一致：全局面板为可滚动底部卡片，完整设置为居中弹窗，二者仅在展示形式上不同。

## 6. 通知与锁屏控制

`NotificationHelper`（`lib/utils/notification_helper.dart`）：

- 启动时创建两个 Android 通知通道：
  - `new_music_channel`（重要性 high）：用于"当前正在播放"等信息推送。
  - `playback_control_channel`（重要性 low，预留 `ongoing` 常驻）：用于播放控制通知（示例代码已注释，可作为后续扩展点）。
- 切歌时调用 `showNewMusicNotification()` 更新通知内容，使系统通知栏 / 锁屏能显示当前曲目。

## 7. 系统集成

- **权限**：`lib/utils/PermissionRequest/` 统一申请通知、存储等权限，启动时申请通知权限。
- **蓝牙耳机断连**：依赖 `headset_connection_event` 监听耳机状态，可在断连时自动暂停（与 `MusicController` 的播放状态联动）。
- **设置**：`lib/views/main_settings.dart` 与 `lib/widget/setting_dialog.dart` 提供完整设置，包括主题、语言、音量、通知、缓存、睡眠定时、清除缓存和恢复默认；播放模式不在设置中，改由「播放队列」页顶部的图标切换。

## 8. 最近播放

`/history`（`lib/page/HistoryPage/play_history_page.dart`）按时间倒序展示播放历史：

- `MusicController.playCachedAudio()` 在真正开始播放时写入 `play_history`，暂停后继续不会重复记录。
- 支持播放历史中的歌曲、删除单条记录、清空全部记录和下拉刷新。
- 历史保存歌曲快照，即使歌曲之后从曲库删除，记录仍可查看。

## 9. 播放统计

`/stats`（`lib/page/StatsPage/play_stats_page.dart`）基于播放历史生成本地统计：

- 概览：总播放次数、不同歌曲数、今日播放次数。
- 近 7 天播放柱状图（含日均次数）。
- 听歌时段分布：凌晨 / 上午 / 下午 / 晚上（按历史 `playedAt` 的小时分组）。
- 常听歌手（由常听歌曲聚合前 4 位）。
- 播放次数最多的前 5 首歌曲，可直接点击播放。
- 页面使用 `LayoutBuilder` + `ConstrainedBox(minHeight)`，内容不足时也铺满可视区域，下拉刷新在整个页面范围内可用。
- 所有统计只来自本机历史，不上传网络。

## 10. 睡眠定时

睡眠定时由 `MusicController` 管理，可在“设置 → 播放 → 睡眠定时”中开启：

- 可选 15 / 30 / 45 / 60 分钟后自动暂停。
- 设置页实时显示 `mm:ss` 倒计时，可随时修改或取消。
- 到时调用 `onPause()` 暂停播放并给出提示。

## 11. Live2D 互动

详见 [05 - Live2D 集成](./05-live2d.md)。简要特性：

- `/livetod` 进入 Live2D 页面，通过 WebView 加载 `assets/live2d/viewer/` 中的 Web 版 Live2D 运行时。
- 当前内置模型为 **Haru**（`assets/live2d/models/Haru/`），含表情（expressions）、动作（motions）、物理（physics）与贴图。
- 支持触摸交互触发角色动作、跟随音频节奏的动画（由页面层驱动）。
- 页面叠加：左上角模型徽标、顶部渐隐遮罩、底部毛玻璃「互动提示」卡（可收起），并提供**重新加载**按钮（通过更换 `ValueKey` 重建 WebView）。

## 12. 主题与多语言

- 跟随系统 / 亮色 / 暗色主题由 `IsDarkController` 控制并持久化，UI 实时响应（见 [02 - 整体架构](./02-architecture.md)）。
- 多语言通过 `MyMessage` + `.tr` 实现，默认中文，回退英文。

## 13. 关于作者

`/about`（`lib/page/about_author.dart`）使用 `AppScaffold` + `aboutBackGround` 背景，包含：

- 顶部渐变个人卡：应用 Logo（`image/RcTool.png`）、作者名、技术标签。
- 「关于作者」「作者的话」两张信息卡。
- 项目信息卡：版本、技术栈、主要功能，以及**一键复制仓库地址**（`Clipboard` + Snackbar 提示）。
- 卡片使用 `SlideFadeIn` 依次淡入。

下一篇：[04 - 数据库设计](./04-database.md)
