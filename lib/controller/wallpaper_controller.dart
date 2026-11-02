import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import '../service/external_storage.dart';
import '../widget/BackGround/back_ground_enum.dart';

/// @ClassName WallpaperController
/// @Description 壁纸源：扫描 <外部目录>/wallpaper 下的图片，按文件名映射到
///              各页面的背景槽位（home / live2d / music / about，或 default 统配）。
///              没有对应文件时回退到内置图，因此删掉文件即可恢复默认。
/// @Author richuff
/// @Version 1.0
class WallpaperController extends GetxController {
  static const Set<String> _extensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.bmp',
  };

  /// slot -> 用户提供的图片文件
  final Map<String, File> _files = <String, File>{};

  String? _directoryPath;
  bool _publicAccess = false;
  bool _loaded = false;
  String? _error;

  /// 每次刷新自增，界面可以拿它做 key 让图片重新解码
  int revision = 0;

  bool get loaded => _loaded;

  String? get error => _error;

  /// 壁纸目录的绝对路径（供设置页展示 / 复制）
  String? get directoryPath => _directoryPath;

  /// 是否拿到了公共目录（否则是应用私有目录）
  bool get publicAccess => _publicAccess;

  /// 外部目录里一共有几张可识别的图片
  int get fileCount => _files.values.toSet().length;

  @override
  void onInit() {
    super.onInit();
    refresh();
  }

  /// 重新扫描壁纸目录；文件增删后调用即可立即生效
  @override
  Future<void> refresh() async {
    try {
      final storage = ExternalStorage.instance;
      final dir = await storage.wallpaperDir();
      _directoryPath = dir.path;
      _publicAccess = storage.publicAccess;

      final found = <String, File>{};
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is! File) continue;
        final extension = p.extension(entity.path).toLowerCase();
        if (!_extensions.contains(extension)) continue;
        final name = p.basenameWithoutExtension(entity.path).toLowerCase();
        // 同名多扩展名时按扩展名优先级取第一个（jpg 先于 png）
        found.putIfAbsent(name, () => entity);
      }

      _files.clear();
      for (final slot in BackGroundEnum.values) {
        final file = found[slot.slot] ?? found['default'];
        if (file != null) _files[slot.slot] = file;
      }

      // 同名文件换了内容也要立刻看到新图，先清掉图片缓存
      for (final file in _files.values) {
        FileImage(file).evict();
      }

      revision++;
      _error = null;
      _loaded = true;
      update();
    } catch (error) {
      _error = '$error';
      _loaded = true;
      update();
    }
  }

  /// 申请公共目录权限，成功后重新扫描
  Future<bool> requestAccess() async {
    final granted = await ExternalStorage.instance.requestPublicAccess();
    await refresh();
    return granted;
  }

  /// 当前槽位使用的自定义图片，没有则返回 null
  File? fileFor(String slot) => _files[slot];

  ImageProvider? customImage(String slot) {
    final file = _files[slot];
    if (file == null) return null;
    return FileImage(file);
  }

  bool hasCustom(String slot) => _files.containsKey(slot);
}
