import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/music_controller.dart';
import '../../repository/SqlLiteConn/play_history_conn.dart';
import '../../repository/entity/play_history.dart';
import '../../widget/app_scaffold.dart';
import '../../widget/slide_fade_in.dart';

/// @ClassName PlayStatsPage
/// @Description 播放统计：概览、近 7 天趋势、时段分布、常听歌曲/歌手。
///             整页使用 LayoutBuilder + 最小高度约束，内容不足时也铺满可视区域。
/// @Author richuff
/// @Version 2.0
class PlayStatsPage extends StatefulWidget {
  const PlayStatsPage({super.key});

  @override
  State<PlayStatsPage> createState() => _PlayStatsPageState();
}

class _PlayStatsPageState extends State<PlayStatsPage> {
  final MusicController musicController = Get.find<MusicController>();
  Map<String, int> overview = const {'total': 0, 'unique': 0, 'today': 0};
  List<PlayedSongSummary> topSongs = [];
  List<int> dailyCounts = List.filled(7, 0);
  List<int> hourBuckets = List.filled(4, 0);
  late DateTime weekStart;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 6));
    final overviewData = await PlayHistoryConn.queryOverview();
    final topData = await PlayHistoryConn.queryTopPlayed(limit: 20);
    final timestamps = await PlayHistoryConn.queryPlayedAtSince(start);
    final counts = List<int>.filled(7, 0);
    final buckets = List<int>.filled(4, 0);
    for (final timestamp in timestamps) {
      final day = DateTime(timestamp.year, timestamp.month, timestamp.day);
      final index = day.difference(start).inDays;
      if (index >= 0 && index < counts.length) counts[index]++;
      // 0-6 凌晨 / 6-12 上午 / 12-18 下午 / 18-24 晚上
      final bucket = (timestamp.hour ~/ 6).clamp(0, 3);
      buckets[bucket]++;
    }
    if (!mounted) return;
    setState(() {
      overview = overviewData;
      topSongs = topData;
      dailyCounts = counts;
      hourBuckets = buckets;
      weekStart = start;
      loading = false;
    });
  }

  /// 从常听歌曲里统计歌手（取前 4 位）。
  List<MapEntry<String, int>> get _topArtists {
    final counter = <String, int>{};
    for (final item in topSongs) {
      final artist = item.music.decoration.trim();
      if (artist.isEmpty) continue;
      counter[artist] = (counter[artist] ?? 0) + item.playCount;
    }
    final entries = counter.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppScaffold(
      nowPlaying: true,
      title: '播放统计'.tr,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                return RefreshIndicator(
                  onRefresh: _loadStats,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: (constraints.maxHeight - 40)
                            .clamp(0.0, double.infinity)
                            .toDouble(),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SlideFadeIn(child: _headerCard(scheme)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _summaryCard(
                                  icon: Icons.play_circle_outline_rounded,
                                  value: overview['total'] ?? 0,
                                  label: '总播放'.tr,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _summaryCard(
                                  icon: Icons.library_music_outlined,
                                  value: overview['unique'] ?? 0,
                                  label: '不同歌曲'.tr,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _summaryCard(
                                  icon: Icons.today_outlined,
                                  value: overview['today'] ?? 0,
                                  label: '今日播放'.tr,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SlideFadeIn(child: _weeklyCard(scheme)),
                          const SizedBox(height: 16),
                          SlideFadeIn(child: _timeOfDayCard(scheme)),
                          const SizedBox(height: 16),
                          if (_topArtists.isNotEmpty) ...[
                            SlideFadeIn(child: _artistCard(scheme)),
                            const SizedBox(height: 16),
                          ],
                          Row(
                            children: [
                              Icon(Icons.emoji_events_outlined,
                                  color: scheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                '常听歌曲'.tr,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (topSongs.isEmpty)
                            _emptyStats()
                          else
                            ...topSongs.take(5).toList().asMap().entries.map(
                                  (entry) => SlideFadeIn(
                                    delay:
                                        Duration(milliseconds: entry.key * 60),
                                    child: _topSongCard(
                                        scheme, entry.key, entry.value),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _headerCard(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer,
            scheme.secondaryContainer.withOpacity(0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: scheme.surface.withOpacity(0.85),
              shape: BoxShape.circle,
            ),
            child:
                Icon(Icons.graphic_eq_rounded, color: scheme.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '你的音乐足迹'.tr,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '统计数据仅来自这台设备上的播放历史'.tr,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: scheme.onPrimaryContainer.withOpacity(0.72),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required int value,
    required String label,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withOpacity(0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 22,
              height: 1.1,
              color: scheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _card(ColorScheme scheme, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.2)),
      ),
      child: child,
    );
  }

  Widget _weeklyCard(ColorScheme scheme) {
    final maxCount = dailyCounts.fold<int>(
      0,
      (max, count) => count > max ? count : max,
    );
    final weekdays = [
      '周一'.tr,
      '周二'.tr,
      '周三'.tr,
      '周四'.tr,
      '周五'.tr,
      '周六'.tr,
      '周日'.tr,
    ];
    final total = dailyCounts.fold<int>(0, (sum, count) => sum + count);
    final average = dailyCounts.isEmpty ? 0.0 : total / dailyCounts.length;

    return _card(
      scheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('近 7 天播放'.tr,
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text(
                '日均 @count 次'.trParams({'count': average.toStringAsFixed(1)}),
                style: TextStyle(
                  fontSize: 11.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 132,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final count = dailyCounts[index];
                final ratio = maxCount == 0 ? 0.0 : count / maxCount;
                final day = weekStart.add(Duration(days: index));
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '$count',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 5),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: ratio),
                        duration: Duration(milliseconds: 350 + index * 45),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => Container(
                          width: 22,
                          height: count == 0 ? 4 : 10 + value * 70,
                          decoration: BoxDecoration(
                            gradient: count == 0
                                ? null
                                : LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      scheme.primary,
                                      scheme.primary.withOpacity(0.55),
                                    ],
                                  ),
                            color: count == 0
                                ? scheme.surfaceContainerHighest
                                : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        index == 6 ? '今天'.tr : weekdays[day.weekday - 1],
                        style: TextStyle(
                          color: index == 6
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight:
                              index == 6 ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeOfDayCard(ColorScheme scheme) {
    final labels = ['凌晨'.tr, '上午'.tr, '下午'.tr, '晚上'.tr];
    const ranges = ['0-6', '6-12', '12-18', '18-24'];
    final total = hourBuckets.fold<int>(0, (sum, count) => sum + count);
    final maxCount =
        hourBuckets.fold<int>(0, (max, count) => count > max ? count : max);

    return _card(
      scheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('听歌时段'.tr, style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text(
                total == 0
                    ? '暂无数据'.tr
                    : '近 7 天 @count 次播放'.trParams({'count': '$total'}),
                style: TextStyle(
                  fontSize: 11.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < labels.length; index++) ...[
            Row(
              children: [
                SizedBox(
                  width: 34,
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(
                        begin: 0,
                        end: maxCount == 0 ? 0 : hourBuckets[index] / maxCount,
                      ),
                      duration: Duration(milliseconds: 320 + index * 60),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 8,
                        backgroundColor:
                            scheme.surfaceContainerHighest.withOpacity(0.8),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(scheme.secondary),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 62,
                  child: Text(
                    '@count 次 · @range'.trParams({
                      'count': '${hourBuckets[index]}',
                      'range': ranges[index]
                    }),
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            if (index != labels.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _artistCard(ColorScheme scheme) {
    return _card(
      scheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('常听歌手'.tr, style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text(
                '按播放次数'.tr,
                style: TextStyle(
                  fontSize: 11.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _topArtists.map((entry) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_outline_rounded,
                        size: 14, color: scheme.onSecondaryContainer),
                    const SizedBox(width: 5),
                    Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${entry.value}',
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSecondaryContainer.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _topSongCard(ColorScheme scheme, int index, PlayedSongSummary item) {
    final rankColors = [
      const Color(0xFFD4A017),
      const Color(0xFF8B949E),
      const Color(0xFFAD6A3B),
    ];
    final playing = musicController.isPlayingMusic(item.music);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline.withOpacity(0.18)),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: SizedBox(
          width: 82,
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '${index + 1}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        index < 3 ? rankColors[index] : scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.music.imageUrl.isNotEmpty
                    ? Image.network(
                        item.music.imageUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _coverFallback(scheme),
                      )
                    : _coverFallback(scheme),
              ),
            ],
          ),
        ),
        title: Text(
          item.music.songName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '@artist · 播放 @count 次'.trParams(
              {'artist': item.music.decoration, 'count': '${item.playCount}'}),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
        trailing: IconButton(
          tooltip: '播放'.tr,
          onPressed: () => musicController.playOrPauseMusic(item.music),
          icon: Icon(
            playing ? Icons.pause_circle_filled : Icons.play_circle_outline,
            color: scheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _coverFallback(ColorScheme scheme) {
    return Container(
      width: 48,
      height: 48,
      color: scheme.surfaceContainerHighest,
      child: Icon(Icons.music_note, color: scheme.onSurfaceVariant),
    );
  }

  Widget _emptyStats() {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.bar_chart_rounded,
                size: 52, color: scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              '播放几首歌曲后，这里会生成你的常听榜单'.tr,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
