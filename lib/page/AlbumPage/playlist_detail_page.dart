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
import 'package:rctool/widget/play_all_button.dart';
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
  final FavoriteController favoriteController = Get.find<FavoriteController>();

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

  /// 歌单内拖动排序：先改内存里的顺序让列表立即生效，再写回 sortOrder。
  /// 「我的喜欢」按收藏表 id 排序，没有可持久化的顺序字段，不支持拖动。
  Future<void> _reorder(int oldIndex, int newIndex) async {
    var target = newIndex;
    if (target > oldIndex) target -= 1;
    if (target == oldIndex ||
        target < 0 ||
        target >= _musicList.length ||
        _isFavorite) {
      return;
    }
    setState(() {
      final item = _musicList.removeAt(oldIndex);
      _musicList.insert(target, item);
    });
    try {
      await PlaylistConn.saveMusicOrder(
        _playlist.id!,
        _musicList.map((m) => m.id!).toList(),
      );
    } catch (_) {
      // 写库失败不回滚界面，下次进入按库里的顺序展示
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppScaffold(
      // 歌单名称直接作为页面标题，页面内不再重复展示「歌单信息」卡片
      title: playlistDisplayName(_playlist.name),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Center(
            child: PlayAllButton(
              dense: true,
              onPressed: _musicList.isEmpty
                  ? null
                  : () => musicController.addMusicListToQueue(_musicList),
            ),
          ),
        ),
      ],
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

  List<Widget> _buildRows() {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 2, 8, 6),
        child: Row(
          children: [
            Icon(
              _isFavorite ? Icons.favorite_rounded : Icons.queue_music_rounded,
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
            if (!_isFavorite) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.drag_handle_rounded,
                size: 13,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.55),
              ),
              const SizedBox(width: 3),
              Text(
                '长按拖动排序'.tr,
                style: TextStyle(
                  fontSize: 10.5,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(0.75),
                ),
              ),
            ],
          ],
        ),
      ),
      GetBuilder<FavoriteController>(
        builder: (_) => GetBuilder<MusicController>(
          builder: (controller) => _isFavorite
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _songRows(controller),
                )
              : ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  onReorder: _reorder,
                  padding: EdgeInsets.zero,
                  proxyDecorator: (child, index, animation) => AnimatedBuilder(
                    animation: animation,
                    builder: (_, __) => Material(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                      child: child,
                    ),
                  ),
                  children: [
                    for (final entry in _musicList.asMap().entries)
                      ReorderableDelayedDragStartListener(
                        key: ValueKey('p-${entry.key}-${entry.value.url}'),
                        index: entry.key,
                        child: _rowFor(controller, entry.value),
                      ),
                  ],
                ),
        ),
      ),
    ];
  }

  List<Widget> _songRows(MusicController controller) {
    return _musicList.asMap().entries.map((entry) {
      return _rowFor(controller, entry.value);
    }).toList();
  }

  Widget _rowFor(MusicController controller, Music music) {
    return SlideFadeIn(
      offset: const Offset(0, 12),
      child: SongRow(
        music: music,
        playing: controller.isPlayingMusic(music),
        onPlayToggle: () => _playMusic(music),
        onMore: () => showSongActions(
          context,
          music,
          removeLabel: _isFavorite ? '从我的喜欢移除'.tr : '从歌单移除'.tr,
          onRemove: () => _removeMusic(music),
        ).then((_) => _load()),
      ),
    );
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
