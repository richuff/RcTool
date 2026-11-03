import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/controller/wallpaper_controller.dart';
import 'package:rctool/service/folder_opener.dart';
import 'package:rctool/service/resource_importer.dart';
import 'package:rctool/widget/BackGround/back_ground_enum.dart';
import 'package:rctool/widget/app_scaffold.dart';

/// @ClassName WallpaperPage
/// @Description 壁纸管理：每个页面槽位都支持在 App 内「导入替换」——
///              从手机里选一张图自动存进应用目录并立即生效，无需手动拷文件；
///              也可以用「打开目录」交给系统文件管理器查看。
/// @Author richuff
/// @Version 2.0
class WallpaperPage extends StatefulWidget {
  const WallpaperPage({super.key});

  @override
  State<WallpaperPage> createState() => _WallpaperPageState();
}

class _WallpaperPageState extends State<WallpaperPage> {
  final WallpaperController controller = Get.find<WallpaperController>();

  bool _busy = false;
  String? _busySlot;

  Future<void> _refresh({bool toast = true}) async {
    await controller.refresh();
    if (!mounted) return;
    setState(() {});
    if (toast) {
      Get.snackbar(
        '壁纸已刷新'.tr,
        '当前识别到 @count 张自定义图片'.trParams({
          'count': '${controller.fileCount}',
        }),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// 从系统文件选择器选一张图，复制进应用目录作为该槽位的壁纸
  Future<void> _import(BackGroundEnum slot) async {
    if (_busy) return;
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      dialogTitle: '导入替换'.tr,
    );
    final path = result?.files.single.path;
    if (path == null) return;

    if (!mounted) return;
    setState(() {
      _busy = true;
      _busySlot = slot.slot;
    });
    try {
      await ResourceImporter.importWallpaper(slot.slot, path);
      await controller.refresh();
      if (!mounted) return;
      Get.snackbar(
        '已导入壁纸'.tr,
        '${slot.label.tr} · ${result!.files.single.name}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar('壁纸导入失败'.tr, '$error', snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _busySlot = null;
        });
      }
    }
  }

  /// 删除槽位的自定义壁纸，回到内置默认图
  Future<void> _reset(BackGroundEnum slot) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _busySlot = slot.slot;
    });
    try {
      await ResourceImporter.resetWallpaper(slot.slot);
      await controller.refresh();
      if (!mounted) return;
      Get.snackbar('已恢复默认壁纸'.tr, slot.label.tr,
          snackPosition: SnackPosition.BOTTOM);
    } catch (error) {
      Get.snackbar('壁纸导入失败'.tr, '$error', snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _busySlot = null;
        });
      }
    }
  }

  Future<void> _openDirectory() async {
    final path = controller.directoryPath;
    if (path == null) return;
    await FolderOpener.open(path);
  }

  Future<void> _requestAccess() async {
    final granted = await controller.requestAccess();
    if (!granted) {
      Get.snackbar(
        '未获得文件夹访问权限'.tr,
        '将使用应用私有目录，仍可在 App 内正常导入壁纸'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    await _refresh(toast: false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppScaffold(
      title: '壁纸'.tr,
      actions: [
        IconButton(
          tooltip: '刷新壁纸'.tr,
          onPressed: _busy ? null : _refresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: GetBuilder<WallpaperController>(
        builder: (wallpaper) => ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
          children: [
            _folderCard(scheme, wallpaper),
            const SizedBox(height: 12),
            _hintCard(scheme),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                '各页面壁纸'.tr,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: scheme.primary,
                ),
              ),
            ),
            for (final slot in BackGroundEnum.values) ...[
              _slotCard(scheme, slot, wallpaper),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _folderCard(ColorScheme scheme, WallpaperController wallpaper) {
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
                child: Icon(Icons.folder_open_rounded,
                    size: 19, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '壁纸目录'.tr,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      wallpaper.publicAccess
                          ? '公共目录 · 已识别 @count 张自定义图片'.trParams({
                              'count': '${wallpaper.fileCount}',
                            })
                          : '应用私有目录 · App 内导入不受影响'.tr,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openDirectory(),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label:
                      Text('打开壁纸目录'.tr, style: const TextStyle(fontSize: 12.5)),
                ),
              ),
              if (!wallpaper.publicAccess) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _requestAccess,
                    icon: const Icon(Icons.folder_shared_outlined, size: 16),
                    label: Text('授予访问权限'.tr,
                        style: const TextStyle(fontSize: 12.5)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _hintCard(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withOpacity(0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 15, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                '在 App 内选图即可，无需手动拷贝'.tr,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '每个页面卡片都支持「导入替换」：从手机里选一张 jpg / png / webp，'
                    '会自动存进应用目录并立即生效；「恢复默认」会删掉当前自定义图。'
                .tr,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _slotCard(
    ColorScheme scheme,
    BackGroundEnum slot,
    WallpaperController wallpaper,
  ) {
    final custom = slot.isCustom;
    final file = wallpaper.fileFor(slot.slot);
    final busyHere = _busySlot == slot.slot;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surface.withOpacity(0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: custom
              ? scheme.primary.withOpacity(0.35)
              : scheme.outline.withOpacity(0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 2.3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image(
                  key:
                      ValueKey('wp-preview-${slot.slot}-${wallpaper.revision}'),
                  image: slot.imageProvider,
                  fit: BoxFit.cover,
                  opacity: const AlwaysStoppedAnimation<double>(0.9),
                ),
                // 底部渐隐，让标题压在图上也清楚
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 46,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          scheme.surface.withOpacity(0),
                          scheme.surface.withOpacity(0.92),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 8,
                  child: Text(
                    slot.label.tr,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Row(
              children: [
                Icon(
                  custom ? Icons.check_circle_rounded : Icons.image_outlined,
                  size: 15,
                  color: custom ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    custom
                        ? '已使用自定义壁纸 · @name'.trParams({
                            'name': file != null
                                ? file.uri.pathSegments.last
                                : slot.slot,
                          })
                        : '使用内置壁纸 · 导入一张图即可替换'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : () => _import(slot),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    icon: busyHere
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.file_upload_outlined, size: 16),
                    label: Text('导入替换'.tr),
                  ),
                ),
                if (custom) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _reset(slot),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        foregroundColor: scheme.error,
                        side: BorderSide(color: scheme.error.withOpacity(0.4)),
                        textStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      icon: const Icon(Icons.restart_alt_rounded, size: 16),
                      label: Text('恢复默认'.tr),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
