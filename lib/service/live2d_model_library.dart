import 'dart:io';

import 'package:path/path.dart' as p;

import '../service/external_storage.dart';

/// @ClassName Live2DModelEntry
/// @Description 一个可加载的 Live2D 模型：内置 Haru 或外部目录里扫描到的模型。
/// @Author richuff
/// @Version 1.0
class Live2DModelEntry {
  /// 持久化用的稳定标识（不含端口号，重启后依然有效）
  final String id;

  /// 展示名，取自 `xxx.model3.json` 的文件名
  final String name;

  /// 相对站点根目录的地址，交给 WebView 的 `?model=` 使用
  final String modelPath;

  /// 是否随包内置
  final bool builtIn;

  /// 模型所在的绝对目录（外部模型用于展示）
  final String? directory;

  const Live2DModelEntry({
    required this.id,
    required this.name,
    required this.modelPath,
    required this.builtIn,
    this.directory,
  });
}

/// @ClassName Live2DModelLibrary
/// @Description 扫描 `<外部目录>/Live2D` 下所有 `*.model3.json`，
///              自动生成可切换的模型列表；内置 Haru 永远排在第一个兜底。
/// @Author richuff
/// @Version 1.0
class Live2DModelLibrary {
  Live2DModelLibrary._();

  static const String builtInId = 'builtin:haru';

  static const Live2DModelEntry builtIn = Live2DModelEntry(
    id: builtInId,
    name: 'Haru',
    modelPath: '/assets/live2d/models/Haru/Haru.model3.json',
    builtIn: true,
  );

  /// 外部模型目录的绝对路径（供界面提示）
  static Future<String> directoryPath() async {
    try {
      return (await ExternalStorage.instance.live2dDir()).path;
    } catch (_) {
      return '';
    }
  }

  /// 扫描模型；不会抛异常，目录不可读时只返回内置模型
  static Future<List<Live2DModelEntry>> scan() async {
    final entries = <Live2DModelEntry>[builtIn];

    Directory dir;
    try {
      dir = await ExternalStorage.instance.live2dDir();
    } catch (_) {
      return entries;
    }

    final files = <File>[];
    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        if (!entity.path.toLowerCase().endsWith('.model3.json')) continue;
        final relative = p.relative(entity.path, from: dir.path);
        // 跳过隐藏目录与卸载残留
        if (relative
            .split(p.separator)
            .any((segment) => segment.startsWith('.'))) {
          continue;
        }
        files.add(entity);
      }
    } catch (_) {
      return entries;
    }

    files.sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
    for (final file in files) {
      final relative = p.relative(file.path, from: dir.path);
      // id 统一用 '/'，Windows 下的 '\' 会让 URL 与持久化 id 对不上
      final normalized = relative.split(p.separator).join('/');
      final encoded = normalized.split('/').map(Uri.encodeComponent).join('/');
      entries.add(
        Live2DModelEntry(
          id: 'ext:$normalized',
          name: _displayName(file.path),
          modelPath: '/ext/$encoded',
          builtIn: false,
          directory: file.parent.path,
        ),
      );
    }
    return entries;
  }

  /// `Haru.model3.json` → `Haru`；取不到文件名时退回所在目录名
  static String _displayName(String path) {
    const suffix = '.model3.json';
    var base = p.basename(path);
    if (base.toLowerCase().endsWith(suffix)) {
      base = base.substring(0, base.length - suffix.length);
    }
    if (base.trim().isEmpty) base = p.basename(p.dirname(path));
    return base;
  }

  /// 由持久化的 id 直接还原出模型地址，避免首帧先加载内置模型再切换。
  static Live2DModelEntry entryFromId(String id) {
    if (id == builtInId || !id.startsWith('ext:')) return builtIn;
    final relative = id.substring(4);
    final encoded = relative.split('/').map(Uri.encodeComponent).join('/');
    return Live2DModelEntry(
      id: id,
      name: _displayName(relative),
      modelPath: '/ext/$encoded',
      builtIn: false,
    );
  }

  /// 按 id 找模型，找不到时回退到内置模型
  static Live2DModelEntry resolve(
    List<Live2DModelEntry> all,
    String? id,
  ) {
    if (all.isEmpty) return builtIn;
    for (final entry in all) {
      if (entry.id == id) return entry;
    }
    return all.first;
  }
}
