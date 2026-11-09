# 05 - Live2D Integration

> **Languages:** English · [简体中文](05-live2d.zh-CN.md)

RcTool offers Live2D character interaction on the `/livetod` page. The approach: **host the Web Live2D runtime in a WebView and load models bundled under `assets/live2d/`**, so a single codebase covers Android / iOS / desktop / Web.

## 1. Asset layout

```
assets/live2d/
├── viewer/                 # Web Live2D runtime (HTML/JS, loads and renders models)
└── models/
    ├── Haru/               # Bundled model
    │   ├── Haru.model3.json      # Model entry config
    │   ├── Haru.moc3              # Model skeleton
    │   ├── Haru.physics3.json     # Physics (hair / ribbon sway, etc.)
    │   ├── Haru.pose3.json        # Poses
    │   ├── Haru.cdi3.json         # Parameter documentation
    │   ├── Haru.userdata3.json
    │   ├── Haru.2048/             # Textures (texture_00/01.png)
    │   ├── expressions/           # Expressions (F01–F08.exp3.json)
    │   ├── motions/               # Motions (idle / m01–m04)
    │   └── sounds/                # Sound effects for motions
    └── README.md
```

> These assets are declared in the `assets` section of `pubspec.yaml` (`assets/live2d/viewer/` and `assets/live2d/models/`) and ship with the app.

## 2. Platform adaptation

The rendering layer lives in `lib/widget/live2d/` and uses **conditional exports** for platform isolation:

```dart
// live2d_webview.dart
export 'live2d_webview_stub.dart'
    if (dart.library.io) 'live2d_webview_io.dart';
```

- `live2d_webview_stub.dart`: Web placeholder implementation.
- `live2d_webview_io.dart`: native (Android / iOS / desktop) implementation, hosting the viewer with `webview_flutter` (mobile/Web) and `webview_windows` (Windows desktop).

The `live_to_d.dart` page therefore only depends on the unified `live2d_webview` entry and does not care about the concrete platform.

## 3. Rendering pipeline

1. The WebView loads the web page in `assets/live2d/viewer/`.
2. The viewer uses `Haru.model3.json` to locate model parts, textures, motions and expressions.
3. The Web Live2D runtime (Cubism Web SDK) parses `.moc3` and `.physics3.json`, renders in real time and applies physics / motions.
4. Flutter can interact with the page through the WebView's JS bridge (e.g. touch events, switching motions / expressions with the music).

## 4. Interaction and synchronization

- **Touch interaction**: tapping / dragging the character triggers the corresponding `motions` or `expressions`.
- **Zoom control**: the bottom zoom bar in `live_to_d.dart` (− / slider / ＋ / percentage) passes the factor to `Live2DWebView(zoom:)`, and Flutter calls `window.live2dBridge.setZoom(value)` through the JS bridge. `fitModelToStage()` computes scale as `0.86 * zoom`; the default is 0.8 (a full-screen fit looks too large), the range is 0.45–1.6, and the value is persisted to `SharedPreferences` (`live2dZoomKey`). Calls made before the model finishes loading are ignored, and the `ready` callback syncs once more.
- **Status reporting**: `window.__rcPost({type: progress|ready|error, ...})` is sent back through `RcLive2DBridge` (Android) or `chrome.webview.postMessage` (Windows); Flutter uses it to show the progress overlay, failure reason and retry entry.
- **Lip sync**: audio is decoded by Flutter's native player (`audioplayers`), so the WebView cannot access audio samples. `main.js` instead simulates speech rhythm with a "syllable envelope" (fast open, slow close + phrase contour), writing `ParamMouthOpenY` in the `internalModel`'s `beforeModelUpdate` callback — at that point motions and physics are computed but `coreModel.update()` has not yet run, so the write actually takes effect. The toggle is in the top right (`live2dLipSyncKey` persisted), drives the mouth only during playback, and closes it smoothly on pause.
- **State pushing**: `Live2DWebView(lipSync:)` pushes playback state into the page via `window.live2dBridge.setLipSync(bool)`, syncing once more in the `ready` callback so switching songs does not lose the state.

## 5. Adding models

### 5.1 External directory (recommended, no repackaging)

1. Copy the whole model folder (containing `.model3.json` plus `moc3 / textures / motions / expressions / physics`) into `<external dir>/Live2D/`; nested subdirectories are supported.
2. Open `/livetod`; the model badge in the top left automatically lists scanned models. Open it → "Rescan" to see the new model; selecting it reloads the WebView with a new `?model=`.
3. The selection is persisted in `live2dModelKey` (a relative path without the port, so it survives restarts); if the model disappears, the app falls back to the bundled Haru.

Implementation notes:

- `Live2DModelLibrary.scan()` recursively finds `*.model3.json` and skips hidden directories; the display name is the filename without its extension.
- `Live2DAssetServer` adds an `/ext/<relative path>` route that reads from disk and validates `p.isWithin` to prevent `../` traversal; responses carry `Cache-Control: no-store` so replacing a model never serves stale content.
- On startup the viewer reads the `model` parameter from `location.search` (`resolveInitialModel()`); only when it is absent does it use the built-in relative path `../models/Haru/Haru.model3.json`.
- Models can also be imported from inside the app (`lib/service/resource_importer.dart`) instead of copying folders by hand.

### 5.2 Bundled assets (shipped with the app)

1. Put the model directory under `assets/live2d/models/<ModelName>/`.
2. Declare the assets in `pubspec.yaml`. **Note that a Flutter directory declaration only includes files directly inside that directory, not subdirectories** — you must list `viewer/vendor/`, `models/<Model>/`, `<Model>.2048/`, `expressions/` and `motions/` individually, otherwise the runtime and model will not be packed into the APK and the page will only report "runtime not loaded".
3. Register the new built-in model where `Live2DModelLibrary.builtIn` is defined (or in `scan()`), and the page can switch to it.

## 6. Debugging and common issues

- **Model not showing**: check that `pubspec.yaml` declares `assets/live2d/models/` and that the sub-file paths referenced inside `.model3.json` match the files on disk.
- **Blank screen on desktop**: Windows uses `webview_windows`, so confirm the platform dependency is present and its runtime is available; iOS / Android use `webview_flutter`.
- **Web platform issues**: `live2d_webview_stub.dart` is only a placeholder; actual Web rendering still comes from the WebView provided by `webview_flutter`. If the Web platform needs special asset loading, handle relative paths inside the viewer.

Back to: [Documentation Hub](./README.md)
