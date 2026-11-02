import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 读取音乐缓存占用的字节数。
///
/// flutter_cache_manager 在移动端/桌面端不会把每个文件的 length 写进缓存记录，
/// 因此 `store.getCacheSize()` 一直是 0；这里直接统计缓存目录下文件的实际大小。
Future<int> readMusicCacheSize() async {
  if (kIsWeb) return 0;
  try {
    final base = await getTemporaryDirectory();
    final dir = Directory(p.join(base.path, DefaultCacheManager.key));
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        try {
          total += await entity.length();
        } catch (_) {
          // 单个文件读不到就跳过
        }
      }
    }
    return total;
  } catch (_) {
    // 目录不可访问时退回缓存管理器的统计（可能为 0）
    try {
      return await DefaultCacheManager().store.getCacheSize();
    } catch (_) {
      return 0;
    }
  }
}
