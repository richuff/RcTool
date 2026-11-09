# 01 - Getting Started

> **Languages:** English · [简体中文](01-getting-started.zh-CN.md)

This guide gets RcTool running locally and walks you through the project layout.

## 1. Requirements

| Tool | Recommended version | Notes |
| --- | --- | --- |
| Flutter SDK | `^3.5.1` (the README badge marks 3.24.x as verified) | Cross-platform build foundation |
| Dart SDK | Bundled with Flutter | — |
| Host machine | Windows / macOS / Linux | Desktop targets need the matching toolchain |
| Device / emulator | Android / iOS / desktop | Run and debug target |

> After installing Flutter, run `flutter doctor` first and make sure nothing is missing — especially Android SDK / Xcode / Visual Studio dependencies for the platforms you intend to build.

## 2. Get the code

```bash
git clone https://github.com/richuff/RcTool.git
cd rctool
```

## 3. Install dependencies

```bash
flutter pub get
```

See the root [`pubspec.yaml`](../pubspec.yaml) for the full dependency list (core libraries: `get`, `audioplayers`, the `sqflite` family, `flutter_local_notifications`, `webview_flutter` / `webview_windows`, and others).

## 4. Run the app

```bash
# After connecting a device or starting an emulator
flutter run
```

Target a specific platform:

```bash
flutter run -d android
flutter run -d windows
flutter run -d web
```

## 5. Build artifacts

```bash
# Android APK / AppBundle
flutter build apk
flutter build appbundle

# iOS (requires macOS + Xcode)
flutter build ios

# Desktop
flutter build windows
flutter build macos
flutter build linux

# Web
flutter build web
```

## 6. Project layout

```
rctool/
├── lib/                      # Application source (Dart)
│   ├── main.dart             # Entry: GetMaterialApp, theme, permissions, portrait lock
│   ├── routers/              # Route table (RoutePath constants + GetPage list)
│   ├── controller/           # GetX controllers (music / favorite / is_dark)
│   ├── repository/           # Data layer: entity models + SqlLiteConn database access
│   ├── views/                # Business views (music player, settings)
│   ├── page/                 # Pages (music, recommend, ranking, album, about, Live2D)
│   ├── widget/               # Shared widgets (drawer, search, background, Live2D, dialogs)
│   ├── components/           # Business components (song list, recommendation cards, ...)
│   ├── feature/              # Theming and design assets (palette, icon buttons)
│   ├── iconfont/             # Icon font wrapper
│   ├── constant/             # Constants (table names, etc.)
│   └── utils/                # Utilities (notifications, permissions, i18n, helpers)
├── assets/                   # Static assets (Live2D models and viewer, JSON configs)
├── image/                    # Wallpapers, icons, illustrations
├── fonts/                    # Custom fonts (iconfont.ttf)
├── android/ ios/ macos/ windows/ linux/ web/   # Platform projects
└── pubspec.yaml              # Dependencies and asset declarations
```

> The platform projects (`android/`, `web/`, `windows/`, `macos/`, ...) are gitignored in this repository. Regenerate them locally with `flutter create .` if they are missing.

## 7. Troubleshooting

- **Blank white / black screen on first launch**: make sure `assets/live2d/viewer/` and `assets/live2d/models/` are declared in `pubspec.yaml` and actually bundled.
- **Desktop database errors**: the project initializes FFI via `sqflite_common_ffi` on desktop; if it still fails, confirm the target is one of Windows / macOS / Linux.
- **Notifications not showing**: Android requires the notification permission (`permission_handler` requests it at startup); the lock-screen control channel is created by `NotificationHelper.initialize()`.
- **Permission denied**: `headset_connection_event`, `permission_handler` and similar plugins need the corresponding entries in each platform project's `Info.plist` / `AndroidManifest.xml`.

Next: [02 - Architecture](./02-architecture.md)
