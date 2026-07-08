import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/repository/SqlLiteConn/music_conn.dart';
import 'package:rctool/repository/SqlLiteConn/recommend_history_conn.dart';
import 'package:rctool/utils/comm_util.dart';

import '../../controller/favorite_controller.dart';
import '../../controller/is_dark_controller.dart';
import '../../controller/music_controller.dart';
import '../../repository/entity/Music.dart';
import '../../repository/entity/recommend_history.dart';
import '../../repository/entity/musicEntity/music_list.dart';
import '../../utils/notification_helper.dart';

class EverydayList extends StatefulWidget {
  const EverydayList({super.key});

  @override
  State<EverydayList> createState() => _EverydayList();
}

class _EverydayList extends State<EverydayList> {
  MusicController musicController = Get.put(MusicController());
  FavoriteController favoriteController = Get.put(FavoriteController());
  IsDarkController isDarkController = Get.put(IsDarkController());
  final NotificationHelper notificationHelper = NotificationHelper();

  bool inDark = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveTodayRecommend();
    });
    isDarkController.addListener(() {
      setState(() {
        inDark = isDarkController.isDark.value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(5, 5, 0, 5),
              alignment: Alignment.centerLeft,
              child: Text(
                "每日推荐".tr,
                style: const TextStyle(
                  fontSize: 30,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(5, 5, 0, 12),
              alignment: Alignment.centerLeft,
              child: Text(
                "Hi~ 为你准备了以下歌曲，请开始你的音乐之旅吧!".tr,
                style: TextStyle(
                    fontSize: 16,
                    color: inDark
                        ? const Color.fromARGB(140, 255, 255, 255)
                        : const Color.fromARGB(140, 0, 0, 0)),
                textAlign: TextAlign.left,
              ),
            ),
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  Flexible(
                    flex: 2,
                    child: _recommendActionButton(
                      context,
                      icon: Icons.play_arrow_sharp,
                      label: "播放全部",
                      backgroundColor: scheme.secondary,
                      foregroundColor: scheme.onSecondary,
                      margin: const EdgeInsets.fromLTRB(8, 5, 2, 4),
                      onTap: () async {
                        final musicList = await _saveTodayRecommend();
                        musicController.addMusicListToQueue(musicList);
                      },
                    ),
                  ),
                  Flexible(
                    flex: 1,
                    child: _recommendActionButton(
                      context,
                      icon: Icons.access_time_outlined,
                      backgroundColor: scheme.secondaryContainer,
                      foregroundColor: scheme.onSecondaryContainer,
                      margin: const EdgeInsets.fromLTRB(5, 5, 2, 4),
                      onTap: () => _showRecommendHistory(context),
                    ),
                  ),
                  Flexible(
                    flex: 1,
                    child: _recommendActionButton(
                      context,
                      icon: Icons.favorite_border,
                      backgroundColor: scheme.primaryContainer,
                      foregroundColor: scheme.onPrimaryContainer,
                      margin: const EdgeInsets.fromLTRB(5, 5, 6, 4),
                      onTap: () => _favoriteTodayRecommend(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: allmusiclist.map((element) {
                  final elementMusic = Music(
                    null,
                    element['url'] ?? "",
                    element['imageUrl'] ?? "",
                    element['songName'] ?? "",
                    element['decoration'] ?? "",
                  );
                  return Stack(
                    children: [
                      const SizedBox(
                        height: 80,
                      ),
                      Container(
                        margin: const EdgeInsets.fromLTRB(8, 20, 0, 12),
                        width: double.infinity,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: scheme.primaryContainer,
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              scheme.primaryContainer.withOpacity(0.86),
                              scheme.secondaryContainer.withOpacity(0.78),
                              scheme.tertiary.withOpacity(0.24),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.shadow.withOpacity(0.16),
                              blurRadius: 10.0,
                            )
                          ],
                        ),
                      ),
                      Positioned(
                          left: 8,
                          top: 0,
                          child: Container(
                            width: 75,
                            height: 75,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                  image: NetworkImage(element['imageUrl']!),
                                  fit: BoxFit.cover),
                              color: scheme.surfaceVariant,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(10)),
                            ),
                          )),
                      Positioned(
                        left: 90,
                        bottom: 30,
                        child: Text(
                            "${element['songName']}  -----  ${element['decoration']}"),
                      ),
                      Positioned(
                          right: 10,
                          bottom: 18,
                          child: GetBuilder<MusicController>(
                            builder: (controller) {
                              final playing =
                                  controller.isPlayingMusic(elementMusic);
                              return Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: playing
                                      ? scheme.primary
                                      : scheme.secondary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: scheme.shadow.withOpacity(0.16),
                                      blurRadius: 6,
                                    )
                                  ],
                                ),
                                child: IconButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: () {
                                      () async {
                                        try {
                                          if (playing) {
                                            controller.onPause();
                                            return;
                                          }
                                          final url = element['url'];
                                          final imageUrl = element['imageUrl'];
                                          final songName = element['songName'];
                                          final decoration =
                                              element['decoration'];

                                          if (url == null ||
                                              imageUrl == null ||
                                              songName == null ||
                                              decoration == null) {
                                            return;
                                          }

                                          int? insertId = await MusicConn
                                              .queryByNameAndInsertMusic(
                                            url,
                                            imageUrl,
                                            songName,
                                            decoration,
                                          );

                                          controller.playOrPauseMusic(Music(
                                            insertId,
                                            url,
                                            imageUrl,
                                            songName,
                                            decoration,
                                          ));

                                          notificationHelper
                                              .showNewMusicNotification(
                                            title: "当前正在播放".tr,
                                            body: "$songName - $decoration",
                                          );
                                        } catch (e) {}
                                      }();
                                    },
                                    icon: Icon(
                                      playing
                                          ? Icons.pause
                                          : Icons.play_arrow_sharp,
                                      color: playing
                                          ? scheme.onPrimary
                                          : scheme.onSecondary,
                                    )),
                              );
                            },
                          )),
                    ],
                  );
                }).toList())
          ],
        ));
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

  Future<void> _favoriteTodayRecommend(BuildContext context) async {
    final musicList = await _saveTodayRecommend();
    await favoriteController.addAll(
      musicList.where((music) => music.id != null).map((music) => music.id!),
    );
    if (!context.mounted) return;
    Get.snackbar(
      "收藏成功",
      "已收藏今日推荐 ${musicList.length} 首歌曲",
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
    );
  }

  Widget _recommendActionButton(
    BuildContext context, {
    required IconData icon,
    required Color backgroundColor,
    required Color foregroundColor,
    required EdgeInsets margin,
    required VoidCallback onTap,
    String? label,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          margin: margin,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withOpacity(0.14),
                blurRadius: 6,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment:
                label == null ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(icon, size: label == null ? 30 : 34, color: foregroundColor),
              if (label != null) ...[
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @Deprecated("不使用controller插入")
  void incMusicOld(Map<String, String> element) {
    musicController.incOld(
        element['url']!,
        element['imageUrl']!,
        element['songName']!,
        element['decoration']!,
        CommUtil.parseBool(element['isFavorite']));
    notificationHelper.showNewMusicNotification(
        title: "当前正在播放".tr,
        body: "${element['songName']}  -----  ${element['decoration']}");
    MusicConn.queryByUrlAndInsert(
        element['url']!,
        element['imageUrl']!,
        element['songName']!,
        element['decoration']!,
        CommUtil.parseBool(element['isFavorite']));
    Get.back();
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: scheme.secondary),
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
                          color: scheme.surfaceVariant.withOpacity(0.72),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: scheme.secondaryContainer,
                            foregroundColor: scheme.onSecondaryContainer,
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
    );
  }
}
