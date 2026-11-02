import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/controller/music_controller.dart';
import 'package:rctool/controller/offline_controller.dart';
import 'package:rctool/utils/size_format.dart';
import 'package:rctool/widget/app_scaffold.dart';
import 'package:rctool/widget/cache_limit_dialog.dart';
import 'package:rctool/widget/now_playing_bar.dart';
import 'package:rctool/widget/song_actions_sheet.dart';
import 'package:rctool/widget/song_row.dart';

/// @ClassName OfflinePage
/// @Description 离线管理：查看已下载到本地的歌曲与占用，可单曲试听 / 删除，
///              也可一键清空，并在这里调整缓存上限。
/// @Author richuff
/// @Version 1.0
class OfflinePage extends StatefulWidget {
  const OfflinePage({super.key});

  @override
  State<OfflinePage> createState() => _OfflinePageState();
}

class _OfflinePageState extends State<OfflinePage> {
  final OfflineController offline = Get.find<OfflineController>();
  final MusicController musicController = Get.find<MusicController>();

  List<OfflineEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final list = await offline.entries();
    if (!mounted) return;
    setState(() {
      _entries = list;
      _loading = false;
    });
  }

  Future<void> _play(int index) async {
    await _load();
    if (!mounted) return;
    musicController.playMusicList(
      _entries.map((entry) => entry.music).toList(),
      startIndex: index,
    );
  }

  Future<void> _remove(OfflineEntry entry) async {
    await offline.removeOffline(entry.music);
    await _load();
  }

  Future<void> _clearAll() async {
    final confirmed = await Get.dialog<bool>(
          AlertDialog(
            title: Text('清空离线缓存'.tr),
            content: Text('将删除全部已下载的音频与封面缓存，歌曲和歌单不受影响。'.tr),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: Text('取消'.tr),
              ),
              FilledButton(
                onPressed: () => Get.back(result: true),
                child: Text('清空'.tr),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    await offline.clearAll();
    await _load();
  }

  Future<void> _pickLimit() async {
    final changed = await showCacheLimitDialog(context, offline);
    if (changed == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppScaffold(
      title: '离线歌曲'.tr,
      actions: [
        IconButton(
          tooltip: '刷新'.tr,
          onPressed: _load,
          icon: Icon(Icons.refresh_rounded, color: scheme.onSurface),
        ),
      ],
      body: GetBuilder<OfflineController>(
        builder: (controller) => Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
                      children: [
                        _summaryCard(scheme, controller),
                        const SizedBox(height: 6),
                        if (_entries.isEmpty)
                          _emptyState(scheme)
                        else ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 2, 8, 6),
                            child: Text(
                              '共 @count 首'.trParams(
                                  {'count': '${_entries.length}'}),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          ..._entries.asMap().entries.map((item) {
                            final entry = item.value;
                            return SongRow(
                              music: entry.music,
                              subtitle: '@size · 已下载'.trParams(
                                  {'size': formatBytes(entry.bytes)}),
                              playing: musicController
                                  .isPlayingMusic(entry.music),
                              onPlayToggle: () => _play(item.key),
                              removeIcon: Icons.delete_outline_rounded,
                              onRemove: () => _remove(entry),
                              onMore: () =>
                                  showSongActions(context, entry.music),
                            );
                          }),
                        ],
                      ],
                    ),
            ),
            const NowPlayingBar(),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(ColorScheme scheme, OfflineController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer.withOpacity(0.75),
            scheme.secondaryContainer.withOpacity(0.45),
          ],
        ),
        border: Border.all(color: scheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.surface.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.offline_pin_rounded,
                    size: 21, color: scheme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '已下载 @count 首'.trParams(
                          {'count': '${controller.cachedUrls.length}'}),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '占用 @size · 上限 @limit'.trParams({
                        'size': formatBytes(controller.totalBytes.value),
                        'limit': controller.limitLabel,
                      }),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickLimit,
                  icon: const Icon(Icons.sd_storage_outlined, size: 17),
                  label: Text('缓存上限'.tr,
                      style: const TextStyle(fontSize: 12.5)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.cachedUrls.isEmpty ? null : _clearAll,
                  icon: const Icon(Icons.delete_sweep_outlined, size: 17),
                  label: Text('清空缓存'.tr,
                      style: const TextStyle(fontSize: 12.5)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    foregroundColor: scheme.error,
                    side: BorderSide(color: scheme.error.withOpacity(0.4)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 44),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withOpacity(0.55),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cloud_download_outlined,
                  size: 30, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 12),
            Text(
              '还没有离线歌曲'.tr,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '在歌曲右侧点「…」选择「下载到本地」即可离线收听'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
