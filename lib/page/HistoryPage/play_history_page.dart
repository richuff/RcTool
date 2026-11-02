import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/music_controller.dart';
import '../../repository/SqlLiteConn/play_history_conn.dart';
import '../../repository/entity/play_history.dart';
import '../../widget/app_scaffold.dart';
import '../../widget/slide_fade_in.dart';
import '../../widget/song_actions_sheet.dart';
import '../../widget/song_row.dart';

class PlayHistoryPage extends StatefulWidget {
  const PlayHistoryPage({super.key});

  @override
  State<PlayHistoryPage> createState() => _PlayHistoryPageState();
}

class _PlayHistoryPageState extends State<PlayHistoryPage> {
  final MusicController musicController = Get.find<MusicController>();
  List<PlayHistory> history = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final items = await PlayHistoryConn.queryRecent();
    if (!mounted) return;
    setState(() {
      history = items;
      loading = false;
    });
  }

  Future<void> _deleteHistory(PlayHistory item) async {
    await PlayHistoryConn.deleteByUrl(item.url);
    await _loadHistory();
  }

  Future<void> _clearHistory() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('清空最近播放'.tr),
        content: Text('将删除全部播放记录和统计数据，歌曲与歌单不会受影响。'.tr),
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
    );
    if (confirmed != true) return;
    await PlayHistoryConn.clear();
    await _loadHistory();
    Get.snackbar('已清空'.tr, '播放历史已删除'.tr, snackPosition: SnackPosition.BOTTOM);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppScaffold(
      nowPlaying: true,
      title: '最近播放'.tr,
      actions: [
        if (history.isNotEmpty)
          IconButton(
            tooltip: '清空历史'.tr,
            onPressed: _clearHistory,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
      ],
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: history.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 130),
                        Icon(
                          Icons.history_toggle_off,
                          size: 72,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            '还没有播放记录'.tr,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            '开始播放后，歌曲会自动出现在这里'.tr,
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    )
                  : GetBuilder<MusicController>(
                      builder: (controller) {
                        final musicList =
                            history.map((item) => item.toMusic()).toList();
                        return ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(8, 12, 8, 24),
                          itemCount: history.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.history, color: scheme.primary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '共 @count 首'.trParams(
                                            {'count': '${history.length}'}),
                                        style: TextStyle(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final itemIndex = index - 1;
                            final item = history[itemIndex];
                            final music = musicList[itemIndex];
                            return SlideFadeIn(
                              delay: Duration(
                                milliseconds:
                                    (itemIndex * 35).clamp(0, 280).toInt(),
                              ),
                              child: SongRow(
                                music: music,
                                subtitle: _formatPlayedAt(item.playedAt),
                                playing: controller.isPlayingMusic(music),
                                onPlayToggle: () => controller.playOrPauseMusic(
                                  music,
                                  list: musicList,
                                  startIndex: itemIndex,
                                ),
                                onMore: () => showSongActions(
                                  context,
                                  music,
                                  removeLabel: '删除这条记录'.tr,
                                  onRemove: () => _deleteHistory(item),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
    );
  }

  String _formatPlayedAt(DateTime value) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(value.year, value.month, value.day);
    final time =
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    if (day == today) return '今天 @time'.trParams({'time': time});
    if (day == today.subtract(const Duration(days: 1))) {
      return '昨天 @time'.trParams({'time': time});
    }
    return '${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} $time';
  }
}
