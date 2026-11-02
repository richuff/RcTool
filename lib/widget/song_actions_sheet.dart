import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/constant/playlist_const.dart';
import 'package:rctool/controller/favorite_controller.dart';
import 'package:rctool/controller/offline_controller.dart';
import 'package:rctool/repository/SqlLiteConn/favorite_conn.dart';
import 'package:rctool/repository/SqlLiteConn/playlist_conn.dart';
import 'package:rctool/repository/entity/Music.dart';
import 'package:rctool/repository/entity/playlist.dart';
import 'package:rctool/utils/size_format.dart';

/// 统一的歌曲操作面板（「…」按钮）。
///
/// 打开后提供「添加到歌单」「收藏 / 取消收藏」，并可按场景追加一项移除操作。
/// 添加到歌单会直接列出全部歌单（含「我的喜欢」），点一下即加入，再点取消。
Future<void> showSongActions(
  BuildContext context,
  Music music, {
  String? removeLabel,
  Future<void> Function()? onRemove,
}) async {
  await Get.bottomSheet(
    _SongActionsSheet(
      music: music,
      removeLabel: removeLabel,
      onRemove: onRemove,
    ),
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
  );
}

class _SongActionsSheet extends StatelessWidget {
  final Music music;
  final String? removeLabel;
  final Future<void> Function()? onRemove;

