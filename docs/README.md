# RcTool Documentation Hub

> **Languages:** English · [简体中文](README.zh-CN.md)

Welcome to the official documentation of **RcTool**, a Flutter-based cross-platform music player with an integrated Live2D character, targeting Android / iOS / Windows / macOS / Linux / Web.

These documents take you from a fresh clone to a solid understanding of every module's design.

## Navigation

| Document | Summary | Best for |
| --- | --- | --- |
| [01 - Getting Started](./01-getting-started.md) | Environment setup, dependencies, project layout, running and building | Developers new to the project |
| [02 - Architecture](./02-architecture.md) | Layering, state management, routing, theming, i18n | Developers who need the big picture |
| [03 - Features](./03-features.md) | Music playback, favorites, recommendations, rankings, Live2D, and more | Anyone asking "what can it do?" |
| [04 - Database Design](./04-database.md) | SQLite schema, entities, data access layer | Developers touching persistence |
| [05 - Live2D Integration](./05-live2d.md) | Model assets, the WebView hosting approach, platform adaptation | Developers maintaining the Live2D interaction |

## Documentation languages

Every document is published in two languages. The path without a suffix is English (the default); appending `.zh-CN` before `.md` gives the Chinese edition. For example, `03-features.md` and `03-features.zh-CN.md`. Each page links to its counterpart at the top, and all internal links stay within the same language.

## Tech stack at a glance

- **Framework**: Flutter (SDK `^3.5.1`)
- **State management & routing**: GetX (`get ^4.6.1`)
- **Audio playback**: `audioplayers`, with `flutter_cache_manager` for cached playback
- **Local storage**: `sqflite` + `sqflite_common_ffi` / `sqflite_common_ffi_web` (FFI on desktop/Web)
- **Local notifications / lock-screen controls**: `flutter_local_notifications`
- **Permissions**: `permission_handler`
- **Bluetooth headset disconnect detection**: `headset_connection_event`
- **Live2D rendering**: `webview_flutter` + `webview_windows` (Web-based Live2D)
- **Settings persistence**: `shared_preferences`

## Project goals

- Smooth music playback and control
- Playlist management and multiple play modes
- Live2D character interaction (touch, animation)
- OS integration through notification and lock-screen controls
- Local persistence for favorites, playlists and recommendation history

> Back to the root [README](../README.md).
