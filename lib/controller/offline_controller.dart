import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../feature/theme/type_value.dart';
import '../repository/SqlLiteConn/music_conn.dart';
import '../repository/entity/Music.dart';
import '../utils/cache_size.dart';
import '../utils/size_format.dart';

/// 一条离线记录：歌曲 + 本地文件大小
class OfflineEntry {
  final Music music;
  final int bytes;

  const OfflineEntry(this.music, this.bytes);
}

/// @ClassName OfflineController
/// @Description 离线缓存管理：维护「哪些歌已下载到本地」、单曲下载 / 删除、
///              缓存上限与超限自动清理（按下载时间清理最旧的音频）。
///              音频与封面共用 DefaultCacheManager，因此上限只统计音频文件。
/// @Author richuff
/// @Version 1.0
class OfflineController extends GetxController {
  /// 已缓存的音频 url
  final RxSet<String> cachedUrls = <String>{}.obs;

  /// 正在下载的音频 url
  final RxSet<String> downloadingUrls = <String>{}.obs;

  /// 已缓存音频的总字节数
  final RxInt totalBytes = 0.obs;

  /// 缓存上限（字节），0 表示不限
  final RxInt limitBytes = 0.obs;

  final DefaultCacheManager cacheManager = DefaultCacheManager();

  final Map<String, int> _sizes = {};
  final Map<String, int> _stamps = {};

  @override
  void onInit() {
    super.onInit();
    init();
  }

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      limitBytes.value = prefs.getInt(cacheLimitKey) ?? 0;
    } catch (_) {
      // 读不到设置就按「不限」处理
    }
    await reload();
    await enforceLimit();
  }

  bool isCached(String url) => cachedUrls.contains(url);
  bool isDownloading(String url) => downloadingUrls.contains(url);

  /// 播放时顺带把刚落到缓存里的歌曲标记为「已离线」，省掉一次全量刷新
  Future<void> markCached(String url) async {
    if (url.isEmpty || cachedUrls.contains(url)) return;
    try {
      final info = await cacheManager.getFileFromCache(url);
      if (info == null) return;
      final file = info.file;
      if (!await file.exists()) return;
      _sizes[url] = await file.length();
      _stamps[url] = (await file.stat()).modified.millisecondsSinceEpoch;
      cachedUrls.add(url);
      totalBytes.value = _sizes.values.fold(0, (sum, value) => sum + value);
      update();
    } catch (_) {
      // 标记失败不影响播放
    }
  }

  int sizeOf(String url) => _sizes[url] ?? 0;

  bool get hasLimit => limitBytes.value > 0;

  String get totalLabel => formatBytes(totalBytes.value);

  String get limitLabel =>
      hasLimit ? formatBytes(limitBytes.value) : '不限'.tr;

  /// 重新统计缓存状态。会顺带检查文件是否真实存在：
  /// 手动清理过缓存目录后不会留下「已缓存」的假象。
  Future<void> reload({List<Music>? extra}) async {
    List<Music> musics;
    try {
      musics = await MusicConn.queryAll();
    } catch (_) {
      musics = [];
    }
    final urls = <String>{
      for (final music in [...musics, ...?extra])
        if (music.url.isNotEmpty) music.url,
    };

    final cached = <String>{};
    final sizes = <String, int>{};
    final stamps = <String, int>{};
    for (final url in urls) {
      try {
        final info = await cacheManager.getFileFromCache(url);
        if (info == null) continue;
        final file = info.file;
        if (!await file.exists()) continue;
        cached.add(url);
        sizes[url] = await file.length();
        stamps[url] = (await file.stat()).modified.millisecondsSinceEpoch;
      } catch (_) {
        // 单条读取失败忽略，不影响其它歌曲
      }
    }

    _sizes
      ..clear()
      ..addAll(sizes);
    _stamps
      ..clear()
      ..addAll(stamps);
    cachedUrls
      ..clear()
      ..addAll(cached);
    totalBytes.value = sizes.values.fold(0, (sum, value) => sum + value);
    update();
  }

  /// 仅按已知曲库生成离线列表，按占用从大到小排列
  Future<List<OfflineEntry>> entries() async {
    await reload();
    List<Music> musics;
    try {
      musics = await MusicConn.queryAll();
    } catch (_) {
      musics = [];
    }
    final list = <OfflineEntry>[
      for (final music in musics)
        if (isCached(music.url)) OfflineEntry(music, sizeOf(music.url)),
    ];
    list.sort((a, b) => b.bytes.compareTo(a.bytes));
    return list;
  }

  /// 下载单曲到本地（已缓存则直接返回）
  Future<bool> download(Music music) async {
    final url = music.url;
    if (url.isEmpty || downloadingUrls.contains(url)) return false;
    if (isCached(url)) return true;

    downloadingUrls.add(url);
    update();
    Get.snackbar(
      '开始下载'.tr,
      '@name 正在后台下载，完成后会提示你'.trParams({'name': music.songName}),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
    try {
      await cacheManager.downloadFile(url);
      await reload(extra: [music]);
      await enforceLimit();
      Get.snackbar(
        '已下载到本地'.tr,
        '@name 可以离线收听了'.trParams({'name': music.songName}),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return true;
    } catch (error) {
      Get.snackbar(
        '下载失败'.tr,
        '@name 下载失败，请检查网络后重试'.trParams({'name': music.songName}),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      downloadingUrls.remove(url);
      update();
    }
  }

  /// 删除单曲的离线文件
  Future<void> removeOffline(Music music) async {
    try {
      await cacheManager.removeFile(music.url);
    } catch (_) {
      // 文件已被系统清理时忽略
    }
    await reload();
    update();
    Get.snackbar(
      '已删除离线缓存'.tr,
      music.songName,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> setLimit(int bytes) async {
    limitBytes.value = bytes < 0 ? 0 : bytes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(cacheLimitKey, limitBytes.value);
    update();
    await enforceLimit();
  }

  /// 超出上限时按下载时间从旧到新清理
  Future<void> enforceLimit() async {
    final limit = limitBytes.value;
    if (limit <= 0 || cachedUrls.isEmpty) return;

    final total = _sizes.values.fold(0, (sum, value) => sum + value);
    if (total <= limit) return;

    final ordered = cachedUrls.toList()
      ..sort((a, b) => (_stamps[a] ?? 0).compareTo(_stamps[b] ?? 0));

    var remaining = total;
    for (final url in ordered) {
      if (remaining <= limit) break;
      try {
        await cacheManager.removeFile(url);
      } catch (_) {
        continue;
      }
      remaining -= _sizes[url] ?? 0;
    }
    await reload();
  }

  /// 整个音乐缓存的磁盘占用（含封面，用于设置页展示）
  Future<int> diskUsage() => readMusicCacheSize();

  /// 清空全部缓存后同步状态
  Future<void> clearAll() async {
    await cacheManager.emptyCache();
    await reload();
  }
}
