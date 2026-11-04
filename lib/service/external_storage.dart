import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// @ClassName ExternalStorage
/// @Description 应用的外部资源根目录：壁纸与 Live2D 模型都从这里读取。
///
///   - Android：优先 `/storage/emulated/0/RcTool`（需要「所有文件访问权限」，
///     这个目录用数据线 / 文件管理器都能直接看到）；
///     未授权时退到应用专属外部目录 `/storage/emulated/0/Android/data/<包名>/files/RcTool`。
///   - 桌面端：`<文档>/RcTool`。
///
/// 解析结果会写进 SharedPreferences：目录一旦选定就固定下来，不会因为权限
/// 状态的瞬时抖动而在「公共目录 / 应用私有目录」之间来回切换——切换会让之前
/// 导入的壁纸凭空消失。授权成功后会把旧目录里的壁纸迁移过去，内容不丢。
/// @Author richuff
/// @Version 1.1
class ExternalStorage {
  ExternalStorage._();

  static final ExternalStorage instance = ExternalStorage._();

  /// 根目录名，出现在路径里，改动会改变用户的既有目录
  static const String rootFolderName = 'RcTool';

  /// 壁纸子目录
  static const String wallpaperFolderName = 'wallpaper';

  /// Live2D 模型子目录
  static const String live2dFolderName = 'Live2D';

  /// 已解析根目录的持久化 key
  static const String _rootKey = 'external_storage_root';

  Directory? _root;

  /// 主动 reset 后忽略已保存的目录，强制重新解析（授权 / 目录被删后调用）
  bool _ignoreSavedRoot = false;

  /// 是否拿到了公共目录（否则是应用私有目录）
  bool _publicAccess = false;

  bool get publicAccess => _publicAccess;

  /// 清理缓存，下次强制重新解析目录
  void reset() {
    _root = null;
    _publicAccess = false;
    _ignoreSavedRoot = true;
  }

  /// 根目录，不存在时会创建
  Future<Directory> root() async {
    final cached = _root;
    if (cached != null) return cached;

    final dir = await _restoreOrResolveRoot();
    try {
      await dir.create(recursive: true);
    } catch (_) {
      // 目录不可写时仍然返回，由调用方按空目录处理
    }
    _root = dir;
    return dir;
  }

  /// 优先沿用上一次解析成功的目录（只要它还在），其次重新解析
  Future<Directory> _restoreOrResolveRoot() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = _ignoreSavedRoot ? null : prefs.getString(_rootKey);
    if (saved != null && saved.isNotEmpty) {
      final dir = Directory(saved);
      try {
        if (await dir.exists() && await _canList(dir)) {
          _publicAccess = !_isAppPrivatePath(saved);
          return dir;
        }
      } catch (_) {
        // 路径失效 / 权限被收回，重新解析
      }
    }
    _ignoreSavedRoot = false;
    final dir = await _resolveRoot();
    await prefs.setString(_rootKey, dir.path);
    return dir;
  }

  /// 目录是否还能读：权限被收回时 list 会抛异常，此时要重新解析目录
  Future<bool> _canList(Directory dir) async {
    try {
      await for (final _ in dir.list(followLinks: false)) {
        break;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 应用私有路径（外部私有目录 / 内部存储），这类目录不需要「所有文件访问权限」
  bool _isAppPrivatePath(String path) {
    final normalized = p.normalize(path);
    return normalized.contains('${p.separator}Android${p.separator}data')
        ? true
        : normalized.startsWith('${p.separator}data${p.separator}');
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
    try {
      await dir.create(recursive: true);
    } catch (_) {
      // 创建失败时返回路径，读取端会按空目录处理
    }
    return dir;
  }

  /// Live2D 模型目录
  Future<Directory> live2dDir() async {
    final dir = Directory(p.join((await root()).path, live2dFolderName));
    try {
      await dir.create(recursive: true);
    } catch (_) {
      // 同上
    }
    return dir;
  }

  /// 申请公共目录访问权限（Android 会跳到系统设置页）。
  /// 目录因此发生变化时，把旧目录里的壁纸搬到新目录，用户不会丢图。
  Future<bool> requestPublicAccess() async {
    if (!Platform.isAndroid) return true;
    final previous = _root;
    final status = await Permission.manageExternalStorage.request();

    reset();
    final dir = await root();
    if (previous != null &&
        p.normalize(previous.path) != p.normalize(dir.path)) {
      await _migrateWallpapers(previous, dir);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rootKey, dir.path);
    return status.isGranted;
  }

  /// 把旧根目录下的壁纸复制到新根目录（同名覆盖），换目录不丢图
  Future<void> _migrateWallpapers(Directory fromRoot, Directory toRoot) async {
    try {
      final from = Directory(p.join(fromRoot.path, wallpaperFolderName));
      if (!await from.exists()) return;
      final to = Directory(p.join(toRoot.path, wallpaperFolderName));
      await to.create(recursive: true);
      await for (final entity in from.list(followLinks: false)) {
        if (entity is! File) continue;
        final target = p.join(to.path, p.basename(entity.path));
        if (await File(target).exists()) continue;
        try {
          await entity.copy(target);
        } catch (_) {
          // 单张失败不影响其他壁纸
        }
      }
    } catch (_) {
      // 迁移失败不阻塞授权流程
    }
  }

  /// 当前是否已拿到公共目录权限
  Future<bool> hasPublicAccess() async {
    if (!Platform.isAndroid) return true;
    return Permission.manageExternalStorage.isGranted;
  }
}
