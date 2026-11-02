import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/controller/music_controller.dart';
import 'package:rctool/repository/entity/Music.dart';
import 'package:rctool/routers/route_path.dart';

/// @ClassName NowPlayingBar
/// @Description 迷你播放条：展示当前播放歌曲的封面、歌名、进度与播放/暂停，
///             队列为空时自动隐藏。用于「每日推荐」等非播放页的底部。
/// @Author richuff
/// @Version 1.0
class NowPlayingBar extends StatefulWidget {
  final EdgeInsets margin;
  final bool showNext;

  const NowPlayingBar({
    super.key,
    this.margin = const EdgeInsets.fromLTRB(10, 4, 10, 10),
    this.showNext = true,
  });

  @override
  State<NowPlayingBar> createState() => _NowPlayingBarState();
}

class _NowPlayingBarState extends State<NowPlayingBar> {
  final MusicController controller = Get.find<MusicController>();
  StreamSubscription<Duration>? _positionSubscription;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onControllerChanged);
    _positionSubscription =
        controller.player.onPositionChanged.listen((Duration position) {
      final total = controller.totalDuration;
      if (total != null && total.inMilliseconds > 0 && mounted) {
        setState(() {
          _progress = (position.inMilliseconds / total.inMilliseconds)
              .clamp(0.0, 1.0);
        });
      }
    });
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  Music? get _current {
    final list = controller.musiclist;
    final pos = controller.position.value;
    if (list.isEmpty || pos >= list.length) return null;
    final item = list[pos];
    return item is Music ? item : null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final current = _current;
    final isPlaying = controller.isplay.value;

    return AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      alignment: Alignment.bottomCenter,
      child: current == null
          ? const SizedBox(width: double.infinity)
          : Container(
              margin: widget.margin,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outline.withOpacity(0.18)),
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withOpacity(0.16),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Get.toNamed(RoutePath.PLAYER),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 播放进度
                      ClipRect(
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 2.5,
                          backgroundColor: scheme.surfaceContainerHighest,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(scheme.primary),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
                        child: Row(
                          children: [
                            Hero(
                              tag: 'now-playing-cover',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: current.imageUrl.isNotEmpty
                                    ? Image.network(
                                        current.imageUrl,
                                        width: 42,
                                        height: 42,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _coverFallback(scheme),
                                      )
                                    : _coverFallback(scheme),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    current.songName,
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
                                    controller.loadingUrl.value.isNotEmpty &&
                                            controller.loadingUrl.value ==
                                                current.url
                                        ? '缓存中 · 首次播放需要下载'.tr
                                        : current.decoration,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: controller.loadingUrl.value ==
                                              current.url
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: controller.loadingUrl.value ==
                                              current.url
                                          ? scheme.primary
                                          : scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: isPlaying ? '暂停'.tr : '播放'.tr,
                              onPressed: () {
                                if (isPlaying) {
                                  controller.onPause();
                                } else {
                                  controller.playLocal();
                                }
                              },
                              icon: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                transitionBuilder: (child, animation) =>
                                    ScaleTransition(
                                        scale: animation, child: child),
                                child: controller.loadingUrl.value ==
                                            current.url &&
                                        controller.loadingUrl.value.isNotEmpty
                                    ? SizedBox(
                                        key: const ValueKey('buffering'),
                                        width: 26,
                                        height: 26,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  scheme.primary),
                                        ),
                                      )
                                    : Icon(
                                        isPlaying
                                            ? Icons.pause_circle_filled
                                            : Icons.play_circle_fill,
                                        key: ValueKey(isPlaying),
                                        size: 36,
                                        color: scheme.primary,
                                      ),
                              ),
                            ),
                            if (widget.showNext)
                              IconButton(
                                tooltip: '下一首'.tr,
                                onPressed: controller.skipNext,
                                icon: Icon(Icons.skip_next_rounded,
                                    color: scheme.onSurfaceVariant),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _coverFallback(ColorScheme scheme) {
    return Container(
      width: 42,
      height: 42,
      color: scheme.primaryContainer,
      child: Icon(Icons.music_note, size: 20, color: scheme.onPrimaryContainer),
    );
  }
}
