import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:rctool/controller/wallpaper_controller.dart';
import 'package:rctool/widget/BackGround/back_ground_enum.dart';
import 'package:rctool/widget/app_scaffold.dart';

/// @ClassName WallpaperPage
/// @Description 壁纸管理：展示当前壁纸目录、每页正在用的图，并支持从外部目录
///              热替换（放进文件 → 刷新即可，无需重新安装）。
/// @Author richuff
/// @Version 1.0
class WallpaperPage extends StatefulWidget {
  const WallpaperPage({super.key});

  @override
  State<WallpaperPage> createState() => _WallpaperPageState();
}

class _WallpaperPageState extends State<WallpaperPage> {
  final WallpaperController controller = Get.find<WallpaperController>();

  bool _busy = false;

  Future<void> _refresh({bool toast = true}) async {
    if (_busy) return;
    setState(() => _busy = true);
    await controller.refresh();
    if (!mounted) return;
    setState(() => _busy = false);
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

  Future<void> _copyPath() async {
    final path = controller.directoryPath;
    if (path == null) return;
    await Clipboard.setData(ClipboardData(text: path));
    Get.snackbar('已复制'.tr, path, snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> _requestAccess() async {
    final granted = await controller.requestAccess();
    if (!granted) {
      Get.snackbar(
        '未获得文件夹访问权限'.tr,
        '将使用应用私有目录，仍可替换壁纸，但需要用文件管理器找到该路径'.tr,
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
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded),
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
              _slotCard(scheme, slot, wallpaper.revision),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _folderCard(ColorScheme scheme, WallpaperController wallpaper) {
    final path = wallpaper.directoryPath ?? '正在解析目录…'.tr;
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
                          ? '公共目录 · 文件管理器可直接访问'.tr
                          : '应用私有目录 · 需要文件管理器进入 Android/data'.tr,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '复制路径'.tr,
                visualDensity: VisualDensity.compact,
                onPressed: _copyPath,
                icon: Icon(Icons.copy_rounded,
                    size: 18, color: scheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withOpacity(0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SelectableText(
              path,
              style: TextStyle(
                fontSize: 11,
                height: 1.35,
                fontFamily: 'monospace',
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          if (!wallpaper.publicAccess) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _requestAccess,
                icon: const Icon(Icons.folder_shared_outlined, size: 17),
                label: Text('授予文件夹访问权限'.tr,
                    style: const TextStyle(fontSize: 12.5)),
              ),
            ),
          ],
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
              Icon(Icons.auto_awesome_rounded,
                  size: 15, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                '放图即换，无需重装'.tr,
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
            '把 jpg / png / webp 放进上面的目录，文件名用 home、live2d、music、about 分别对应四个页面；'
                '放一张 default 则四个页面统一生效。回到这里点右上角刷新即可。'
                .tr,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '删掉文件就会恢复内置默认图。'.tr,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: scheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _slotCard(ColorScheme scheme, BackGroundEnum slot, int revision) {
    final custom = slot.isCustom;
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
                  key: ValueKey('wp-preview-${slot.slot}-$revision'),
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
                            'name': '${slot.slot}.jpg',
                          })
                        : '使用内置壁纸 · 放入 @name 即可替换'.trParams({
                            'name': '${slot.slot}.jpg',
                          }),
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
        ],
      ),
    );
  }
}
