import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:rctool/service/external_storage.dart';
import 'package:rctool/service/live2d_model_library.dart';

/// @ClassName Live2DModelSheet
/// @Description 模型选择面板：列出内置 Haru 与外部目录扫描到的所有模型，
///              支持重新扫描、复制模型目录，选中后由页面重建 WebView 加载。
/// @Author richuff
/// @Version 1.0
class Live2DModelSheet extends StatefulWidget {
  final String? selectedId;

  /// 由页面提供扫描逻辑，扫描结果同时回写到页面状态
  final Future<List<Live2DModelEntry>> Function() onScan;

  const Live2DModelSheet({
    super.key,
    required this.onScan,
    this.selectedId,
  });

  @override
  State<Live2DModelSheet> createState() => _Live2DModelSheetState();
}

class _Live2DModelSheetState extends State<Live2DModelSheet> {
  List<Live2DModelEntry> _models = const [];
  String _directory = '';
  bool _scanning = true;

  @override
  void initState() {
    super.initState();
    _scan();
    _loadDirectory();
  }

  Future<void> _loadDirectory() async {
    final path = await Live2DModelLibrary.directoryPath();
    if (!mounted) return;
    setState(() => _directory = path);
  }

  Future<void> _scan() async {
    setState(() => _scanning = true);
    final models = await widget.onScan();
    if (!mounted) return;
    setState(() {
      _models = models;
      _scanning = false;
    });
  }

  Future<void> _copyDirectory() async {
    if (_directory.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _directory));
    Get.snackbar('已复制'.tr, _directory, snackPosition: SnackPosition.BOTTOM);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final height = MediaQuery.of(context).size.height * 0.66;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.outline.withOpacity(0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 8, 4),
            child: Row(
              children: [
                Icon(Icons.face_retouching_natural,
                    size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  '选择模型'.tr,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${_models.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: '重新扫描'.tr,
                  visualDensity: VisualDensity.compact,
                  onPressed: _scanning ? null : _scan,
                  icon: _scanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.refresh_rounded,
                          size: 20, color: scheme.primary),
                ),
              ],
            ),
          ),
          Expanded(
            child: _scanning && _models.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                    itemCount: _models.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final model = _models[index];
                      final selected = model.id == widget.selectedId;
                      return _modelTile(scheme, model, selected);
                    },
                  ),
          ),
          _directoryFooter(scheme),
        ],
      ),
    );
  }

  Widget _modelTile(
    ColorScheme scheme,
    Live2DModelEntry model,
    bool selected,
  ) {
    return Material(
      color: selected
          ? scheme.primaryContainer.withOpacity(0.55)
          : scheme.surfaceContainerHighest.withOpacity(0.45),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Get.back(result: model),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected
                      ? scheme.primary.withOpacity(0.16)
                      : scheme.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  model.builtIn
                      ? Icons.inventory_2_outlined
                      : Icons.folder_open_rounded,
                  size: 19,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      model.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      model.builtIn
                          ? '随包内置'.tr
                          : '外部目录 · ${model.id.replaceFirst('ext:', '')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded,
                    size: 20, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _directoryFooter(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(color: scheme.outline.withOpacity(0.18)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.folder_outlined, size: 14, color: scheme.primary),
              const SizedBox(width: 5),
              Text(
                '模型目录'.tr,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const Spacer(),
              if (ExternalStorage.instance.publicAccess)
                Text(
                  '公共目录'.tr,
                  style: TextStyle(
                    fontSize: 10,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              IconButton(
                tooltip: '复制路径'.tr,
                visualDensity: VisualDensity.compact,
                onPressed: _directory.isEmpty ? null : _copyDirectory,
                icon: Icon(Icons.copy_rounded,
                    size: 16, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          Text(
            _directory.isEmpty ? '—' : _directory,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              height: 1.4,
              fontFamily: 'monospace',
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '把包含 .model3.json 的模型文件夹放进该目录，点右上角重新扫描即可加载。'.tr,
            style: TextStyle(
              fontSize: 10.5,
              height: 1.4,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
