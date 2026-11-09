# 02 - Architecture

> **Languages:** English · [简体中文](02-architecture.zh-CN.md)

This document describes RcTool's layering, state management, routing, theming and internationalization.

## 1. Layers at a glance

RcTool uses a lightweight "page / view → controller → data layer" structure wired together by GetX:

```
┌─────────────────────────────────────────────┐
│  Pages / views (page, views, widget, comp.)  │  ← UI layer
└───────────────┬─────────────────────────────┘
                │ GetBuilder / .obs reactive bindings
┌───────────────▼─────────────────────────────┐
│           Controllers (controller)           │  ← State layer (GetxController)
│   MusicController / FavoriteController /     │
│   IsDarkController                           │
└───────────────┬─────────────────────────────┘
                │ calls
┌───────────────▼─────────────────────────────┐
│           Data layer (repository)            │  ← Persistence layer
│   entity/* models + SqlLiteConn/* DAOs        │
└───────────────┬─────────────────────────────┘
                │ calls
┌───────────────▼─────────────────────────────┐
│   Low-level deps: sqflite / audioplayers /   │
│   flutter_local_notifications / shared_prefs │
└─────────────────────────────────────────────┘
```

## 2. Entry point and startup

Startup order in `lib/main.dart`:

1. `WidgetsFlutterBinding.ensureInitialized()` — initialize Flutter bindings.
2. `NotificationHelper().initialize()` — create Android notification channels (new releases, playback controls).
3. `runApp(const MyApp())` — enter the app.

`MyApp.initState` performs:

- The startup fade-in (`AnimationController` + `FadeTransition`).
- Reads `SharedPreferences` settings (language, playback flags) and sets `appLocale` accordingly.
- Calls `PermissionRequest.requestNotificationPermission()` for the notification permission.
- Locks the orientation to portrait via `SystemChrome.setPreferredOrientations`.

`MyApp` wraps `GetMaterialApp` in `GetBuilder<IsDarkController>` so light / dark themes switch live; `themeMode` is owned by `IsDarkController`.

## 3. State management (GetX)

The project follows the GetX pattern:

- **Reactive state**: controllers extend `GetxController`; mutable state uses `.obs` (e.g. `isplay`, `position`, `playMode`).
- **View refresh**: the UI subscribes through `GetBuilder<Controller>` or `Obx` and rebuilds automatically.
- **Dependency injection**: `Get.put(IsDarkController(), permanent: true)` registers a permanent singleton.

Main controllers:

| Controller | Responsibility |
| --- | --- |
| `MusicController` | Playlist, play / pause, previous / next, play mode (loop / single / shuffle), progress, cached playback, notification integration |
| `FavoriteController` | CRUD for favorite songs and favorite playlists, in-memory index cache |
| `IsDarkController` | Light / dark theme mode |

## 4. Routing

Routes live in `lib/routers/`: `route_path.dart` defines the path constants, `Index.dart` defines the `GetPage` list (all using `Transition.rightToLeft`).

| Constant | Path | Page |
| --- | --- | --- |
| `HOME` | `/` | Home (welcome card + quick start + music library entries) |
| `MUSIC` | `/music` | Music list page |
| `MUSICCHOOSE` | `/musicchoose` | Play queue (play mode icons, clear queue) |
| `RECOMMEND` | `/recommend` | Daily recommendations |
| `RANKING` | `/ranking` | Rankings |
| `ALBUM` | `/album` | Playlist list |
| `PLAYLIST` | `/playlist` | Playlist detail (passes a `Playlist` via `arguments`; `id = -1` means "My Favorites") |
| `HISTORY` | `/history` | Recently played |
| `STATS` | `/stats` | Playback statistics |
| `ABOUT` | `/about` | About the author |
| `LIVETOD` | `/livetod` | Live2D interaction page |

Navigation example: `Get.toNamed(RoutePath.MUSIC)` (or `/music`).

Top-level pages are mutually exclusive: `AppNav.goTopLevel()` replaces the current top-level page instead of pushing, so the stack never grows without bound. Returning to the home page does not replay its entrance animation.

## 5. Theming

Themes live in `lib/feature/theme/`:

- `app_theme.dart`: Material 3 `ColorScheme` with `AppTheme.light` and `AppTheme.dark`.
- The primary color is a **soft rose pink (`pink500` = `#C8567F`)**, organized by the 60-30-10 rule (neutral surfaces as the base, a little primary for emphasis).
- `color_value.dart` / `type_value.dart`: centralized color and type constants, avoiding scattered hardcoded values.
- `RcSemanticColors`: a `ThemeExtension` supplying the success / warning / info colors missing from `ColorScheme`, used as `Theme.of(context).extension<RcSemanticColors>()!.success`.

## 6. Internationalization

