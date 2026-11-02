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
- **音频联动**：播放页 / Live2D 页可将 `MusicController` 的播放状态、节奏信息传递给 Web 端，驱动角色动作随音乐变化（具体桥接逻辑见 `live_to_d.dart` 与 viewer 配置）。

## 5. 新增模型步骤

1. 将新模型目录放到 `assets/live2d/models/<ModelName>/`，确保包含 `.model3.json` 及配套 `moc3 / 贴图 / motions / expressions`。
2. 在 `pubspec.yaml` 的 `assets` 中确认 `assets/live2d/models/` 已声明（目录级声明即可包含子目录）。
3. 在 viewer 的模型清单（或页面层）中登记新模型，供多角色切换使用。
4. 若涉及多角色切换 UI，可参考 `main.dart` 中"多角色切换"的产品目标，在 `/livetod` 页面扩展选择逻辑。

## 6. 调试与常见问题

- **模型不显示**：检查 `pubspec.yaml` 资源声明是否包含 `assets/live2d/models/`；确认 `.model3.json` 内引用的子文件路径与实际一致。
- **桌面端白屏**：Windows 走 `webview_windows`，需确认该平台依赖已正确引入且运行时可用；iOS / Android 走 `webview_flutter`。
- **Web 端异常**：`live2d_webview_stub.dart` 仅为占位，Web 实际渲染仍由 `webview_flutter` 提供的 WebView 完成；若 Web 平台需特殊资源加载逻辑，应在 viewer 内处理相对路径。

返回：[文档中心](./README.md)
