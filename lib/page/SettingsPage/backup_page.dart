import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/controller/favorite_controller.dart';
import 'package:rctool/controller/wallpaper_controller.dart';
import 'package:rctool/service/backup_service.dart';
import 'package:rctool/service/folder_opener.dart';
import 'package:rctool/utils/size_format.dart';
import 'package:rctool/widget/app_scaffold.dart';
import 'package:rctool/widget/slide_fade_in.dart';

/// @ClassName BackupPage
/// @Description 数据备份与恢复：把歌单、收藏、歌词和设置导出成 JSON，
///             换设备时从同一个目录里挑一份恢复即可。
/// @Author richuff
/// @Version 1.0
class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  List<BackupFile> _files = const [];
  bool _loading = true;
  bool _busy = false;
  String _directory = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final dir = await BackupService.backupDir();
      final files = await BackupService.list();
      if (!mounted) return;
      setState(() {
        _directory = dir.path;
        _files = files;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createBackup() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final file = await BackupService.export();
      await _load();
      Get.snackbar(
        '备份完成'.tr,
        '已保存到 @name'.trParams({'name': file.uri.pathSegments.last}),
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar('备份失败'.tr, '$error', snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore(BackupFile backup) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('恢复备份'.tr),
        content: Text(
          '将把「@name」里的歌单、收藏和歌词合并到本机，已有的数据不会被删除。'
              .trParams({'name': backup.fileName}),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('取消'.tr),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text('恢复'.tr),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      final result = await BackupService.restore(backup.file);
      // 收藏与壁纸（语言/主题等设置）需要重新读取
      if (Get.isRegistered<FavoriteController>()) {
        await Get.find<FavoriteController>().refresh();
      }
      if (Get.isRegistered<WallpaperController>()) {
        await Get.find<WallpaperController>().refresh();
      }
      Get.snackbar(
        '已恢复'.tr,
        '@playlists 个歌单 · @favorites 首收藏 · @lyrics 份歌词'.trParams({
          'playlists': '${result.playlists}',
          'favorites': '${result.favorites}',
          'lyrics': '${result.lyrics}',
        }),
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar('恢复失败'.tr, '$error', snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(BackupFile backup) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('删除备份'.tr),
        content: Text(
          '确定删除「@name」吗？'.trParams({'name': backup.fileName}),
        ),
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
    );
    if (confirmed != true) return;
    try {
      await backup.file.delete();
    } catch (_) {
      // 文件已不存在时忽略
    }
    await _load();
  }

  Future<void> _openDirectory() async {
    if (_directory.isEmpty) return;
    await FolderOpener.open(_directory);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppScaffold(
      title: '备份与恢复'.tr,
      actions: [
        IconButton(
          tooltip: '刷新'.tr,
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        children: stagger([
          _introCard(scheme),
          const SizedBox(height: 12),
          _actionCard(scheme),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                Text(
                  '备份文件'.tr,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: scheme.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  '@count 个'.trParams({'count': '${_files.length}'}),
                  style: TextStyle(
                    fontSize: 11.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_files.isEmpty)
            _emptyCard(scheme)
          else
            for (final backup in _files) ...[
              _backupTile(scheme, backup),
              const SizedBox(height: 10),
            ],
        ]),
      ),
    );
  }

  Widget _introCard(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: scheme.surface.withOpacity(0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.inventory_2_outlined,
                    size: 19, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '备份内容'.tr,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '歌单 · 收藏 · 歌词 · 播放设置'.tr,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '备份只包含歌单结构和设置，不含音频文件；恢复时按歌单名合并，本机已有的数据不会被删除。'.tr,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _openDirectory,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 40),
              textStyle:
                  const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
            icon: const Icon(Icons.open_in_new_rounded, size: 17),
            label: Text('打开备份目录'.tr),
          ),
        ],
      ),
    );
  }

  Widget _actionCard(ColorScheme scheme) {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _busy ? null : _createBackup,
        icon: _busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save_alt_rounded, size: 19),
        label: Text(
          '立即备份'.tr,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
        ),
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }

  Widget _emptyCard(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
      decoration: BoxDecoration(
        color: scheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 40, color: scheme.outline),
          const SizedBox(height: 10),
          Text(
            '还没有备份文件'.tr,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '点上面的「立即备份」生成第一份'.tr,
            style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _backupTile(ColorScheme scheme, BackupFile backup) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface.withOpacity(0.94),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _busy ? null : () => _restore(backup),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.description_outlined,
                      size: 18, color: scheme.onSecondaryContainer),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        backup.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@playlists 个歌单 · @favorites 首收藏 · @size'.trParams({
                          'playlists': '${backup.playlists}',
                          'favorites': '${backup.favorites}',
                          'size': formatBytes(backup.size),
                        }),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '删除备份'.tr,
                  onPressed: _busy ? null : () => _delete(backup),
                  icon: Icon(Icons.delete_outline_rounded,
                      size: 19, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
