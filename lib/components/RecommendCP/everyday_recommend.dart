import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/controller/favorite_controller.dart';
import 'package:rctool/controller/music_controller.dart';
import 'package:rctool/repository/SqlLiteConn/favorite_conn.dart';
import 'package:rctool/repository/SqlLiteConn/music_conn.dart';
import 'package:rctool/repository/SqlLiteConn/recommend_history_conn.dart';
import 'package:rctool/widget/now_playing_bar.dart';
import 'package:rctool/widget/slide_fade_in.dart';
import 'package:rctool/widget/song_row.dart';

import '../../repository/entity/Music.dart';
import '../../repository/entity/musicEntity/music_list.dart';
import '../../repository/entity/recommend_history.dart';

/// @ClassName EverydayList
/// @Description 每日推荐：头部渐变标题 + 统一高度操作按钮，
///             爱心点击后**图标本身变红**（再次点击取消收藏），
///             收藏落到「我的喜欢」默认歌单，底部常驻迷你播放条。
/// @Author richuff
/// @Version 3.0
class EverydayList extends StatefulWidget {
  const EverydayList({super.key});

  @override
  State<EverydayList> createState() => _EverydayList();
}

class _EverydayList extends State<EverydayList> {
  final MusicController musicController = Get.put(MusicController());
  final FavoriteController favoriteController = Get.put(FavoriteController());

