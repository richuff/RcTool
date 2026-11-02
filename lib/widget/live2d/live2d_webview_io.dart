import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart' as system_webview;
import 'package:webview_windows/webview_windows.dart' as windows_webview;

import 'live2d_asset_server.dart';

/// @ClassName Live2DWebView
/// @Description Live2D 展示容器。资源统一由本机 HTTP 服务提供（避免 file:// 下的
///             跨源限制导致模型加载失败），并通过 JS 桥把「加载中 / 就绪 / 失败」
///             状态回传给 Flutter，页面因此能显示真实进度与重试入口。
/// @Author richuff
/// @Version 2.0
class Live2DWebView extends StatefulWidget {
  final String assetPath;

  /// 模型缩放倍率（1 表示完整贴合画面），由页面滑块控制。
  final double zoom;

  const Live2DWebView({
    super.key,
    required this.assetPath,
    this.zoom = 1.0,
  });

  @override
  State<Live2DWebView> createState() => _Live2DWebViewState();
}

class _Live2DWebViewState extends State<Live2DWebView> {
  static const String _bridgeName = 'RcLive2DBridge';
  static const Duration _loadTimeout = Duration(seconds: 35);

  system_webview.WebViewController? _systemController;
  windows_webview.WebviewController? _windowsController;
  StreamSubscription<dynamic>? _windowsMessageSub;
  Timer? _timeoutTimer;

