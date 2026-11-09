# 03 - Features

> **Languages:** English · [简体中文](03-features.zh-CN.md)

A module-by-module tour of RcTool's functionality and how it is implemented.

## 0. Home

`/` (`lib/page/home_page.dart`; `main.dart` only sets `home: const HomePage()`) consists of three parts:

- **Gradient welcome card**: app logo, greeting, subtitle and version (`AppInfo.version`).
- **Quick start**: two large gradient cards for Music and Live2D, jumping straight to those pages.
- **Music library**: five entries — Daily Recommendations, Rankings, My Favorites, Playlists, Playback Statistics — in a shared grouped card.
- Bottom `NowPlayingBar`: pinned whenever a queue exists; pause / skip songs and enter the player directly.

All of these elements fade in with staggered `SlideFadeIn` / `stagger()` delays when the page is entered.

## 1. Music playback

Driven by `MusicController` (`lib/controller/music_controller.dart`):

- **Playlist**: `musiclist` (`RxList`) holds the current queue and supports append and deduplication.
- **Play / pause**: `playLocal()` / `onPause()`; tapping the same song again pauses it.
- **Previous / next**: `skipPrevious()` / `skipNext()` compute the target index from the play mode.
- **Play modes** (`enum PlayMode`): switched by compact icons on the Play Queue page only; the settings page no longer offers this.
  - `loop`: loop the list
  - `single`: repeat one song
  - `random`: shuffle (a linear congruential generator produces a pseudo-random sequence that avoids adjacent repeats)
- **Progress control**: `setPosition(double)` maps a 0–100 slider value to a `Duration` and calls `seek`.
- **Cached playback**: `playCachedAudio()` by default downloads the audio URL to a local cache file with `flutter_cache_manager` before handing it to `audioplayers`; with "cache first" disabled it streams the network URL directly.
- **Cache size display**: the settings entries "Cache first" and "Clear music cache" show the current cache size (`lib/utils/cache_size.dart` sums the cache directory and formats it as MB/KB); it refreshes to 0 after clearing.
- **Completion listener**: `onPlayerComplete` automatically continues with the next song (`playNextLocal()`).
- **Playback settings**: volume, play mode, notification toggle and cache-first are persisted to `SharedPreferences` and restored by `MusicController` on startup.
- **Controller singletons**: `MusicController` / `FavoriteController` / `IsDarkController` are each registered once in `main()` (`permanent: true`) and pages use `Get.find`. Previously individual pages called `Get.put`, replacing instances and desynchronizing progress, favorites and the queue across pages.
- **Full-screen player** (`lib/page/PlayerPage/now_playing_page.dart`): tap any empty area of the mini player to enter; blurred, color-extracted cover background, hero transition for the large cover, draggable progress, play mode / previous / play-pause / next / current queue all on one screen, swipe down to dismiss. Only "Lyrics / More" remain in the top right; redundant counters such as "playing x/x" were removed.
- **Current queue sheet** (`lib/widget/queue_sheet.dart`): the button next to "Next" in the player opens a bottom sheet instead of navigating away. Tap any song to switch immediately; the trailing button removes it from the queue; count and current item stay in sync.
- **Instant favorite feedback**: `FavoriteController.toggle()` updates the in-memory set and calls `update()` before writing to the database, rolling back on failure. Hearts in the player and list cards therefore change color on tap instead of waiting for a database read-back.
- **Queue drag sorting**: the play queue uses `ReorderableListView`; long-press any song to drag it. `reorderQueue()` moves the playback index along with the current song so the wrong track never plays. After removing a song, a SnackBar offers "Undo" (`removeAt` / `insertAt`).
- **Library search** (`lib/page/SearchPage/search_page.dart`): filters the local library by song name / artist in real time, highlights matched keywords (`SongRow.highlight`), keeps up to 10 recent searches (clearable), and supports playing the whole result set or per-song "…" actions. Entry point: the magnifier in every page's AppBar.
- **Page transitions**: opening many pages no longer accumulates a stack — `AppNav.goTopLevel()` keeps top-level pages exclusive and the stack depth constant.

> In the data model a `Music` holds `url` (audio address), `imageUrl` (cover), `songName` (title) and `decoration` (description / artist, etc.), so playback supports both remote URLs and local paths.

## 2. Favorites

`FavoriteController` (`lib/controller/favorite_controller.dart`) manages two kinds of favorites:

- **Favorite songs**: `toggle/add/remove` operate on the `favorite_music` table and maintain the in-memory `_favoriteMusicIds` set for fast lookups.
- **Favorite playlists**: `togglePlaylist/addPlaylist/removePlaylist` operate on `favorite_playlist`.
- **Lazy loading**: `ensureLoaded()` refreshes from the database before first use; every write calls `refresh()` to resync memory and UI.

