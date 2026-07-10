import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart' as system_webview;
import 'package:webview_windows/webview_windows.dart' as windows_webview;

class Live2DWebView extends StatefulWidget {
  final String assetPath;

  const Live2DWebView({
    super.key,
    required this.assetPath,
  });

  @override
  State<Live2DWebView> createState() => _Live2DWebViewState();
}

class _Live2DWebViewState extends State<Live2DWebView> {
  system_webview.WebViewController? _systemController;
  windows_webview.WebviewController? _windowsController;
  String? _error;
  int _loadingProgress = 0;
  bool _windowsReady = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
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
      _error = 'Live2D WebView is not supported on this platform yet.';
    });
  }

  Future<void> _initSystemWebView() async {
    final controller = system_webview.WebViewController()
      ..setJavaScriptMode(system_webview.JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        system_webview.NavigationDelegate(
          onProgress: (progress) {
            if (!mounted) return;
            setState(() {
              _loadingProgress = progress;
            });
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            setState(() {
              _error = error.description;
            });
          },
        ),
      );

    if (!mounted) return;
    setState(() {
      _systemController = controller;
    });

    await controller.loadFlutterAsset(widget.assetPath);
  }

  Future<void> _initWindowsWebView() async {
    try {
      final version =
          await windows_webview.WebviewController.getWebViewVersion();
      if (version == null) {
        if (!mounted) return;
        setState(() {
          _error =
              'Microsoft Edge WebView2 Runtime is required to show Live2D on Windows.';
        });
        return;
      }

      final controller = windows_webview.WebviewController();
      await controller.initialize();
      await controller.setBackgroundColor(Colors.transparent);
      await controller.setPopupWindowPolicy(
        windows_webview.WebviewPopupWindowPolicy.deny,
      );

      final htmlPath = File(widget.assetPath).absolute.uri.toString();
      await controller.loadUrl(htmlPath);

      if (!mounted) {
        unawaited(controller.dispose());
        return;
      }
      setState(() {
        _windowsController = controller;
        _windowsReady = true;
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message ?? error.code;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _Live2DMessage(message: _error!);
    }

    if (Platform.isWindows) {
      if (!_windowsReady || _windowsController == null) {
        return const _Live2DLoading();
      }
      return windows_webview.Webview(_windowsController!);
    }

    final controller = _systemController;
    if (controller == null) {
      return const _Live2DLoading();
    }

    return Stack(
      children: [
        system_webview.WebViewWidget(controller: controller),
        if (_loadingProgress > 0 && _loadingProgress < 100)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: LinearProgressIndicator(value: _loadingProgress / 100),
          ),
      ],
    );
  }

  @override
  void dispose() {
    final controller = _windowsController;
    if (controller != null) {
      unawaited(controller.dispose());
    }
    super.dispose();
  }
}

class _Live2DLoading extends StatelessWidget {
  const _Live2DLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _Live2DMessage extends StatelessWidget {
  final String message;

  const _Live2DMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