  bool _ready = false;
  String? _error;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _startTimeout();
    _initWebView();
  }

  @override
  void didUpdateWidget(covariant Live2DWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.zoom != widget.zoom) {
      _applyZoom();
    }
  }

  /// 把缩放值推给页面脚本；页面尚未加载完成时静默忽略，
  /// 加载完成后会在 ready 回调里再同步一次。
  Future<void> _applyZoom() async {
    final value = widget.zoom.toStringAsFixed(3);
    await _runJavaScript(
      'window.live2dBridge && window.live2dBridge.setZoom($value);',
    );
  }

  Future<void> _runJavaScript(String script) async {
    try {
      final windowsController = _windowsController;
      if (windowsController != null) {
        await windowsController.executeScript(script);
        return;
      }
      await _systemController?.runJavaScript(script);
    } catch (_) {
      // 页面还没就绪时执行失败属正常，ready 后会补一次
    }
  }

  void _startTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(_loadTimeout, () {
      if (!mounted || _ready) return;
      setState(() {
        _error = '模型加载超时，请检查网络或点击重试。';
      });
    });
  }

  Future<void> _initWebView() async {
    try {
      if (Platform.isWindows) {
        await _initWindowsWebView();
        return;
      }
      if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
        await _initSystemWebView();
        return;
      }
      if (!mounted) return;
      setState(() {
        _error = '当前平台暂不支持 Live2D 展示。';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Live2D 初始化失败：$error';
      });
    }
  }

  /// 由本地资源服务提供的页面地址，例如
  /// http://127.0.0.1:53219/assets/live2d/viewer/index.html
  Future<Uri> _viewerUri() async {
    final port = await Live2DAssetServer.instance.ensureStarted();
    return Uri.parse('http://127.0.0.1:$port/${widget.assetPath}');
  }

  Future<void> _initSystemWebView() async {
    final uri = await _viewerUri();

    final controller = system_webview.WebViewController()
      ..setJavaScriptMode(system_webview.JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        _bridgeName,
        onMessageReceived: (message) => _handleBridgeMessage(message.message),
      )
      ..setNavigationDelegate(
        system_webview.NavigationDelegate(
          onProgress: (progress) {
            if (!mounted || _ready) return;
            setState(() {
              _progress = (progress / 100).clamp(0.0, 1.0);
            });
          },
          onPageFinished: (_) {
            if (!mounted || _ready) return;
            // 页面加载完成只代表资源到位，模型是否渲染成功以 JS 桥消息为准。
            setState(() => _progress = 1);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == false) return;
            if (!mounted) return;
            setState(() {
              _error = '页面加载失败：${error.description}';
            });
          },
        ),
      );

    if (!mounted) return;
    setState(() => _systemController = controller);

    await controller.loadRequest(uri);
  }

  Future<void> _initWindowsWebView() async {
    final version = await windows_webview.WebviewController.getWebViewVersion();
    if (version == null) {
      if (!mounted) return;
      setState(() {
        _error = '需要安装 Microsoft Edge WebView2 Runtime 才能显示 Live2D。';
      });
      return;
    }

    final uri = await _viewerUri();
    final controller = windows_webview.WebviewController();
    await controller.initialize();
    await controller.setBackgroundColor(Colors.transparent);
    await controller.setPopupWindowPolicy(
      windows_webview.WebviewPopupWindowPolicy.deny,
    );
    await controller.addScriptToExecuteOnDocumentCreated(
      'window.__rcWindowsHost = true;',
    );

    _windowsMessageSub = controller.webMessage.listen(_handleBridgeMessage);

    await controller.loadUrl(uri.toString());

    if (!mounted) {
      unawaited(controller.dispose());
      return;
    }
    setState(() => _windowsController = controller);
  }

  /// 解析来自页面脚本的状态消息：{type: ready|error|progress, message, value}
  void _handleBridgeMessage(dynamic data) {
    Map<String, dynamic>? payload;
    if (data is Map) {
      payload = data.map((key, value) => MapEntry('$key', value));
    } else if (data is String && data.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) {
          payload = decoded.map((key, value) => MapEntry('$key', value));
        }
      } catch (_) {
        payload = {'type': 'log', 'message': data};
      }
    }
    if (payload == null || !mounted) return;
    final message = payload;

    switch (message['type']) {
      case 'ready':
        _timeoutTimer?.cancel();
        setState(() {
          _ready = true;
          _error = null;
          _progress = 1;
        });
        // 模型就绪后再同步一次缩放，避免冷启动时滑块值丢失
        _applyZoom();
        break;
      case 'error':
        _timeoutTimer?.cancel();
        setState(() {
          _error = '${message['message'] ?? 'Live2D 模型加载失败'}';
        });
        break;
      case 'progress':
        final value = message['value'];
        if (value is num) {
          setState(() => _progress = (value / 100).clamp(0.0, 1.0));
        }
        break;
      default:
        break;
    }
  }

  Future<void> _retry() async {
    setState(() {
      _error = null;
      _ready = false;
      _progress = 0;
    });
    _startTimeout();

    try {
      final uri = await _viewerUri();
      final windowsController = _windowsController;
      if (windowsController != null) {
        await windowsController.loadUrl(uri.toString());
        return;
      }
      await _systemController?.loadRequest(uri);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '重试失败：$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildWebView(),
        if (!_ready)
          _Live2DOverlay(
            error: _error,
            progress: _progress,
            onRetry: _retry,
          ),
      ],
    );
  }

  Widget _buildWebView() {
    if (Platform.isWindows) {
      final controller = _windowsController;
      if (controller == null) return const SizedBox.shrink();
      return windows_webview.Webview(controller);
    }
    final controller = _systemController;
    if (controller == null) return const SizedBox.shrink();
    return system_webview.WebViewWidget(controller: controller);
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _windowsMessageSub?.cancel();
    final controller = _windowsController;
    if (controller != null) {
      unawaited(controller.dispose());
    }
    super.dispose();
  }
}

/// 加载 / 失败浮层：与页面其余卡片同风格，默认状态下不遮挡交互。
class _Live2DOverlay extends StatelessWidget {
  final String? error;
  final double progress;
  final VoidCallback onRetry;

  const _Live2DOverlay({
    required this.error,
    required this.progress,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isError = error != null;

    // 加载中挡住底层 WebView 的点击；失败时要放行，否则「重新加载」按钮点不动
    return AbsorbPointer(
      absorbing: !isError,
      child: Container(
        color: scheme.surface.withOpacity(0.92),
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primaryContainer,
                      scheme.secondaryContainer,
                    ],
                  ),
                ),
                child: Center(
                  child: isError
                      ? Icon(Icons.sentiment_dissatisfied_rounded,
                          size: 32, color: scheme.onPrimaryContainer)
                      : SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.6,
                            value: progress > 0 && progress < 1
                                ? progress
                                : null,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(scheme.primary),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isError ? 'Haru 没能加载出来' : '正在唤醒 Haru',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isError
                    ? error!
                    : '首次加载需要解码约 4MB 模型资源，请稍候…',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              if (isError)
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('重新加载'),
                )
              else
                SizedBox(
                  width: 150,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress > 0 && progress < 1 ? progress : null,
                      minHeight: 4,
                      backgroundColor: scheme.surfaceContainerHighest,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(scheme.primary),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