`MyMessage` in `lib/utils/my_message.dart` extends `Translations` and provides Chinese (`zh_CN`) / English (`en_US`) / Japanese (`ja_JP`) maps. Keys are the Chinese source strings (`'播放全部'.tr`); parameterized strings use `@placeholder` with `trParams`.

Language state is held by `LocaleController` in `lib/controller/locale_controller.dart`:

- `locale` is an `Rx<Locale>`; `MyApp` wraps `GetMaterialApp` in `Obx` and passes it to `locale:`, so switching languages rebuilds MaterialApp itself and therefore every route and overlay subtree.
- `change()` writes `Get.locale` first (`.tr` reads from it), then updates the Rx, and finally persists to `SharedPreferences` (`languageCodeKey` / `countryCodeKey`).
- `restore()` is awaited once in `main()` to avoid a one-frame flash of Chinese on cold start.
- Calling `Get.updateLocale()` alone is not enough: `Get.locale` is a plain field, so assigning it notifies no widget. It would have to rely on `performReassemble()` to rebuild the entire tree, which tends to miss overlays and cached pages.

`test/layout_smoke_test.dart` has two guards: all three language bundles must have exactly the same key set with no empty values, and switching `Get.locale` must produce different translations for the same key.

## 7. Assets and fonts

- Custom icon font: `fonts/iconfont.ttf`, registered in `pubspec.yaml` as the `RcIcon` family and wrapped by `lib/iconfont/rc_icon.dart`.
- Static images and Live2D assets: `image/` (wallpapers, illustrations) and `assets/live2d/` (models + viewer), both declared in the `assets` section of `pubspec.yaml`.

## 8. Shared UI components (post-refactor)

To avoid repeating scaffolding and list rows on every page, the project provides these shared components (`lib/widget/`):

- **`AppScaffold`**: a common page shell wrapping `Scaffold` + `Drawer` (main menu) + `AppBar` (menu button and the global settings entry `SearchWidget`) + background decoration. Music, recommendations, rankings, playlists, playlist detail and song selection all use it, eliminating copy-pasted scaffolding. Its `ScaffoldState` key is held in the widget's `State`, so rebuilding does not remount the whole subtree (which would restart entrance animations and reset scroll positions).
- **`SongRow`**: a shared "gradient bar + cover + title + play/remove" horizontal song card that replaced three duplicated large-row implementations (recommendations, song selection, playlist detail). It fixes white icons being invisible on light themes, animates play/pause icon swaps, shows an index left of the cover when `index` is passed (used by the queue), and adds a "…" button when `onMore` is passed.
- **`SongActionsSheet`** (`lib/widget/song_actions_sheet.dart`): `showSongActions()` opens the song action sheet with "Add to playlist" (lists "My Favorites" and all custom playlists, and can create one inline), "Favorite / Unfavorite", and an optional contextual remove action. The "…" buttons in recommendations, the queue, playlist detail and recent history all use it.
- **`SlideFadeIn`**: entrance animation for list rows / cards (fade + slide up, with optional delay for staggered reveals), used by rankings, daily recommendations, the about page and others. `stagger()` applies a stepped delay to a group of children; `PageEnter` wraps the whole page body.
- **`SettingsSection` / `SettingsHeader` / `SettingsChoiceTile` / `SettingsSwitchTile` / `SettingsActionTile`** (`lib/widget/settings_ui.dart`): shared settings components. The global quick panel (`search_widget`), the full settings dialog (`setting_dialog`) and the settings page content (`main_settings`) all reuse the same grouped cards, icon containers and selected/switch styles, keeping both entry points visually identical.
- **`NowPlayingBar`** (`lib/widget/now_playing_bar.dart`): a mini player pinned to the bottom of non-player pages (daily recommendations, home, playlist detail), showing cover, title, live progress and play/pause; hides itself when the queue is empty.
- **`PlaylistDetailPage`** (`lib/page/AlbumPage/playlist_detail_page.dart`): playlist detail; `id = -1` is the built-in "My Favorites" playlist (backed by the `favorite_music` table), all others are regular playlists (`playlist_music`). Both share the same detail UI.
- **`DeviceInfoPanel`** (`lib/widget/device_info_panel.dart`): device info card, fed by `lib/utils/device_info.dart`, which aggregates native channel data and `/proc` information.
- **`AppInfo`** (`lib/constant/app_info.dart`): app name, version, repository URL, author and similar constants reused by home / about / device info.
- **Animation and styling**: play/pause uses an `AnimatedSwitcher` scale transition; `MSCard` (now-playing card) uses a full-bleed cover with a bottom fade and a size that adapts to available space; the `music_list` bottom bar is a compact single row (42px cover + thin progress bar), roughly half its previous height.

Next: [03 - Features](./03-features.md)