Related page: **"My Favorites" is a built-in default playlist**, not a separate page. It is pinned at the top of the playlist list and opens the same detail page as any other playlist (`/playlist`, with `id = -1` reading from `favorite_music`).

## 3. Daily recommendations

`/recommend` uses the `recommend_history` and `recommend_history_music` tables to record "which songs were recommended on a given day" and avoid repeats. See `lib/components/RecommendCP/everyday_recommend.dart`.

Page details:

- **Action bar**: Play All / History / Favorite share a fixed `46px` height via `SizedBox`, fixing the earlier misalignment where text buttons were taller than icon buttons.
- **Heart favorite**: tapping fills the heart icon itself in red (the button background keeps the theme surface color and only its border turns primary/red); tap again to undo. The semantics are "add today's recommended batch to the My Favorites default playlist", decided by whether all songs in the batch are already favorited.
- **Bottom player**: `NowPlayingBar` (`lib/widget/now_playing_bar.dart`) appears once a song starts playing, showing cover, title, live progress, play/pause and next; it hides when the queue is empty.
- **Entrance animation**: song rows fade in with staggered `SlideFadeIn` delays.

## 4. Rankings / playlists

- `/ranking`: aggregated popularity / sorted display.
- `/album` (playlist list): shares the grouped-card style with the settings page.
  - **Create**: tap `+` in the top right (next to the global settings button) to open an input dialog (name required, duplicate names rejected).
  - **Delete**: only the trailing delete button on a row triggers deletion, with a confirmation step (the input box is no longer embedded in the list).
  - **No songs in the list**: rows show only name, creation date and song count; tapping a row opens `/playlist` (playlist info card + `SongRow` list + bottom `NowPlayingBar`).
  - **Add songs**: the detail page has no "Add songs" entry; instead the "…" button on any song row opens the action sheet to add that song to My Favorites or any custom playlist (tap again to remove).
  - **My Favorites**: pinned at the top as a default playlist and cannot be deleted.
  - Internal playlists generated by daily recommendations (`每日推荐 yyyy-MM-dd`) never appear in the list.

Both pages live in `lib/page/RankingPage/` and `lib/page/AlbumPage/`.

## 5. Global quick panel

`SearchWidget` (`lib/widget/search_widget.dart`) is mounted on the right of each AppBar; its bottom card contains:

- **Device info** (`lib/widget/device_info_panel.dart`): model, Android version/API, CPU core count and max frequency, ABI, memory usage, screen resolution, app version, with manual refresh.
- Settings for **theme / language / playback**, plus an entry to the full settings dialog.

Device data comes primarily from the Android native channel `rctool/device_info` (`MainActivity.kt`) reading `Build`, `ActivityManager` and `Runtime`; CPU model, frequency and total memory fall back to `/proc/cpuinfo`, `/sys/.../cpuinfo_max_freq` and `/proc/meminfo` — no third-party plugin needed.

Both settings surfaces share components from `lib/widget/settings_ui.dart` (`SettingsSection` / `SettingsHeader` / `SettingsChoiceTile` / `SettingsSwitchTile` / `SettingsActionTile` / `SettingsInfoTile`), so grouped cards, icon containers, selection markers and switch colors are identical: the global panel is a scrollable bottom card, the full settings is a centered dialog — only the presentation differs.

## 6. Notifications and lock-screen controls

`NotificationHelper` (`lib/utils/notification_helper.dart`):

- Two Android notification channels: `new_music_channel` (high, informational) and `playback_control_channel` (low, playback controls).
- **Persistent playback notification**: `showPlaybackNotification()` shows the current track and artist with three action buttons (previous / pause·play / next), using `ongoing + onlyAlertOnce + no sound`, so changing tracks does not ring every time.
- Button taps return through `initialize(onDidReceiveNotificationResponse:)` into `MusicController._handleNotificationAction()`, with action ids `rctool.prev / rctool.toggle / rctool.next`.
- Triggers: start playing, pause, track change, clearing the queue, toggling "playback notification".
- Limitation: the project does not integrate the `audio_service` foreground service, so buttons depend on the app process being alive (they work in the background and with the screen off); once the system kills the process the notification is display-only.

## 7. OS integration

