import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/controller/favorite_controller.dart';
import 'package:rctool/controller/music_controller.dart';
import 'package:rctool/repository/SqlLiteConn/music_conn.dart';
import 'package:rctool/repository/entity/Music.dart';
import 'package:rctool/widget/app_scaffold.dart';
import 'package:rctool/widget/play_all_button.dart';
import 'package:rctool/widget/slide_fade_in.dart';

/// 前三名奖牌配色（金 / 银 / 铜）
const List<Color> _medalColors = [
  Color(0xFFF5B800),
  Color(0xFFC7CDD4),
  Color(0xFFCD7F32),
];

class Ranking extends StatefulWidget {
  const Ranking({super.key});

  @override
  State<Ranking> createState() => _Ranking();
}

class _Ranking extends State<Ranking> {
  final MusicController musicController = Get.find<MusicController>();
  final FavoriteController favoriteController = Get.find<FavoriteController>();

  List<Music> allMusic = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    allMusic = await MusicConn.queryAll();
    await favoriteController.refresh();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final queueMusic = musicController.musiclist.whereType<Music>().toList();
    final latestMusic = allMusic.reversed.take(20).toList();

    return AppScaffold(
      // 榜单和播放强相关，底部常驻迷你播放条
      nowPlaying: true,
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          scrollbars: false,
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
          },
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: stagger([
              Text(
                "排行榜".tr,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                "为你整理的实时榜单".tr,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              GetBuilder<FavoriteController>(
                builder: (controller) => _RankingSection(
                  title: "收藏热榜".tr,
                  icon: Icons.favorite,
                  musicList: controller.favoriteMusic,
                  emptyText: "收藏歌曲后会出现在这里".tr,
                  onPlayAll: () => musicController
                      .addMusicListToQueue(controller.favoriteMusic),
                  onPlayMusic: (music) {
                    musicController.playOrPauseMusic(
                      music,
                      list: controller.favoriteMusic,
                      startIndex: controller.favoriteMusic.indexOf(music),
                    );
                  },
                  isPlayingMusic: musicController.isPlayingMusic,
                ),
              ),
              const SizedBox(height: 14),
              _RankingSection(
                title: "最近加入".tr,
                icon: Icons.new_releases,
                musicList: latestMusic,
                emptyText: "还没有加入歌曲".tr,
                onPlayAll: () =>
                    musicController.addMusicListToQueue(latestMusic),
                onPlayMusic: (music) {
                  musicController.playOrPauseMusic(
                    music,
                    list: latestMusic,
                    startIndex: latestMusic.indexOf(music),
                  );
                },
                isPlayingMusic: musicController.isPlayingMusic,
              ),
              const SizedBox(height: 14),
              _RankingSection(
                title: "当前队列".tr,
                icon: Icons.queue_music,
                musicList: queueMusic,
                emptyText: "当前播放队列为空".tr,
                onPlayAll: () =>
                    musicController.addMusicListToQueue(queueMusic),
                onPlayMusic: (music) {
                  musicController.playOrPauseMusic(
                    music,
                    list: queueMusic,
                    startIndex: queueMusic.indexOf(music),
                  );
                },
                isPlayingMusic: musicController.isPlayingMusic,
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _RankingSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Music> musicList;
  final String emptyText;
  final VoidCallback onPlayAll;
  final void Function(Music music) onPlayMusic;
  final bool Function(Music music) isPlayingMusic;

  const _RankingSection({
    required this.title,
    required this.icon,
    required this.musicList,
    required this.emptyText,
    required this.onPlayAll,
    required this.onPlayMusic,
    required this.isPlayingMusic,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.28)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  "共 @count 首".trParams({'count': '${musicList.length}'}),
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              PlayAllButton(
                dense: true,
                onPressed: musicList.isEmpty ? null : onPlayAll,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (musicList.isEmpty)
            SizedBox(
              height: 92,
              child: Center(
                child: Text(
                  emptyText,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            )
          else
            ...musicList.asMap().entries.map((entry) {
              final index = entry.key;
              final music = entry.value;
              final isTop3 = index < 3;
              final rankColor =
                  isTop3 ? _medalColors[index] : scheme.secondaryContainer;
              final rankTextColor =
                  isTop3 ? Colors.white : scheme.onSecondaryContainer;

              return SlideFadeIn(
                delay: Duration(milliseconds: 50 * index),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: scheme.surfaceVariant.withOpacity(0.72),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isTop3
                        ? [
                            BoxShadow(
                              color: rankColor.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: ListTile(
                    leading: SizedBox(
                      width: 92,
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: rankColor,
                            foregroundColor: rankTextColor,
                            child: Text("${index + 1}"),
                          ),
                          const SizedBox(width: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              music.imageUrl,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 40,
                                height: 40,
                                color: scheme.primaryContainer,
                                child: Icon(
                                  Icons.music_note,
                                  size: 20,
                                  color: scheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    title: Text(music.songName),
                    subtitle: Text(music.decoration),
                    trailing: IconButton(
                      tooltip: "播放".tr,
                      onPressed: () => onPlayMusic(music),
                      icon: GetBuilder<MusicController>(
                        builder: (_) {
                          final playing = isPlayingMusic(music);
                          return Icon(
                            playing ? Icons.pause : Icons.play_arrow,
                            color: playing ? scheme.primary : null,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
