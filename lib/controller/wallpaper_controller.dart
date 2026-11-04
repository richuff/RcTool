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

      // 同一槽位可能有多张（手动放的 home.jpg + 导入的 home-1700000000.jpg），
      // 一律取最新那张；空文件（复制中断留下的残片）直接跳过。
      final candidates = <MapEntry<String, DateTime>>[];
      final filesByName = <String, File>{};
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is! File) continue;
        if (!isSupportedFile(entity.path)) continue;
        final name = p.basenameWithoutExtension(entity.path).toLowerCase();
        if (slotOfFile(name) == null) continue;

        final stat = await entity.stat();
        if (stat.size <= 0) continue;
        candidates.add(MapEntry(name, stat.modified));
        filesByName[name] = entity;
      }

      final chosen = pickSlots(candidates);
      _files.clear();
      for (final slot in BackGroundEnum.values) {
        final name = chosen[slot.slot] ?? chosen['default'];
        final file = name == null ? null : filesByName[name];
        if (file != null) _files[slot.slot] = file;
      }

      revision++;
      _error = null;
      _loaded = true;
      update();
    } catch (error) {
      // 扫描失败保留上一次的壁纸，不要因为一次读取异常就变回内置图
      _error = '$error';
      _loaded = true;
      update();
    }
  }

  /// 是否是可用的壁纸文件（按扩展名判断）
  static bool isSupportedFile(String fileName) {
    return _extensions.contains(p.extension(fileName).toLowerCase());
  }

  /// 每个槽位挑最新的一张：入参是「文件名（不含扩展名，小写）+ 修改时间」，
  /// 返回 槽位 -> 选中的文件名。抽成纯函数方便单测。
  static Map<String, String> pickSlots(
    Iterable<MapEntry<String, DateTime>> entries,
  ) {
    final best = <String, MapEntry<String, DateTime>>{};
    for (final entry in entries) {
      final slot = slotOfFile(entry.key);
      if (slot == null) continue;
      final previous = best[slot];
      if (previous == null || entry.value.isAfter(previous.value)) {
        best[slot] = entry;
      }
    }
    return best.map((slot, entry) => MapEntry(slot, entry.key));
  }

  /// 文件名对应的槽位：`home.jpg` 与 `home-1700000000.png` 都属于 home，
  /// `default` 作为四个页面统一兜底。
  static String? slotOfFile(String baseName) {
    for (final slot in BackGroundEnum.values) {
      if (baseName == slot.slot || baseName.startsWith('${slot.slot}-')) {
        return slot.slot;
      }
    }
    if (baseName == 'default' || baseName.startsWith('default-')) {
      return 'default';
    }
    return null;
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
    // 文件被外部删除 / 存储被移除时直接回退内置图，避免解码失败画出空白
    if (!file.existsSync()) return null;
    return FileImage(file);
  }

  bool hasCustom(String slot) => _files.containsKey(slot);
}
