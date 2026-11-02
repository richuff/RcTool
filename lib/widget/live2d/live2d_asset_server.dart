import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../../service/external_storage.dart';

/// @ClassName Live2DAssetServer
/// @Description 本机静态资源服务：把 Flutter asset 以 http://127.0.0.1:<port>/ 暴露出去。
///
///   Live2D 的模型加载依赖 XHR/fetch 读取 .model3.json、.moc3 与贴图。
///   直接用 `loadFlutterAsset` 打开的是 `file://` 页面，WebView 默认禁止
///   file 协议下的跨源请求（CORS），模型因此永远加载不出来。
///   起一个仅监听回环地址的本地 HTTP 服务即可绕过该限制，
///   同时桌面端也不必再拼 assets 的物理路径。
///
/// @Author richuff
/// @Version 1.0
class Live2DAssetServer {
  Live2DAssetServer._();

  static final Live2DAssetServer instance = Live2DAssetServer._();

  HttpServer? _server;
  Future<int>? _starting;

  /// 服务端口；未启动时返回 null。
  int? get port => _server?.port;

  /// 确保服务已启动并返回端口号。
  Future<int> ensureStarted() {
    final running = _server;
    if (running != null) return Future.value(running.port);
    return _starting ??= _start();
  }

  Future<int> _start() async {
    try {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen(_handleRequest);
      _server = server;
      return server.port;
    } catch (_) {
      _starting = null;
      rethrow;
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final response = request.response;
    try {
      var path = request.uri.path;
      if (path.isEmpty || path == '/') {
        path = '/assets/live2d/viewer/index.html';
      }

      // 外部模型目录：/ext/<相对路径>，直接读磁盘，无需重新打包
      if (path.startsWith('/ext/')) {
        await _serveExternal(request, response, path.substring('/ext/'.length));
        return;
      }

      // 去掉开头的 '/' 就是 Flutter asset 的 key
      final assetKey = path.startsWith('/') ? path.substring(1) : path;

      final data = await rootBundle.load(assetKey);
      final bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      response.headers.set('Content-Type', _mimeType(assetKey));
      response.headers.set('Access-Control-Allow-Origin', '*');
      response.headers.set('Cache-Control', 'max-age=86400');
      response.headers.contentLength = bytes.length;
      response.add(bytes);
    } catch (_) {
      response.statusCode = HttpStatus.notFound;
    } finally {
      await response.close();
    }
  }

  /// 输出外部模型目录里的文件（模型 json / moc3 / 贴图 / 音频）。
  Future<void> _serveExternal(
    HttpRequest request,
    HttpResponse response,
    String relative,
  ) async {
    final root = await ExternalStorage.instance.live2dDir();
    final target = p.normalize(p.join(root.path, relative));
    // 防止 ../ 跳出模型目录
    if (!p.isWithin(root.path, target)) {
      response.statusCode = HttpStatus.forbidden;
      return;
    }
    final file = File(target);
    if (!await file.exists()) {
      response.statusCode = HttpStatus.notFound;
      return;
    }

    response.headers.set('Content-Type', _mimeType(target));
    response.headers.set('Access-Control-Allow-Origin', '*');
    // 模型文件允许用户随时替换，禁止缓存旧内容
    response.headers.set('Cache-Control', 'no-store');
    response.contentLength = await file.length();
    await response.addStream(file.openRead());
  }

  static String _mimeType(String key) {
    final lower = key.toLowerCase();
    if (lower.endsWith('.html') || lower.endsWith('.htm')) {
      return 'text/html; charset=utf-8';
    }
    if (lower.endsWith('.js')) return 'application/javascript; charset=utf-8';
    if (lower.endsWith('.css')) return 'text/css; charset=utf-8';
    if (lower.endsWith('.json')) return 'application/json; charset=utf-8';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.svg')) return 'image/svg+xml';
    return 'application/octet-stream';
  }

  /// 关闭服务（页面销毁时调用）。
  Future<void> dispose() async {
    _starting = null;
    final server = _server;
    _server = null;
    await server?.close(force: true);
  }
}
