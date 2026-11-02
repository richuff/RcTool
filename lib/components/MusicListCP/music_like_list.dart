import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/controller/music_controller.dart';
import 'package:rctool/repository/SqlLiteConn/playlist_conn.dart';

import '../../controller/favorite_controller.dart';
import '../../repository/entity/Music.dart';
import '../../repository/entity/playlist.dart';

class MusicLikeList extends StatefulWidget {
  const MusicLikeList({super.key});

  @override
  State<MusicLikeList> createState() => _MusicLikeList();
}

class _MusicLikeList extends State<MusicLikeList> {
  FavoriteController favoriteController = Get.put(FavoriteController());
  MusicController musicController = Get.put(MusicController());

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      favoriteController.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GetBuilder<FavoriteController>(
      builder: (controller) {
        final List<Music> likeList = controller.favoriteMusic;
        final List<Playlist> playlistList = controller.favoritePlaylists;
        return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _sectionTitle(context, "收藏歌单"),
                if (playlistList.isEmpty)
                  _emptyHint(context, "还没有收藏歌单")
                else
                  Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: playlistList.map((playlist) {
                        return _playlistItem(context, controller, playlist);
                      }).toList()),
                const SizedBox(height: 8),
                _sectionTitle(context, "收藏歌曲"),
                if (likeList.isEmpty)
                  _emptyHint(context, "还没有收藏歌曲")
                else
                Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: likeList.map((element) {
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
                                  image: NetworkImage(element.imageUrl),
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
                            "${element.songName}  -----  ${element.decoration}"),
                      ),
                      Positioned(
                          right: 2,
                          bottom: 18,
                          child: IconButton(
                              onPressed: () async {
                                await controller.remove(element.id);
                              },
                              icon: Icon(
                                Icons.favorite,
                                color: Colors.red,
                              ))),
                    ],
                  );
                    }).toList())
              ],
            ));
      },
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 2),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  Widget _emptyHint(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(8, 8, 0, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.62),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: scheme.onSurfaceVariant),
      ),
    );
  }

  Widget _playlistItem(
    BuildContext context,
    FavoriteController controller,
    Playlist playlist,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 0, 8),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withOpacity(0.72),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.secondary,
          foregroundColor: scheme.onSecondary,
          child: const Icon(Icons.queue_music),
        ),
        title: Text(playlist.name),
        subtitle: Text("${playlist.musicCount} 首歌曲"),
        trailing: Wrap(
          spacing: 2,
          children: [
            IconButton(
              tooltip: "播放歌单",
              icon: const Icon(Icons.play_arrow),
              onPressed: () async {
                if (playlist.id == null) return;
                final musicList =
                    await PlaylistConn.queryMusicByPlaylist(playlist.id!);
                musicController.addMusicListToQueue(musicList);
              },
            ),
            IconButton(
              tooltip: "取消收藏歌单",
              icon: const Icon(Icons.favorite, color: Colors.red),
              onPressed: () => controller.removePlaylist(playlist.id),
            ),
          ],
        ),
      ),
    );
  }
}
