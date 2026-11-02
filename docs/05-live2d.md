# 05 - Live2D 集成

RcTool 在 `/livetod` 页面提供 Live2D 角色互动。整体方案是：**用 WebView 承载 Web 版 Live2D 运行时，加载打包在 `assets/live2d/` 内的模型**，从而以一份代码覆盖 Android / iOS / 桌面 / Web。

## 1. 资源布局

```
assets/live2d/
├── viewer/                 # Web 版 Live2D 运行时（HTML/JS，加载模型并渲染）
└── models/
    ├── Haru/               # 当前内置模型
    │   ├── Haru.model3.json      # 模型入口配置
    │   ├── Haru.moc3              # 模型骨架
    │   ├── Haru.physics3.json     # 物理（头发 / 飘带摆动等）
    │   ├── Haru.pose3.json        # 姿势
    │   ├── Haru.cdi3.json         # 可动参数说明
    │   ├── Haru.userdata3.json
    │   ├── Haru.2048/             # 贴图（texture_00/01.png）
    │   ├── expressions/           # 表情（F01–F08.exp3.json）
    │   ├── motions/               # 动作（idle / m01–m04）
    │   └── sounds/                # 动作配套音效
    └── README.md
```

> 资源已在 `pubspec.yaml` 的 `assets` 中声明（`assets/live2d/viewer/` 与 `assets/live2d/models/`），打包后随应用分发。

## 2. 平台适配

Live2D 渲染层位于 `lib/widget/live2d/`，采用 **条件导出** 做平台隔离：

```dart
// live2d_webview.dart
export 'live2d_webview_stub.dart'
    if (dart.library.io) 'live2d_webview_io.dart';
```

- `live2d_webview_stub.dart`：Web 端占位实现。
- `live2d_webview_io.dart`：原生（Android / iOS / 桌面）实现，使用 `webview_flutter`（移动/Web）与 `webview_windows`（Windows 桌面）承载 viewer。

这样上层 `live_to_d.dart` 页面只依赖统一的 `live2d_webview` 入口，无需关心具体平台。

## 3. 渲染原理

1. WebView 加载 `assets/live2d/viewer/` 中的 Web 页面。
2. viewer 通过 `Haru.model3.json` 找到模型各部件、贴图、动作、表情。
3. Web 端 Live2D 运行时（Cubism Web SDK）解析 `.moc3` 与 `.physics3.json`，实时渲染并应用物理 / 动作。
4. Flutter 侧可通过 WebView 的 JS 桥与应用交互（例如：触摸事件、随音乐节奏切换动作 / 表情）。

## 4. 交互与联动

- **触摸交互**：用户点击 / 拖拽角色，触发对应 `motions` 动作或 `expressions` 表情。
- **缩放控制**：`live_to_d.dart` 底部缩放条（− / 滑块 / ＋ / 百分比）把倍率传给 `Live2DWebView(zoom:)`，Flutter 侧通过 JS 桥调用 `window.live2dBridge.setZoom(value)`；`fitModelToStage()` 里以 `0.86 * zoom` 计算缩放，默认 0.8（整屏贴合会显得过大），范围 0.45–1.6，倍率持久化到 `SharedPreferences`（`live2dZoomKey`）。模型未加载完成时的调用会被忽略，`ready` 回调里会再同步一次。
- **状态回传**：`window.__rcPost({type: progress|ready|error, ...})` 经 `RcLive2DBridge`（Android）或 `chrome.webview.postMessage`（Windows）回传，Flutter 据此显示进度浮层、失败原因与重试入口。
- **口型联动**：音频由 Flutter 原生播放器（`audioplayers`）解码，WebView 拿不到音频采样，因此 `main.js` 用「音节包络」模拟说话节奏（快张慢合 + 乐句起伏），在 `internalModel` 的 `beforeModelUpdate` 回调里写入 `ParamMouthOpenY`——此时动作与物理都已算完、`coreModel.update()` 尚未执行，写入才会真正生效。开关在页面右上角（`live2dLipSyncKey` 持久化），只在播放时驱动，暂停后平滑闭嘴。
- **状态驱动**：`Live2DWebView(lipSync:)` 通过 `window.live2dBridge.setLipSync(bool)` 把播放状态推进页面，`ready` 回调里补一次同步，切换歌曲不会丢失状态。

## 5. 新增模型

### 5.1 外部目录（推荐，无需重新打包）

1. 把模型文件夹（含 `.model3.json` 及其 `moc3 / 贴图 / motions / expressions / physics`）整个复制到 `<外部目录>/Live2D/` 下，支持多层子目录。
2. 打开 `/livetod`，左上角模型徽标会自动列出扫描到的模型；点开 → 「重新扫描」即可看到新模型，选中后 WebView 以新 `?model=` 重新加载。
3. 选择结果持久化到 `live2dModelKey`（存相对路径，不含端口，重启依旧有效）；模型被删掉时自动回退到内置 Haru。

实现要点：

- `Live2DModelLibrary.scan()` 递归查找 `*.model3.json`，跳过隐藏目录；展示名取文件名去掉后缀。
- `Live2DAssetServer` 增加 `/ext/<相对路径>` 路由，直接读磁盘并校验 `p.isWithin`，防止 `../` 越权；响应带 `Cache-Control: no-store`，替换模型后不会读到旧缓存。
- viewer 启动时读取 `location.search` 的 `model` 参数（`resolveInitialModel()`），没有参数才用内置相对路径 `../models/Haru/Haru.model3.json`。

### 5.2 内置资源（随包发布）

1. 将模型目录放到 `assets/live2d/models/<ModelName>/`。
2. 在 `pubspec.yaml` 的 `assets` 中声明资源。**注意 Flutter 的目录声明只收该目录下的直接文件，不递归子目录**——必须把 `viewer/vendor/`、`models/<Model>/`、`<Model>.2048/`、`expressions/`、`motions/` 逐个列出，否则运行库与模型不会被打进 APK，页面只会报「运行库未加载」。
3. 在 `Live2DModelLibrary.builtIn` 所在位置（或 `scan()` 里）登记新的内置模型，页面即可切换。

## 6. 调试与常见问题

- **模型不显示**：检查 `pubspec.yaml` 资源声明是否包含 `assets/live2d/models/`；确认 `.model3.json` 内引用的子文件路径与实际一致。
- **桌面端白屏**：Windows 走 `webview_windows`，需确认该平台依赖已正确引入且运行时可用；iOS / Android 走 `webview_flutter`。
- **Web 端异常**：`live2d_webview_stub.dart` 仅为占位，Web 实际渲染仍由 `webview_flutter` 提供的 WebView 完成；若 Web 平台需特殊资源加载逻辑，应在 viewer 内处理相对路径。

返回：[文档中心](./README.md)
