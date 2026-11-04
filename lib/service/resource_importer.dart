import 'dart:io';

import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import 'external_storage.dart';

/// @ClassName ResourceImporter
/// @Description 在 App 内导入外部资源：把用户从系统文件选择器选中的图片 /
///              模型文件夹复制进应用资源目录，免去手动拷贝路径的操作。
/// @Author richuff
/// @Version 1.1
class ResourceImporter {
  ResourceImporter._();

  /// 导入壁纸：复制成 `<wallpaper>/<slot>-<时间戳><原扩展名>`。
  ///
  /// 文件名带时间戳是有意的：图片缓存以「文件路径」为 key，如果一直覆盖
  /// `<slot>.jpg`，换图后很容易读到缓存里的旧图；换成新名字则每次都是新 key，
  /// 既不会显示旧图，也不会因为缓存失效而变成空白。旧文件在复制成功后才清理。
  static Future<File> importWallpaper(String slot, String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw Exception('选择的文件不存在'.tr);
    }
    final ext = p.extension(sourcePath).toLowerCase();
    final dir = await ExternalStorage.instance.wallpaperDir();

    final stamp = DateTime.now().millisecondsSinceEpoch;
    final target = File(p.join(dir.path, '$slot-$stamp$ext'));
    await source.copy(target.path);

    // 复制成功后再删旧文件，避免复制失败时用户原有的壁纸也没了
    await _deleteSlotFiles(dir, slot, keep: target.path);
    return target;
  }

  /// 删除槽位的自定义壁纸，恢复内置默认图。
  static Future<void> resetWallpaper(String slot) async {
    final dir = await ExternalStorage.instance.wallpaperDir();
    await _deleteSlotFiles(dir, slot);
  }

  /// 清掉某个槽位的所有文件（`home.jpg`、`home-1700000000.png` 都算），
  /// 可保留一个刚写入的新文件。
  static Future<void> _deleteSlotFiles(
    Directory dir,
    String slot, {
    String? keep,
  }) async {
    final keepPath = keep == null ? null : p.normalize(keep);
    try {
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is! File) continue;
        if (keepPath != null && p.normalize(entity.path) == keepPath) continue;
        final base = p.basenameWithoutExtension(entity.path).toLowerCase();
        if (base == slot || base.startsWith('$slot-')) {
          try {
            await entity.delete();
          } catch (_) {
            // 删不掉时忽略：新文件已经写入，旧文件残留不影响显示
          }
        }
      }
    } catch (_) {
      // 目录不可读时不阻塞导入流程
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
