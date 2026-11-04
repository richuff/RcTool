import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/constant/playlist_const.dart';
import 'package:rctool/repository/SqlLiteConn/favorite_conn.dart';
import 'package:rctool/repository/SqlLiteConn/playlist_conn.dart';
import 'package:rctool/repository/entity/Music.dart';
import 'package:rctool/repository/entity/playlist.dart';
import 'package:rctool/routers/route_path.dart';
import 'package:rctool/widget/app_scaffold.dart';
import 'package:rctool/widget/settings_ui.dart';
import 'package:rctool/widget/slide_fade_in.dart';

/// @ClassName Album
/// @Description 歌单列表页：新建走弹窗、删除需点击删除按钮并二次确认，
///             点击歌单进入独立的歌单详情页；「我的喜欢」作为默认歌单置顶。
/// @Author richuff
/// @Version 3.0
class Album extends StatefulWidget {
  const Album({super.key});

  @override
  State<Album> createState() => _Album();
}

class _Album extends State<Album> {
  List<Playlist> playlists = [];
  int favoriteCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final all = await PlaylistConn.queryPlaylists();
    final List<Music> favorites = await FavoriteConn.queryFavoriteMusic();
    if (!mounted) return;
    setState(() {
      // 每日推荐生成的内部歌单不进入列表
      playlists = all.where((item) => !isInternalPlaylist(item)).toList();
      favoriteCount = favorites.length;
      _loading = false;
    });
  }

  Future<void> _openPlaylist(Playlist playlist) async {
    await Get.toNamed(RoutePath.PLAYLIST, arguments: playlist);
    // 从详情页返回后刷新歌曲数量
    await _loadData();
  }

  Future<void> _showCreateDialog() async {
    final created = await Get.dialog<bool>(
      const _CreatePlaylistDialog(),
      barrierDismissible: true,
    );
    if (created == true) {
      await _loadData();
      Get.snackbar(
        '已创建'.tr,
        '新歌单已经建好了，点进去添加歌曲吧'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _deletePlaylist(Playlist playlist) async {
    final confirmed = await Get.dialog<bool>(
          AlertDialog(
            title: Text('删除歌单'.tr),
            content: Text('确定删除「@name」吗？歌单中的歌曲不会从曲库移除。'
                .trParams({'name': playlist.name})),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: Text('取消'.tr),
              ),
              FilledButton(
                onPressed: () => Get.back(result: true),
                child: Text('删除'.tr),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    await PlaylistConn.deletePlaylist(playlist.id!);
    await _loadData();
    Get.snackbar('已删除'.tr, '歌单「@name」已删除'.trParams({'name': playlist.name}),
        snackPosition: SnackPosition.BOTTOM);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppScaffold(
      nowPlaying: true,
      title: '歌单'.tr,
      actions: [
        IconButton(
          tooltip: '新建歌单'.tr,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
          onPressed: _showCreateDialog,
          icon: const Icon(Icons.add_rounded),
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
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  children: stagger([
                    SettingsSection(
                      title: '默认歌单'.tr,
                      icon: Icons.favorite_rounded,
                      children: [
                        _PlaylistRow(
                          icon: Icons.favorite_rounded,
                          title: playlistDisplayName(kFavoritePlaylistName),
                          subtitle: '收藏的歌曲都会汇总到这里'.tr,
                          count: favoriteCount,
                          highlight: true,
                          onTap: () => _openPlaylist(
                            favoritePlaylist(musicCount: favoriteCount),
                          ),
                        ),
                      ],
                    ),
                    SettingsSection(
                      title: '我的歌单'.tr,
                      icon: Icons.queue_music_rounded,
                      children: [
                        if (playlists.isEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                            child: Text(
                              '还没有自建歌单，点右上角的「+」新建一个吧'.tr,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        else
                          ...playlists.map(
                            (playlist) => _PlaylistRow(
                              icon: Icons.queue_music_rounded,
                              title: playlistDisplayName(playlist.name),
                              subtitle: '创建于 @date'.trParams({
                                'date': _formatDate(playlist.createdAt),
                              }),
                              count: playlist.musicCount,
                              onTap: () => _openPlaylist(playlist),
                              onDelete: () => _deletePlaylist(playlist),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '歌单只保存在本机，歌曲从曲库中添加，不会重复占用存储。'.tr,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
      ),
    );
  }

  String _formatDate(int millis) {
    if (millis <= 0) return '-';
    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

/// 歌单行：与设置页的选项行保持同一套视觉
class _PlaylistRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int count;
  final bool highlight;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _PlaylistRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.onTap,
    this.highlight = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(14, 2, 8, 2),
      onTap: onTap,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: highlight
              ? scheme.error.withOpacity(0.14)
              : scheme.primaryContainer.withOpacity(0.65),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(
          icon,
          size: 20,
          color: highlight ? scheme.error : scheme.onPrimaryContainer,
        ),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '@name · @count 首'.trParams({
          'name': subtitle,
          'count': '$count',
        }),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onDelete != null)
            IconButton(
              tooltip: '删除歌单'.tr,
              visualDensity: VisualDensity.compact,
              onPressed: onDelete,
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: scheme.error,
              ),
            ),
          Icon(Icons.chevron_right_rounded, size: 20, color: scheme.outline),
        ],
      ),
    );
  }
}

/// 新建歌单弹窗：名称输入 + 重名校验，创建完成后返回 true
class _CreatePlaylistDialog extends StatefulWidget {
  const _CreatePlaylistDialog();

  @override
  State<_CreatePlaylistDialog> createState() => _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends State<_CreatePlaylistDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = '请输入歌单名称'.tr);
      return;
    }
    if (name.length > 30) {
      setState(() => _error = '名称太长啦，30 个字以内'.tr);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    if (await PlaylistConn.existsByName(name)) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = '已经有同名歌单了，换个名字试试'.tr;
      });
      return;
    }
    await PlaylistConn.insertPlaylist(name);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: scheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SettingsHeader(
              icon: Icons.queue_music_rounded,
              title: '新建歌单'.tr,
              subtitle: '给这个歌单取一个名字'.tr,
              onClose: () => Navigator.of(context).pop(false),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              maxLength: 30,
              onSubmitted: (_) => _submit(),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              decoration: InputDecoration(
                labelText: '歌单名称'.tr,
                hintText: '比如：深夜循环'.tr,
                errorText: _error,
                counterText: '',
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withOpacity(0.5),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: scheme.primary, width: 1.4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('取消'.tr),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: Text(_submitting ? '创建中…'.tr : '创建'.tr),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
