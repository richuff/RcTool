import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/controller/favorite_controller.dart';
import 'package:rctool/controller/music_controller.dart';
import 'package:rctool/repository/SqlLiteConn/music_conn.dart';
import 'package:rctool/repository/entity/Music.dart';
import 'package:rctool/widget/BackGround/back_ground_enum.dart';

import '../../feature/design/icon_button_no_ripple.dart';
import '../../widget/main_drawer.dart';
import '../../widget/search_widget.dart';

class Ranking extends StatefulWidget {
  const Ranking({super.key});

  @override
  State<Ranking> createState() => _Ranking();
}

class _Ranking extends State<Ranking> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final MusicController musicController =
      Get.put(MusicController(), permanent: true);
  final FavoriteController favoriteController =
      Get.put(FavoriteController(), permanent: true);

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
    final scheme = Theme.of(context).colorScheme;
    final queueMusic = musicController.musiclist.whereType<Music>().toList();
    final latestMusic = allMusic.reversed.take(20).toList();
    return Scaffold(
      key: scaffoldKey,
      drawerScrimColor: Colors.transparent,
      drawer: MainDrawer(() {
        scaffoldKey.currentState?.closeDrawer();
      }),
      appBar: AppBar(
          backgroundColor: scheme.surface,
          leading: Builder(builder: (context) {
            return Column(children: [
              const Padding(padding: EdgeInsets.only(top: 8)),
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: IconButtonNoRipple(
                  hoverColor: scheme.primaryContainer,
                  focusColor: scheme.primaryContainer,
                  highlightColor: scheme.secondaryContainer,
                  alignment: Alignment.bottomCenter,
                  icon: const Icon(
                    Icons.menu,
                    size: 26,
                  ),
                  color: scheme.onSurface,
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),
            ]);
          }),
          actions: const [SearchWidget()]),
      body: Container(
          width: double.infinity,
          decoration: BackGroundEnum.musicBackGround.decoration,
          child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context)
                  .copyWith(scrollbars: false, dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
              }),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "排行榜".tr,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    GetBuilder<FavoriteController>(
                      builder: (controller) {
                        final favoriteMusic = controller.favoriteMusic;
                        return _RankingSection(
                          title: "收藏热榜",
                          icon: Icons.favorite,
                          musicList: favoriteMusic,
                          emptyText: "收藏歌曲后会出现在这里",
                          onPlayAll: () =>
                              musicController.addMusicListToQueue(favoriteMusic),
                          onPlayMusic: (music) {
                            musicController.playOrPauseMusic(
                              music,
                              list: favoriteMusic,
                              startIndex: favoriteMusic.indexOf(music),
                            );
                          },
                          isPlayingMusic: musicController.isPlayingMusic,
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _RankingSection(
                      title: "最近加入",
                      icon: Icons.new_releases,
                      musicList: latestMusic,
                      emptyText: "还没有加入歌曲",
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
                      title: "当前队列",
                      icon: Icons.queue_music,
                      musicList: queueMusic,
                      emptyText: "当前播放队列为空",
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
                  ],
                ),
              ))),
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outline.withOpacity(0.35)),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  "${musicList.length}",
                  style: TextStyle(
                    color: scheme.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: musicList.isEmpty ? null : onPlayAll,
                icon: const Icon(Icons.play_arrow),
                label: const Text("播放全部"),
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
              final index = entry.key + 1;
              final music = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: scheme.surfaceVariant.withOpacity(0.72),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: index <= 3
                        ? scheme.primary
                        : scheme.secondaryContainer,
                    foregroundColor: index <= 3
                        ? scheme.onPrimary
                        : scheme.onSecondaryContainer,
                    child: Text("$index"),
                  ),
                  title: Text(music.songName),
                  subtitle: Text(music.decoration),
                  trailing: IconButton(
                    tooltip: "播放",
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
              );
            }),
        ],
      ),
    );
  }
}
