import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/controller/music_controller.dart';
import 'package:rctool/repository/SqlLiteConn/lyric_conn.dart';
import 'package:rctool/repository/entity/Music.dart';
import 'package:rctool/utils/lrc_parser.dart';
import 'package:rctool/widget/lyric_editor_sheet.dart';

/// @ClassName LyricView
/// @Description 歌词视图：按播放进度高亮当前行并自动居中，支持点行跳转、
///              手动滚动后「回到当前」、导入 / 编辑 / 偏移微调。
///              行高固定，靠上下留白让首尾行也能落到画面中央。
/// @Author richuff
/// @Version 1.0
class LyricView extends StatefulWidget {
  final Music music;

  const LyricView({super.key, required this.music});

  @override
  State<LyricView> createState() => _LyricViewState();
}

class _LyricViewState extends State<LyricView> {
  static const double _lineHeight = 54;

  final MusicController _controller = Get.find<MusicController>();
  final ScrollController _scroll = ScrollController();

  StreamSubscription<Duration>? _positionSub;
  LyricSheet _sheet = LyricSheet.empty;
  Duration _userOffset = Duration.zero;
  Duration _position = Duration.zero;
  int _index = -1;
  bool _loading = true;
  bool _follow = true;

  @override
  void initState() {
    super.initState();
    _load();
    _positionSub = _controller.player.onPositionChanged.listen(_onPosition);
  }

  @override
  void didUpdateWidget(covariant LyricView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 切歌后重新加载歌词。延后一帧，避免在构建过程中 setState
    if (oldWidget.music.url != widget.music.url) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final url = widget.music.url;
    setState(() => _loading = true);
    LyricSheet sheet = LyricSheet.empty;
    Duration userOffset = Duration.zero;
    try {
      final record = await LyricConn.query(url);
      if (record != null) {
        sheet = LyricSheet.parse(record.content);
        userOffset = Duration(milliseconds: record.offsetMs);
      }
    } catch (_) {
      // 读取失败按无歌词处理，不影响播放
    }
    if (!mounted || url != widget.music.url) return;
    setState(() {
      _sheet = sheet;
      _userOffset = userOffset;
      _loading = false;
      _follow = true;
      _index = sheet.isEmpty
          ? -1
          : sheet.indexAt(_position, userOffset: userOffset);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollTo(_index, animate: false);
    });
  }

  void _onPosition(Duration position) {
    _position = position;
    if (!mounted || _sheet.isEmpty || !_sheet.synced) return;
    final index = _sheet.indexAt(position, userOffset: _userOffset);
    if (index == _index) return;
    setState(() => _index = index);
    if (_follow) _scrollTo(index);
  }

  void _scrollTo(int index, {bool animate = true}) {
    if (index < 0 || !_scroll.hasClients) return;
    final target = (index * _lineHeight).clamp(
      _scroll.position.minScrollExtent,
      _scroll.position.maxScrollExtent,
    );
    if (animate) {
      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scroll.jumpTo(target);
    }
  }

  Future<void> _openEditor() async {
    final changed = await showLyricEditor(context, widget.music);
    if (changed == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
    }

    if (_sheet.isEmpty) return _emptyState(scheme);

    return Column(
      children: [
        _toolbar(scheme),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final pad = ((constraints.maxHeight - _lineHeight) / 2)
                  .clamp(0.0, double.infinity);
              return NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  // 用户主动拖动时暂停跟随，避免抢滚动
                  if (notification is ScrollStartNotification &&
                      notification.dragDetails != null &&
                      _follow) {
                    setState(() => _follow = false);
                  }
                  return false;
                },
                child: Stack(
                  children: [
                    ListView.builder(
                      controller: _scroll,
                      padding: EdgeInsets.symmetric(vertical: pad),
                      itemExtent: _lineHeight,
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      itemCount: _sheet.lines.length,
                      itemBuilder: (context, index) =>
                          _line(scheme, index),
                    ),
                    if (!_follow)
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: _backToCurrent(scheme),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _toolbar(ColorScheme scheme) {
    final hasOffset = _userOffset != Duration.zero;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 16, 4),
      child: Row(
        children: [
          if (_sheet.tags['ti'] != null)
            Flexible(
              child: Text(
                _sheet.tags['ti']!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant.withOpacity(0.8),
                ),
              ),
            ),
          if (hasOffset) ...[
            const SizedBox(width: 6),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _changeOffset(Duration.zero),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_userOffset.inMilliseconds > 0 ? '+' : ''}'
                  '${(_userOffset.inMilliseconds / 1000).toStringAsFixed(1)}s',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ),
            ),
          ],
          const Spacer(),
          InkWell(
            borderRadius: BorderRadius.circular(9),
            onTap: _openEditor,
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_note_rounded,
                      size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 3),
                  Text(
                    '编辑歌词'.tr,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changeOffset(Duration offset) async {
    final url = widget.music.url;
    setState(() => _userOffset = offset);
    await LyricConn.updateOffset(url, offset.inMilliseconds);
    if (!mounted) return;
    setState(() {
      _index = _sheet.indexAt(
        _position,
        userOffset: _userOffset,
      );
    });
    _scrollTo(_index);
  }

  Widget _line(ColorScheme scheme, int index) {
    final line = _sheet.lines[index];
    final isCurrent = _sheet.synced && index == _index;
    final distance = _sheet.synced ? (index - _index).abs() : 99;

    final Color color;
    final double size;
    final FontWeight weight;
    if (!_sheet.synced) {
      color = scheme.onSurface.withOpacity(0.86);
      size = 14.5;
      weight = FontWeight.w500;
    } else if (isCurrent) {
      color = scheme.primary;
      size = 16;
      weight = FontWeight.w800;
    } else if (distance == 1) {
      color = scheme.onSurface.withOpacity(0.72);
      size = 14.5;
      weight = FontWeight.w600;
    } else {
      color = scheme.onSurfaceVariant.withOpacity(
        (0.62 - distance * 0.05).clamp(0.22, 0.62),
      );
      size = 14;
      weight = FontWeight.w500;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _sheet.synced
          ? () async {
              setState(() => _follow = true);
              await _controller.player.seek(line.time);
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        alignment: Alignment.center,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
          style: TextStyle(
            fontSize: size,
            height: 1.35,
            fontWeight: weight,
            color: color,
            letterSpacing: 0.2,
          ),
          child: Text(
            line.text,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _backToCurrent(ColorScheme scheme) {
    return Material(
      color: scheme.primary.withOpacity(0.14),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          setState(() => _follow = true);
          _scrollTo(_index);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.my_location_rounded, size: 13, color: scheme.primary),
              const SizedBox(width: 4),
              Text(
                '回到当前'.tr,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(ColorScheme scheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lyrics_outlined,
                  size: 30, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 12),
            Text(
              '暂无歌词'.tr,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '导入 LRC 歌词后，这里会跟着播放进度滚动'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            FilledButton.tonalIcon(
              onPressed: _openEditor,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text('导入歌词'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
