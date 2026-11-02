import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:rctool/repository/SqlLiteConn/lyric_conn.dart';
import 'package:rctool/repository/entity/Music.dart';
import 'package:rctool/repository/entity/lyric.dart';
import 'package:rctool/utils/lrc_parser.dart';

/// 打开歌词编辑面板。返回 true 表示内容已变更（调用方应重新加载歌词）。
Future<bool?> showLyricEditor(BuildContext context, Music music) {
  return Get.bottomSheet<bool>(
    _LyricEditorSheet(music: music),
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: false,
  );
}

class _LyricEditorSheet extends StatefulWidget {
  final Music music;

  const _LyricEditorSheet({required this.music});

  @override
  State<_LyricEditorSheet> createState() => _LyricEditorSheetState();
}

class _LyricEditorSheetState extends State<_LyricEditorSheet> {
  final TextEditingController _controller = TextEditingController();

  LyricRecord? _record;
  int _offsetMs = 0;
  int _lineCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final record = await LyricConn.query(widget.music.url);
    if (!mounted) return;
    setState(() {
      _record = record;
      _controller.text = record?.content ?? '';
      _offsetMs = record?.offsetMs ?? 0;
      _lineCount =
          record == null ? 0 : LyricSheet.parse(record.content).lines.length;
      _loading = false;
    });
  }

  void _updateCount(String value) {
    setState(() {
      _lineCount = LyricSheet.parse(value).lines.length;
    });
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.trim().isEmpty) {
      Get.snackbar('剪贴板是空的'.tr, '先复制一段 LRC 歌词再试'.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    _controller.text = text;
    _updateCount(text);
  }

  Future<void> _save() async {
    final content = _controller.text.trim();
    if (content.isEmpty) {
      Get.snackbar('歌词内容为空'.tr, '粘贴 LRC 文本，或选择「删除歌词」'.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    await LyricConn.save(widget.music.url, content, offsetMs: _offsetMs);
    if (!mounted) return;
    Get.back(result: true);
    Get.snackbar('歌词已保存'.tr, widget.music.songName,
        snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> _delete() async {
    await LyricConn.delete(widget.music.url);
    if (!mounted) return;
    Get.back(result: true);
    Get.snackbar('歌词已删除'.tr, widget.music.songName,
        snackPosition: SnackPosition.BOTTOM);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    // 输入法弹起后收掉非必要的行，把高度都留给输入区
    final compact = keyboard > 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 外层 Get.bottomSheet 已经替键盘让过一次高度，这里只补差额：
        // 两层都完整让位（padding 与高度各让一次）会把面板顶出屏幕上沿。
        final reserved =
            (media.size.height - constraints.maxHeight).clamp(0.0, keyboard);
        final gap = keyboard - reserved;
        final available = math.max(0.0, constraints.maxHeight - gap);
        final height = math.min(
            available, math.max(280.0, available * (compact ? 1 : 0.9)));

        return Padding(
          padding: EdgeInsets.only(bottom: gap),
          child: Container(
            height: height,
            padding:
                EdgeInsets.fromLTRB(16, compact ? 6 : 10, 16, compact ? 8 : 12),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  if (!compact)
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: scheme.outline.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  SizedBox(height: compact ? 4 : 12),
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(Icons.lyrics_outlined,
                            size: 19, color: scheme.onPrimaryContainer),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '导入歌词'.tr,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurface,
                              ),
                            ),
                            Text(
                              widget.music.songName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _paste,
                        icon: const Icon(Icons.content_paste_rounded, size: 17),
                        label: Text('粘贴'.tr),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 32),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      IconButton(
                        tooltip: '关闭'.tr,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Get.back(),
                        icon: Icon(Icons.close_rounded,
                            size: 20, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : Container(
                            decoration: BoxDecoration(
                              color:
                                  scheme.surfaceContainerHigh.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: scheme.outlineVariant.withOpacity(0.4),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            child: TextField(
                              controller: _controller,
                              onChanged: _updateCount,
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              keyboardType: TextInputType.multiline,
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.5,
                                fontFamily: 'monospace',
                                color: scheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                filled: false,
                                border: InputBorder.none,
                                hintText: '[00:12.34] ${'第一句歌词'.tr}\n'
                                    '[00:18.00] ${'第二句歌词'.tr}\n\n'
                                    '${'支持一行多个时间戳、[offset:] 偏移，纯文本也能保存'.tr}',
                                hintStyle: TextStyle(
                                  fontSize: 12,
                                  height: 1.6,
                                  color:
                                      scheme.onSurfaceVariant.withOpacity(0.6),
                                ),
                              ),
                            ),
                          ),
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 10),
                    _offsetRow(scheme),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (_record != null)
                        TextButton.icon(
                          onPressed: _delete,
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 18),
                          label: Text('删除歌词'.tr),
                          style: TextButton.styleFrom(
                            foregroundColor: scheme.error,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Get.back(),
                        child: Text('取消'.tr),
                      ),
                      const SizedBox(width: 6),
                      FilledButton(
                        onPressed: _save,
                        child: Text('保存'.tr),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _offsetRow(ColorScheme scheme) {
    final seconds = _offsetMs / 1000;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.compare_arrows_rounded,
              size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            '歌词偏移'.tr,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          const Spacer(),
          Text(
            '${seconds >= 0 ? '+' : ''}${seconds.toStringAsFixed(1)}s',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
          IconButton(
            tooltip: '提前 0.5 秒'.tr,
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() => _offsetMs -= 500),
            icon: Icon(Icons.remove_circle_outline_rounded,
                size: 19, color: scheme.onSurfaceVariant),
          ),
          IconButton(
            tooltip: '延后 0.5 秒'.tr,
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() => _offsetMs += 500),
            icon: Icon(Icons.add_circle_outline_rounded,
                size: 19, color: scheme.onSurfaceVariant),
          ),
          if (_lineCount > 0)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                '@count 行'.trParams({'count': '$_lineCount'}),
                style: TextStyle(
                  fontSize: 10.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