- **Permissions**: `lib/utils/PermissionRequest/` requests notification, storage and other permissions, including the notification permission at startup.
- **Bluetooth headset disconnect**: `headset_connection_event` monitors headset state and can auto-pause on disconnect, coordinated with `MusicController`'s playback state.
- **Settings**: `lib/views/main_settings.dart` and `lib/widget/setting_dialog.dart` provide full settings for theme, language, volume, notifications, cache, sleep timer, clearing cache and restoring defaults; play mode is not in settings, but switched by icons at the top of the Play Queue page.
- **In-app imports**: wallpapers and Live2D models can be imported from inside the app (`lib/service/resource_importer.dart`), so users no longer need to copy files into a directory manually. A "Open folder" action sends an `ACTION_VIEW` chooser Intent via a MethodChannel, letting the user pick which file manager app to use.

## 8. Recently played

`/history` (`lib/page/HistoryPage/play_history_page.dart`) shows history in reverse chronological order:

- `MusicController.playCachedAudio()` writes to `play_history` when playback actually starts; resuming after a pause does not create a duplicate.
- Supports playing a song from history, deleting a single record, clearing all records and pull-to-refresh.
- History stores a song snapshot, so records remain viewable even if the song is later removed from the library.
- Duplicate entries for the same song are collapsed (grouped by `url`, keeping the latest `playedAt`), and a 5-second repeat window prevents one tap from producing two rows.

## 9. Playback statistics

`/stats` (`lib/page/StatsPage/play_stats_page.dart`) generates local statistics from play history:

- Overview: total plays, distinct songs, plays today.
- 7-day bar chart (with daily average).
- Listening time-of-day distribution: late night / morning / afternoon / evening (grouped by the hour of `playedAt`).
- Top artists (top 4 aggregated from most-played songs).
- Top 5 most-played songs, playable with one tap.
- Uses `LayoutBuilder` + `ConstrainedBox(minHeight)` so short content still fills the viewport and pull-to-refresh works across the whole page.
- All statistics come from local history only; nothing is uploaded.

## 10. Sleep timer

Managed by `MusicController`, enabled under "Settings → Playback → Sleep timer":

- Auto-pause after 15 / 30 / 45 / 60 minutes.
- The settings page shows a live `mm:ss` countdown and allows changing or cancelling at any time.
- On expiry it calls `onPause()` and shows a hint.

## 11. Live2D interaction

See [05 - Live2D Integration](./05-live2d.md). In brief:

- `/livetod` opens the Live2D page, loading the Web Live2D runtime from `assets/live2d/viewer/` in a WebView.
- The bundled model is **Haru** (`assets/live2d/models/Haru/`) with expressions, motions, physics and textures.
- Touch interaction triggers character motions; a "lip sync" toggle can drive the mouth from music playback (syllable envelope + `ParamMouthOpenY` in `main.js`).
- The bottom-right zoom bar (0.45–1.6, default 0.8) and the top-right lip-sync toggle are persisted to `SharedPreferences`.
- Overlays: a model badge in the top left (tap to switch models), a top fade, a bottom frosted-glass "interaction hints" card (collapsible) and a **Reload** button (rebuilds the WebView by changing its `ValueKey`).
- **Automatic model scanning**: `Live2DModelLibrary` recursively scans all `*.model3.json` under `<external dir>/Live2D` and merges them with the built-in Haru; the picker supports rescan and copying the directory, and the selection is stored in `live2dModelKey`.

## 12. Theming and multiple languages

- Follow system / light / dark theme is controlled and persisted by `IsDarkController`, with live UI updates (see [02 - Architecture](./02-architecture.md)).
- Multiple languages via `MyMessage` + `.tr`: Chinese / English / Japanese, ~390 keys each with an identical key set (guarded by tests).
- **Single source of truth** `LocaleController`: switching first changes `Get.locale`, then the `Rx<Locale>`; an `Obx` in `MyApp` makes `GetMaterialApp` swap its `locale` directly. Relying only on `Get.updateLocale()` does not work — `Get.locale` is a plain field and notifies no widget, so it would need `performReassemble()` to rebuild the whole tree, which easily misses overlays and cached pages. That was the root cause of "switched language but some strings stayed the same".
- No hardcoded Chinese remains in code (except proper nouns such as built-in playlist names, song metadata, `日本語`): the database stores original names like "我的喜欢" and "每日推荐 2024-01-01", and display goes through `playlistDisplayName()` to follow the locale.

## 13. Lyrics

In the full-screen player (`/player`), tap the cover or the "Lyrics" icon in the top right to switch between cover and lyrics:

- LRC parsing in `lib/utils/lrc_parser.dart`: supports multiple timestamps on one line, `[offset:]`, `[ti:]` and similar metadata; plain-text lyrics can also be saved (in which case there is no scrolling or highlighting).
- Lyrics are stored in the `lyric` table by audio `url` (`LyricConn`), so the same song shows the same lyrics whether it was opened from the library, a playlist or history.
- The current line is highlighted and auto-centered; tap any line to seek to it; manual scrolling pauses follow mode and reveals "Back to current".
- "Edit lyrics" panel: paste from clipboard, edit raw text, fine-tune offset by ±0.5 s, delete lyrics; the empty state offers an import entry and a format example. Its layout compensates for the keyboard insets so the input field is never pushed off screen.

