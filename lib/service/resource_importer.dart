import 'dart:io';

import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import 'external_storage.dart';

/// @ClassName ResourceImporter
/// @Description 在 App 内导入外部资源：把用户从系统文件选择器选中的图片 /
///              模型文件夹复制进应用资源目录，免去手动拷贝路径的操作。
/// @Author richuff
/// @Version 1.0
class ResourceImporter {
  ResourceImporter._();

  /// 导入壁纸：复制成 `<wallpaper>/<slot><原扩展名>`，
  /// 同时清掉同槽位旧文件（含其它扩展名，避免同名双图）。
  static Future<File> importWallpaper(String slot, String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw Exception('选择的文件不存在'.tr);
    }
    final ext = p.extension(sourcePath).toLowerCase();
    final dir = await ExternalStorage.instance.wallpaperDir();

    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! File) continue;
      if (p.basenameWithoutExtension(entity.path).toLowerCase() == slot) {
        try {
          await entity.delete();
        } catch (_) {
          // 删不掉旧文件时忽略，覆盖写入仍然生效
        }
      }
    }

    final target = File(p.join(dir.path, '$slot$ext'));
    await source.copy(target.path);
    return target;
  }

  /// 删除槽位的自定义壁纸，恢复内置默认图。
  static Future<void> resetWallpaper(String slot) async {
    final dir = await ExternalStorage.instance.wallpaperDir();
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! File) continue;
      if (p.basenameWithoutExtension(entity.path).toLowerCase() == slot) {
        try {
          await entity.delete();
        } catch (_) {
          // 已不存在时忽略
        }
      }
    }
  }

  /// 导入 Live2D 模型：把整个文件夹复制到 `<Live2D>/<文件夹名>`，
  /// 同名旧模型会被覆盖。返回导入后的文件夹名（用于自动选中）。
  /// 选择的目录本来就在模型目录里时，直接沿用不复制。
  static Future<String> importLive2dModel(String sourceDirPath) async {
    final source = Directory(sourceDirPath);
    if (!await source.exists()) {
      throw Exception('选择的文件夹不存在'.tr);
    }
    final targetParent = await ExternalStorage.instance.live2dDir();

    final normalized = p.normalize(sourceDirPath);
    // 选的就是模型目录（或模型目录本身在所选目录里面）时，复制会套娃，
    // 直接沿用现有内容重新扫描。
    if (p.equals(normalized, targetParent.path) ||
        p.isWithin(normalized, targetParent.path)) {
      return p.basename(normalized);
    }
    if (p.isWithin(targetParent.path, normalized)) {
      // 已经在模型目录里，扫描即可
      return p.basename(normalized);
    }

    var folderName = p.basename(normalized).trim();
    if (folderName.isEmpty || folderName == p.separator) folderName = 'model';
    folderName = folderName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

    final target = Directory(p.join(targetParent.path, folderName));
    if (await target.exists()) {
      await target.delete(recursive: true);
    }
    await _copyDirectory(source, target, exclude: target.path);
    return folderName;
  }

  static Future<void> _copyDirectory(
    Directory src,
    Directory dst, {
    String? exclude,
  }) async {
    await dst.create(recursive: true);
    await for (final entity in src.list(followLinks: false)) {
      final entityPath = p.normalize(entity.path);
      if (exclude != null &&
          (p.equals(entityPath, exclude) || p.isWithin(entityPath, exclude))) {
        // 跳过目标目录自身，避免复制套娃
        continue;
      }
      final targetPath = p.join(dst.path, p.basename(entity.path));
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(targetPath), exclude: exclude);
      } else if (entity is File) {
        try {
          await entity.copy(targetPath);
        } catch (_) {
          // 单个文件失败不中断整体导入（缓存 / 缩略图等可有可无）
        }
      }
    }
  }
}
