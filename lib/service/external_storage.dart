import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// @ClassName ExternalStorage
/// @Description 应用的外部资源根目录：壁纸与 Live2D 模型都从这里读取，
///              用户只要把文件丢进对应子目录、在应用里刷新一次即可生效，
///              不必重新打包 APK。
///
///   - Android：优先 `/storage/emulated/0/RcTool`（需要「所有文件访问权限」，
///     这个目录用数据线 / 文件管理器都能直接看到）；
///     未授权时退到应用专属外部目录 `/storage/emulated/0/Android/data/<包名>/files/RcTool`，
///     同样可用，只是系统文件管理器不一定能进去。
///   - 桌面端：`<文档>/RcTool`。
///
/// @Author richuff
/// @Version 1.0
class ExternalStorage {
  ExternalStorage._();

  static final ExternalStorage instance = ExternalStorage._();

  /// 根目录名，出现在路径里，改动会改变用户的既有目录
  static const String rootFolderName = 'RcTool';

  /// 壁纸子目录
  static const String wallpaperFolderName = 'wallpaper';

  /// Live2D 模型子目录
  static const String live2dFolderName = 'Live2D';

  Directory? _root;

  /// 是否拿到了公共目录（否则是应用私有目录）
  bool _publicAccess = false;

  bool get publicAccess => _publicAccess;

  /// 清理缓存，下次重新解析目录（授权 / 目录被删后调用）
  void reset() {
    _root = null;
    _publicAccess = false;
  }

  /// 根目录，不存在时会创建
  Future<Directory> root() async {
    final cached = _root;
    if (cached != null) return cached;

    final dir = await _resolveRoot();
    await dir.create(recursive: true);
    _root = dir;
    return dir;
  }

  Future<Directory> _resolveRoot() async {
    if (Platform.isAndroid) return _resolveAndroidRoot();
    final documents = await getApplicationDocumentsDirectory();
    return Directory(p.join(documents.path, rootFolderName));
  }

  Future<Directory> _resolveAndroidRoot() async {
    _publicAccess = false;
    // 有「所有文件访问权限」时优先用公共目录，用户最容易往里面放东西
    if (await Permission.manageExternalStorage.isGranted) {
      final publicDir = Directory('/storage/emulated/0/$rootFolderName');
      try {
        await publicDir.create(recursive: true);
        _publicAccess = true;
        return publicDir;
      } catch (_) {
        // 部分机型即便授权也写不进公共目录，继续走应用专属目录
      }
    }

    final external = await getExternalStorageDirectory();
    final base = external ?? await getApplicationDocumentsDirectory();
    return Directory(p.join(base.path, rootFolderName));
  }

  /// 壁纸目录
  Future<Directory> wallpaperDir() async {
    final dir = Directory(p.join((await root()).path, wallpaperFolderName));
    await dir.create(recursive: true);
    return dir;
  }

  /// Live2D 模型目录
  Future<Directory> live2dDir() async {
    final dir = Directory(p.join((await root()).path, live2dFolderName));
    await dir.create(recursive: true);
    return dir;
  }

  /// 申请公共目录访问权限（Android 会跳到系统设置页）
  Future<bool> requestPublicAccess() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.manageExternalStorage.request();
    reset();
    return status.isGranted;
  }

  /// 当前是否已拿到公共目录权限
  Future<bool> hasPublicAccess() async {
    if (!Platform.isAndroid) return true;
    return Permission.manageExternalStorage.isGranted;
  }
}
