import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/constant/playlist_const.dart';
import 'package:rctool/controller/favorite_controller.dart';
import 'package:rctool/controller/music_controller.dart';
import 'package:rctool/repository/SqlLiteConn/favorite_conn.dart';
import 'package:rctool/repository/SqlLiteConn/playlist_conn.dart';
import 'package:rctool/repository/entity/Music.dart';
import 'package:rctool/repository/entity/playlist.dart';
import 'package:rctool/widget/app_scaffold.dart';
import 'package:rctool/widget/now_playing_bar.dart';
import 'package:rctool/widget/slide_fade_in.dart';
import 'package:rctool/widget/song_actions_sheet.dart';
import 'package:rctool/widget/song_row.dart';

/// @ClassName PlaylistDetailPage
/// @Description 歌单详情页：歌单信息 + 歌曲列表，样式与设置页保持一致。
///             「我的喜欢」是内置默认歌单（id = -1），数据来源为收藏表。
/// @Author richuff
/// @Version 1.0
class PlaylistDetailPage extends StatefulWidget {
  final Playlist playlist;

  const PlaylistDetailPage({super.key, required this.playlist});

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  final MusicController musicController = Get.find<MusicController>();
  final FavoriteController favoriteController =
      Get.find<FavoriteController>();

  List<Music> _musicList = [];
  bool _loading = true;

  Playlist get _playlist => widget.playlist;
  bool get _isFavorite => isFavoritePlaylistId(_playlist.id);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final list = _isFavorite
        ? await FavoriteConn.queryFavoriteMusic()
        : await PlaylistConn.queryMusicByPlaylist(_playlist.id!);
    if (!mounted) return;
    setState(() {
      _musicList = list;
      _loading = false;
    });
  }

  Future<void> _removeMusic(Music music) async {
    if (music.id == null) return;
    if (_isFavorite) {
      await FavoriteConn.deleteByMusicId(music.id!);
      await favoriteController.refresh();
    } else {
      await PlaylistConn.removeMusic(_playlist.id!, music.id!);
    }
    await _load();
  }

  void _playMusic(Music music) {
    musicController.playOrPauseMusic(
      music,
      list: _musicList,
      startIndex: _musicList.indexOf(music),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppScaffold(
      // 歌单名称直接作为页面标题，页面内不再重复展示「歌单信息」卡片
      title: _playlist.name,
      actions: [_playAllAction(scheme)],
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          scrollbars: false,
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
          },
        ),
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
                      children: [
                        if (_musicList.isEmpty)
                          _emptyState(scheme)
                        else
                          ..._buildRows(),
                      ],
                    ),
            ),
            const NowPlayingBar(),
          ],
        ),
      ),
    );
  }

  /// 右上角「播放全部」按钮：直接加入队列并从头播放
  Widget _playAllAction(ColorScheme scheme) {
    final enabled = _musicList.isNotEmpty;
    final radius = BorderRadius.circular(18);
    return Padding(
      padding: const EdgeInsets.only(top: 9, bottom: 9, right: 2),
      child: Opacity(
        opacity: enabled ? 1 : 0.42,
        child: Material(
          color: scheme.primary,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: enabled
                ? () => musicController.addMusicListToQueue(_musicList)
                : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 5, 12, 5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.play_arrow_rounded,
                    size: 19,
                    color: scheme.onPrimary,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '播放全部'.tr,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: scheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRows() {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 2, 8, 6),
        child: Row(
          children: [
            Icon(
              _isFavorite
                  ? Icons.favorite_rounded
                  : Icons.queue_music_rounded,
              size: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              '共 @count 首'.trParams({'count': '${_musicList.length}'}),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      GetBuilder<FavoriteController>(
        builder: (_) => GetBuilder<MusicController>(
          builder: (controller) => Column(
            mainAxisSize: MainAxisSize.min,
            children: _musicList.asMap().entries.map((entry) {
              final music = entry.value;
              return SlideFadeIn(
                delay: Duration(milliseconds: (entry.key * 35).clamp(0, 280)),
                offset: const Offset(0, 12),
                child: SongRow(
                  music: music,
                  playing: controller.isPlayingMusic(music),
                  onPlayToggle: () => _playMusic(music),
                  onMore: () => showSongActions(
                    context,
                    music,
                    removeLabel: _isFavorite
                        ? '从我的喜欢移除'.tr
                        : '从歌单移除'.tr,
                    onRemove: () => _removeMusic(music),
                  ).then((_) => _load()),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    ];
  }

  Widget _emptyState(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 46),
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
              child: Icon(
                _isFavorite
                    ? Icons.favorite_border_rounded
                    : Icons.music_note_rounded,
                size: 30,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isFavorite
                  ? '还没有收藏歌曲，去每日推荐看看吧'.tr
                  : '这个歌单还是空的，在任意歌曲右侧点「…」就能加进来'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