## 14. Offline cache

`OfflineController` (`lib/controller/offline_controller.dart`) owns download state:

- Downloaded songs show an offline badge at the end of the row subtitle (`SongRow` subscribes internally and refreshes as soon as the state changes).
- The song "…" sheet gains "Download to device / Delete offline cache" and shows per-song size.
- `/offline` management page: total count and size, per-song preview / delete, clear cache, adjust the cache cap.
- The cap can be Unlimited / 200MB / 500MB / 1GB / 2GB; when exceeded, the oldest audio is removed by download time (settings and offline pages share the same picker).
- Audio and covers share `DefaultCacheManager`, and the cap only counts audio files, so covers are never deleted by mistake (which would leave a list of placeholders).

## 15. Wallpapers and external assets

Page backgrounds are no longer hardcoded; external files take priority with built-in images as fallback:

- The root is resolved by `ExternalStorage` (`lib/service/external_storage.dart`): on Android it prefers `/storage/emulated/0/RcTool` (requires the "All files access" permission, reachable from a file manager) and falls back to the app-specific directory when not granted; on desktop it is `<Documents>/RcTool`. The resolved root is persisted to `SharedPreferences` so it cannot flip between public and private paths on later launches.
- Wallpapers live in `RcTool/wallpaper/` and map to pages by filename: `home` / `live2d` / `music` / `about`; a `default` image applies to all four. Supported: jpg / jpeg / png / webp / bmp. Each slot uses the most recently modified matching file.
- `WallpaperController` scans the directory and matches slots; `BackGroundEnum.imageProvider` returns a `FileImage` or the built-in `AssetImage` at runtime, and `AppScaffold` refreshes through `GetBuilder`. Replacing a file evicts the image cache too, so overwriting a same-named file is visible immediately.
- `/wallpaper` management page: shows the directory path (copyable), whether it is the public directory, a permission entry, previews and current status for the four pages, plus refresh in the top right. Delete a file to fall back to the built-in image.
- Images are decoded at display size via `ResizeImage` to avoid out-of-memory crashes on large photos.
- Directory layout:

```
RcTool/
├── wallpaper/      # home.jpg / live2d.png / music.webp / about.jpg / default.jpg
└── Live2D/         # one folder per model, containing xxx.model3.json
```

## 16. Resume playback

`MusicController` writes "queue + current index + playback position" to `SharedPreferences`:

- Persists every 4 seconds while playing, and immediately on pause, track change, playback start and queue clear, so exiting the app loses at most 4 seconds.
- On startup `_restoreSession()` restores the queue and index at the saved position (`isplay = false`, no sound); the mini player subtitle shows "Last played at 12:34".
- When the user presses play, `playCachedAudio()` matches `_resumeUrl` and uses `player.seek()` to return to that position, then clears the checkpoint.
- `MusicController.ready` exposes a Future; the library page awaits it before deciding "is the queue empty", so a restored queue is not overwritten at startup.

## 17. Backup and restore

`BackupService` (`lib/service/backup_service.dart`) + the `/backup` page:

- **Export**: dumps the `music / playlist / playlist_music / favorite_music / lyric` tables row by row, plus a settings snapshot (theme, language, play mode, volume, cache cap, Live2D zoom and lip sync, wallpaper/model selection), to `<external dir>/backup/rcbackup-yyyyMMdd-HHmmss.json` (indented JSON, readable and editable by hand).
- **Restore**: lists backups with time, size, playlist count and favorite count; after confirmation it runs `INSERT OR IGNORE` in a single transaction, merging same-named playlists by name and **never deleting existing local data**. A bad row (schema difference) is skipped.
- Settings are written back to `SharedPreferences` by type; favorite and wallpaper controllers refresh after restore.
- Backups do not contain audio files; playlists only store references to library songs.

## 18. About the author

`/about` (`lib/page/about_author.dart`) uses `AppScaffold` with the `aboutBackGround` background and contains:

- A top gradient profile card: app logo (`image/RcToolIcon.png`), author name, tech tags.
- Two info cards: "About the author" and "A note from the author".
- A project info card: version, tech stack, main features, and **one-tap copy of the repository URL** (`Clipboard` + Snackbar).
- Cards fade in one after another via `SlideFadeIn`.

Next: [04 - Database Design](./04-database.md)
