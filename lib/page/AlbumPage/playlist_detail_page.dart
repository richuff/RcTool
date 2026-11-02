import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/constant/playlist_const.dart';
import 'package:rctool/controller/favorite_controller.dart';
import 'package:rctool/controller/music_controller.dart';
import 'package:rctool/repository/SqlLiteConn/favorite_conn.dart';
import 'package:rctool/repository/SqlLiteConn/music_conn.dart';
import 'package:rctool/repository/SqlLiteConn/playlist_conn.dart';
import 'package:rctool/repository/entity/Music.dart';
import 'package:rctool/repository/entity/playlist.dart';
import 'package:rctool/widget/app_scaffold.dart';
import 'package:rctool/widget/now_playing_bar.dart';
import 'package:rctool/widget/settings_ui.dart';
import 'package:rctool/widget/slide_fade_in.dart';
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
  final MusicController musicController = Get.put(MusicController());
  final FavoriteController favoriteController = Get.put(FavoriteController());

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

  Future<void> _showAddMusicDialog() async {
    final inPlaylist = _musicList.map((music) => music.id).toSet();
    final allMusic = await MusicConn.queryAll();
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        final scheme = Theme.of(dialogContext).colorScheme;
        return Dialog(
          backgroundColor: scheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          insetPadding: const EdgeInsets.all(18),
          child: SizedBox(
            width: 460,
            height: 460,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
                  child: SettingsHeader(
                    icon: Icons.library_add_rounded,
                    title: '添加歌曲',
                    subtitle: '添加到「${_playlist.name}」，已在歌单内的会标记',
                    onClose: () => Navigator.of(dialogContext).pop(),
                  ),
                ),
                Divider(
                  height: 1,
                  color: scheme.outline.withOpacity(0.16),
                ),
                Expanded(
                  child: allMusic.isEmpty
                      ? Center(
                          child: Text(
                            '曲库还没有歌曲',
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: allMusic.length,
                          itemBuilder: (context, index) {
                            final music = allMusic[index];
                            final added = inPlaylist.contains(music.id);
                            return ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              leading: _cover(scheme, music, 42),
                              title: Text(
                                music.songName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                music.decoration,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: added
                                  ? Icon(Icons.check_circle_rounded,
                                      color: scheme.primary)
                                  : IconButton(
                                      tooltip: '添加',
                                      icon: const Icon(
                                          Icons.add_circle_outline_rounded),
                                      onPressed: () async {
                                        await PlaylistConn.addMusic(
                                          _playlist.id!,
                                          music.id!,
                                        );
                                        await _load();
                                        if (dialogContext.mounted) {
                                          Navigator.of(dialogContext).pop();
                                        }
                                      },
                                    ),
                              onTap: added
                                  ? null
                                  : () async {
                                      await PlaylistConn.addMusic(
                                        _playlist.id!,
                                        music.id!,
                                      );
                                      await _load();
                                      if (dialogContext.mounted) {
                                        Navigator.of(dialogContext).pop();
                                      }
                                    },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppScaffold(
      title: _playlist.name,
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
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      children: [
                        _infoCard(context),
                        const SizedBox(height: 4),
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

  /// 与设置页一致的分组卡片
  Widget _infoCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SettingsSection(
      title: _isFavorite ? '默认歌单' : '歌单信息',
      icon: _isFavorite
          ? Icons.favorite_rounded
          : Icons.queue_music_rounded,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primaryContainer,
                  scheme.secondaryContainer,
                ],
              ),
            ),
            child: Icon(
              _isFavorite
                  ? Icons.favorite_rounded
                  : Icons.playlist_play_rounded,
              color: scheme.onPrimaryContainer,
            ),
          ),
          title: Text(
            _playlist.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          subtitle: Text(
            _isFavorite
                ? '收藏的歌曲都会出现在这里 · 共 ${_musicList.length} 首'
                : '共 ${_musicList.length} 首歌曲',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ),
        SettingsActionTile(
          icon: Icons.play_arrow_rounded,
          title: '播放全部',
          subtitle: _musicList.isEmpty ? '歌单里还没有歌曲' : '加入播放队列并从头开始',
          onTap: _musicList.isEmpty
              ? () {}
              : () => musicController.addMusicListToQueue(_musicList),
        ),
        if (!_isFavorite)
          SettingsActionTile(
            icon: Icons.library_add_rounded,
            title: '添加歌曲',
            subtitle: '从曲库中选择歌曲加入这个歌单',
            onTap: _showAddMusicDialog,
          ),
      ],
    );
  }

  List<Widget> _buildRows() {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
        child: Row(
          children: [
            Icon(Icons.music_note_rounded,
                size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              '歌曲',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: 0.6,
              ),
            ),
            const Spacer(),
            Text(
              '${_musicList.length} 首',
              style: TextStyle(
                fontSize: 12,
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
                  onRemove: () => _removeMusic(music),
                  removeIcon:
                      _isFavorite ? Icons.favorite : Icons.remove_circle_outline,
                  removeColor: _isFavorite
                      ? Theme.of(context).colorScheme.error
                      : null,
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
                  ? '还没有收藏歌曲，去每日推荐看看吧'
                  : '这个歌单还是空的，点「添加歌曲」加几首吧',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cover(ColorScheme scheme, Music music, double size) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: music.imageUrl.isNotEmpty
          ? Image.network(
              music.imageUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _coverFallback(scheme, size),
            )
          : _coverFallback(scheme, size),
    );
  }

  Widget _coverFallback(ColorScheme scheme, double size) {
    return Container(
      width: size,
      height: size,
      color: scheme.surfaceContainerHighest,
      child: Icon(Icons.music_note, size: size * 0.45, color: scheme.onSurfaceVariant),
    );
  }
}