  const _SongActionsSheet({
    required this.music,
    this.removeLabel,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outline.withOpacity(0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _cover(scheme),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        music.songName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        music.decoration,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '关闭',
                  onPressed: () => Get.back(),
                  icon: Icon(Icons.close_rounded,
                      size: 20, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: scheme.outline.withOpacity(0.14)),
            const SizedBox(height: 6),
            _tile(
              context,
              icon: Icons.playlist_add_rounded,
              title: '添加到歌单'.tr,
              subtitle: '加入「我的喜欢」或自建歌单'.tr,
              onTap: () => _openPlaylistPicker(context),
            ),
            GetBuilder<FavoriteController>(
              builder: (controller) {
                final isFavorite = controller.isFavorite(music.id);
                return _tile(
                  context,
                  icon: isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  iconColor: isFavorite ? scheme.error : null,
                  title: isFavorite ? '取消收藏'.tr : '收藏到我的喜欢'.tr,
                  onTap: () async {
                    await controller.toggle(music.id);
                    if (Get.isBottomSheetOpen ?? false) Get.back();
                    Get.snackbar(
                      isFavorite ? '已取消收藏'.tr : '收藏成功'.tr,
                      music.songName,
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                );
              },
            ),
            if (Get.isRegistered<OfflineController>())
              GetBuilder<OfflineController>(
                builder: (offline) {
                  final cached = offline.isCached(music.url);
                  final busy = offline.isDownloading(music.url);
                  return _tile(
                    context,
                    icon: cached
                        ? Icons.offline_pin_rounded
                        : Icons.download_rounded,
                    iconColor: cached ? scheme.primary : null,
                    title: cached ? '删除离线缓存'.tr : '下载到本地'.tr,
                    subtitle: busy
                        ? '正在下载…'.tr
                        : cached
                            ? '已占用 @size · 删除后需联网播放'.trParams(
                                {'size': formatBytes(offline.sizeOf(music.url))})
                            : '下载后可离线收听'.tr,
                    onTap: () async {
                      if (busy) return;
                      if (cached) {
                        await offline.removeOffline(music);
                        return;
                      }
                      // 下载可能耗时，先收起面板再在后台进行
                      if (Get.isBottomSheetOpen ?? false) Get.back();
                      await offline.download(music);
                    },
                  );
                },
              ),
            if (removeLabel != null && onRemove != null)              _tile(
                context,
                icon: Icons.remove_circle_outline_rounded,
                iconColor: scheme.error,
                title: removeLabel!,
                onTap: () async {
                  await onRemove!();
                  if (Get.isBottomSheetOpen ?? false) Get.back();
                },
              ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _cover(ColorScheme scheme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: music.imageUrl.isNotEmpty
          ? Image.network(
              music.imageUrl,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _coverFallback(scheme),
            )
          : _coverFallback(scheme),
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

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 6),
      onTap: onTap,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withOpacity(0.6),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon,
            size: 20, color: iconColor ?? scheme.onPrimaryContainer),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: iconColor ?? scheme.onSurface,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
            ),
      trailing:
          Icon(Icons.chevron_right_rounded, size: 20, color: scheme.outline),
    );
  }

  Future<void> _openPlaylistPicker(BuildContext context) async {
    final musicId = music.id;
    if (musicId == null) {
      Get.snackbar(
        '无法添加',
        '这首歌还没有保存到曲库，先播放一次再添加吧',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    await Get.bottomSheet(
      _PlaylistPickerSheet(music: music),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }
}

/// 歌单选择面板：列出「我的喜欢」与全部自建歌单，点一下加入 / 再点移出。
class _PlaylistPickerSheet extends StatefulWidget {
  final Music music;

  const _PlaylistPickerSheet({required this.music});

  @override
  State<_PlaylistPickerSheet> createState() => _PlaylistPickerSheetState();
}

class _PlaylistPickerSheetState extends State<_PlaylistPickerSheet> {
  final FavoriteController favoriteController =
      Get.find<FavoriteController>();

  List<Playlist> _playlists = [];
  Set<int> _contained = {};
  bool _favorite = false;
  bool _loading = true;

  int get _musicId => widget.music.id!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final all = await PlaylistConn.queryPlaylists();
    final contained = await PlaylistConn.queryPlaylistIdsOfMusic(_musicId);
    final favorite = await FavoriteConn.queryByMusicAndCheckFavorite(_musicId);
    if (!mounted) return;
    setState(() {
      _playlists = all.where((item) => !isInternalPlaylist(item)).toList();
      _contained = contained;
      _favorite = favorite;
      _loading = false;
    });
  }

  Future<void> _togglePlaylist(Playlist playlist) async {
    final id = playlist.id!;
    final wasThere = _contained.contains(id);
    if (wasThere) {
      await PlaylistConn.removeMusic(id, _musicId);
    } else {
      await PlaylistConn.addMusic(id, _musicId);
    }
    await _load();
    Get.snackbar(
      wasThere
          ? '已从「@name」移出'.trParams({'name': playlist.name})
          : '已加入「@name」'.trParams({'name': playlist.name}),
      widget.music.songName,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _toggleFavorite() async {
    final wasFavorite = _favorite;
    await favoriteController.toggle(_musicId);
    await _load();
    Get.snackbar(
      wasFavorite ? '已取消收藏'.tr : '已加入「我的喜欢」'.tr,
      widget.music.songName,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _createPlaylist() async {
    final controller = TextEditingController();
    final name = await Get.dialog<String>(
      AlertDialog(
        title: Text('新建歌单'.tr),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          decoration: InputDecoration(
            labelText: '歌单名称'.tr,
            counterText: '',
          ),
          onSubmitted: (value) => Get.back(result: value.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('取消'.tr)),
          FilledButton(
            onPressed: () => Get.back(result: controller.text.trim()),
            child: Text('创建'.tr),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    if (await PlaylistConn.existsByName(name)) {
      Get.snackbar('已有同名歌单'.tr, '换个名字试试'.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final id = await PlaylistConn.insertPlaylist(name);
    await PlaylistConn.addMusic(id, _musicId);
    await _load();
    Get.snackbar('已创建'.tr,
        '「@name」已建好，这首歌也加进去了'.trParams({'name': name}),
        snackPosition: SnackPosition.BOTTOM);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final height = MediaQuery.of(context).size.height;
    return Container(
      height: height * 0.6,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outline.withOpacity(0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.playlist_add_rounded,
                    size: 20, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '添加到歌单',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _createPlaylist,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('新建', style: TextStyle(fontSize: 12.5)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ],
            ),
            Divider(height: 14, color: scheme.outline.withOpacity(0.14)),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      children: [
                        _row(
                          context,
                          icon: _favorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          iconColor: _favorite ? scheme.error : null,
                          title: kFavoritePlaylistName,
                          subtitle: '默认歌单 · 收藏的歌曲都会汇总到这里',
                          selected: _favorite,
                          onTap: _toggleFavorite,
                        ),
                        if (_playlists.isEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 18, 8, 8),
                            child: Text(
                              '还没有自建歌单，点右上角「新建」建一个吧'.tr,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        else
                          ..._playlists.map(
                            (playlist) => _row(
                              context,
                              icon: Icons.queue_music_rounded,
                              title: playlist.name,
                              subtitle: '@count 首'
                                  .trParams({'count': '${playlist.musicCount}'}),
                              selected: _contained.contains(playlist.id),
                              onTap: () => _togglePlaylist(playlist),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 6),
      onTap: onTap,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withOpacity(0.55),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon,
            size: 19, color: iconColor ?? scheme.onPrimaryContainer),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
      ),
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: scheme.primary, size: 22)
          : Icon(Icons.add_circle_outline_rounded,
              color: scheme.outline, size: 22),
    );
  }
}