  /// 今日推荐的歌曲（已写入曲库，带真实 id），收藏/播放都基于它
  List<Music> _todayMusic = [];
  bool _preparing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prepare();
      favoriteController.ensureLoaded();
    });
  }

  Future<void> _prepare() async {
    final list = await _saveTodayRecommend();
    if (!mounted) return;
    setState(() {
      _todayMusic = list;
      _preparing = false;
    });
  }

  List<int> get _todayIds =>
      _todayMusic.map((music) => music.id).whereType<int>().toList();

  bool get _isAllFavorite {
    final ids = _todayIds;
    if (ids.isEmpty) return false;
    return ids.every(favoriteController.isFavorite);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            padding: const EdgeInsets.fromLTRB(2, 6, 2, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _header(context),
                const SizedBox(height: 14),
                _actionBar(context),
                const SizedBox(height: 14),
                if (_preparing)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(),
                  )
                else
                  GetBuilder<FavoriteController>(
                    builder: (_) => GetBuilder<MusicController>(
                      builder: (controller) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var index = 0;
                              index < _todayMusic.length;
                              index++)
                            _buildRow(context, controller, index),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
        // 底部迷你播放条：队列为空时自动隐藏
        const NowPlayingBar(),
      ],
    );
  }

  Widget _buildRow(
    BuildContext context,
    MusicController controller,
    int index,
  ) {
    final music = _todayMusic[index];
    return SlideFadeIn(
      delay: Duration(milliseconds: (index * 40).clamp(0, 320)),
      offset: const Offset(0, 14),
      child: SongRow(
        music: music,
        playing: controller.isPlayingMusic(music),
        onPlayToggle: () => musicController.playOrPauseMusic(
          music,
          list: _todayMusic,
          startIndex: index,
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final count = _preparing ? allmusiclist.length : _todayMusic.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [scheme.primary, scheme.secondary],
                ).createShader(bounds),
                child: Text(
                  "每日推荐".tr,
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count 首',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Hi~ 为你准备了以下歌曲，请开始你的音乐之旅吧!".tr,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _actionButton(
              icon: Icons.play_arrow_rounded,
              label: "播放全部".tr,
              background: scheme.primary,
              foreground: scheme.onPrimary,
              gradient: true,
              onTap: () async {
                if (_todayMusic.isEmpty) await _prepare();
                if (_todayMusic.isEmpty) return;
                musicController.addMusicListToQueue(_todayMusic);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _actionButton(
              icon: Icons.history_rounded,
              background: scheme.surface,
              foreground: scheme.onSurface,
              border: scheme.outline.withOpacity(0.3),
              onTap: () => _showRecommendHistory(context),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GetBuilder<FavoriteController>(
              builder: (controller) {
                final isFavorite = _isAllFavorite;
                // 爱心图标本身变红（不是按钮底色变红），再点一次取消
                return _actionButton(
                  iconWidget: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      key: ValueKey(isFavorite),
                      size: 22,
                      color: isFavorite ? scheme.error : scheme.onSurfaceVariant,
                    ),
                  ),
                  background: scheme.surface,
                  foreground: scheme.onSurface,
                  border: isFavorite
                      ? scheme.error.withOpacity(0.55)
                      : scheme.outline.withOpacity(0.3),
                  onTap: _toggleFavorite,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 统一高度的操作按钮，避免"播放全部"带文字而比图标按钮更高的错位问题。
  Widget _actionButton({
    required Color background,
    required Color foreground,
    required VoidCallback onTap,
    IconData? icon,
    Widget? iconWidget,
    String? label,
    bool gradient = false,
    Color? border,
  }) {
    return SizedBox(
      height: 46,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
              border: border == null ? null : Border.all(color: border),
              gradient: gradient
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        background,
                        Color.alphaBlend(
                          Colors.black.withOpacity(0.12),
                          background,
                        ),
                      ],
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                iconWidget ??
                    Icon(icon, size: label == null ? 22 : 24, color: foreground),
                if (label != null) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return "${now.year}-$month-$day";
  }

  Future<List<Music>> _saveTodayRecommend() async {
    final musicList = <Music>[];
    for (final element in allmusiclist) {
      final url = element['url'];
      final imageUrl = element['imageUrl'];
      final songName = element['songName'];
      final decoration = element['decoration'];
      if (url == null ||
          imageUrl == null ||
          songName == null ||
          decoration == null) {
        continue;
      }

      final id = await MusicConn.queryByNameAndInsertMusic(
        url,
        imageUrl,
        songName,
        decoration,
      );
      musicList.add(Music(id, url, imageUrl, songName, decoration));
    }
    await RecommendHistoryConn.saveHistory(_todayKey(), musicList);
    return musicList;
  }

  /// 收藏 / 取消收藏今日推荐：收藏落到「我的喜欢」默认歌单。
  Future<void> _toggleFavorite() async {
    if (_preparing) return;
    final ids = _todayIds;
    if (ids.isEmpty) return;

    await favoriteController.ensureLoaded();
    final wasFavorite = ids.every(favoriteController.isFavorite);

    if (wasFavorite) {
      for (final id in ids) {
        await FavoriteConn.deleteByMusicId(id);
      }
    } else {
      for (final id in ids) {
        await FavoriteConn.insertFavoriteMusic(id);
      }
    }
    await favoriteController.refresh();

    Get.snackbar(
      wasFavorite ? "已取消收藏" : "收藏成功",
      wasFavorite
          ? "已从「我的喜欢」移除今日推荐的 ${ids.length} 首歌曲"
          : "今日推荐的 ${ids.length} 首歌曲已加入「我的喜欢」",
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> _showRecommendHistory(BuildContext context) async {
    await _saveTodayRecommend();
    final histories = await RecommendHistoryConn.queryHistories();
    if (!context.mounted) return;

    Get.bottomSheet(
      _RecommendHistorySheet(
        histories: histories,
        onPlayHistory: (history) async {
          final musicList =
              await RecommendHistoryConn.queryMusicByHistory(history.id);
          musicController.addMusicListToQueue(musicList);
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

class _RecommendHistorySheet extends StatelessWidget {
  final List<RecommendHistory> histories;
  final Future<void> Function(RecommendHistory history) onPlayHistory;

  const _RecommendHistorySheet({
    required this.histories,
    required this.onPlayHistory,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final height = MediaQuery.of(context).size.height;
    return Container(
      height: height > 520 ? 520 : height * 0.82,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                "每日推荐历史",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: histories.isEmpty
                ? Center(
                    child: Text(
                      "暂无历史记录",
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    itemCount: histories.length,
                    itemBuilder: (context, index) {
                      final history = histories[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          leading: CircleAvatar(
                            backgroundColor: scheme.primaryContainer,
                            foregroundColor: scheme.onPrimaryContainer,
                            child: const Icon(Icons.calendar_month),
                          ),
                          title: Text(history.recommendDate),
                          subtitle: Text("${history.musicCount} 首歌曲"),
                          trailing: IconButton(
                            tooltip: "播放这天的推荐",
                            icon: const Icon(Icons.play_arrow),
                            onPressed: () => onPlayHistory(history),
                          ),
                          onTap: () => _showHistoryDetail(context, history),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showHistoryDetail(BuildContext context, RecommendHistory history) {
    final scheme = Theme.of(context).colorScheme;
    Get.bottomSheet(
      Container(
        height: 420,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    history.recommendDate,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => onPlayHistory(history),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("播放"),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<Music>>(
                future: RecommendHistoryConn.queryMusicByHistory(history.id),
                builder: (context, snapshot) {
                  final musicList = snapshot.data ?? [];
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (musicList.isEmpty) {
                    return Center(
                      child: Text(
                        "这天还没有歌曲记录",
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: musicList.length,
                    itemBuilder: (context, index) {
                      final music = musicList[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: scheme.secondaryContainer,
                          foregroundColor: scheme.onSecondaryContainer,
                          child: Text("${index + 1}"),
                        ),
                        title: Text(music.songName),
                        subtitle: Text(music.decoration),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}
