import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:headset_connection_event/headset_event.dart';
import 'package:rctool/controller/music_controller.dart';
import 'package:rctool/feature/design/icon_button_no_ripple.dart';
import 'package:rctool/routers/route_path.dart';
import 'package:rctool/utils/notification_helper.dart';
import 'package:rctool/repository/entity/Music.dart';

/// @ClassName MusicList
/// @Description 听音乐页底部播放条：紧凑单行布局（封面 + 歌名 + 上一首/播放/下一首 + 队列），
///             底部一条可拖动的细进度条，整体高度比原来压缩约一半。
/// @Author richuff
/// @Version 2.0
class MusicList extends StatefulWidget {
  const MusicList({super.key});

  @override
  State<MusicList> createState() => _MusicList();
}

class _MusicList extends State<MusicList> {
  final MusicController musicController = Get.find<MusicController>();
  final NotificationHelper notificationHelper = NotificationHelper();
  final _headsetPlugin = HeadsetEvent();

  double _progress = 0.0;
  StreamSubscription<Duration>? _positionSubscription;

  @override
  void initState() {
    super.initState();

    // 请求蓝牙权限并监听蓝牙设备
    _headsetPlugin.requestPermission();
    _headsetPlugin.setListener((val) {
      // 蓝牙断开则暂停，重连则继续播放
      if (val == HeadsetState.DISCONNECT) {
        musicController.onPause();
      } else {
        musicController.playLocal();
      }
    });

    musicController.addListener(_onControllerChanged);

    _positionSubscription =
        musicController.player.onPositionChanged.listen((Duration position) {
      final total = musicController.totalDuration;
      if (total != null && total.inMilliseconds > 0) {
        setState(() {
          _progress =
              (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
        });
      }
    });
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Music? get _current {
    final list = musicController.musiclist;
    final pos = musicController.position.value;
    if (list.isEmpty || pos >= list.length) return null;
    final m = list[pos];
    return m is Music ? m : null;
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    musicController.removeListener(_onControllerChanged);
    super.dispose();
  }

  String _fmt(Duration? duration) {
    if (duration == null) return '--:--';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final current = _current;
    final count = musicController.musiclist.length;
    final isPlaying = musicController.isplay.value;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 2, 12, 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surface.withOpacity(0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.14),
            blurRadius: 12,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap:
                  current == null ? null : () => Get.toNamed(RoutePath.PLAYER),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 6, 2),
                child: Row(
                  children: [
                    // 封面（缩小到 42，整体更紧凑）
                    Hero(
                      tag: 'now-playing-cover',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: current != null && current.imageUrl.isNotEmpty
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
                            current?.songName ?? "您还未选择播放的歌曲".tr,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Builder(builder: (context) {
                            final buffering = current != null &&
                                current.url.isNotEmpty &&
                                musicController.loadingUrl.value == current.url;
                            return Text(
                              buffering
                                  ? '缓存中 · 首次播放需要下载'.tr
                                  : (current?.decoration ?? "未知歌手"),
                              style: TextStyle(
                                color: buffering
                                    ? scheme.primary
                                    : scheme.onSurfaceVariant,
                                fontSize: 11,
                                fontWeight: buffering
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          }),
                        ],
                      ),
                    ),
                    _ctrlButton(
                      scheme,
                      icon: Icons.skip_previous_rounded,
                      tooltip: "上一首".tr,
                      onPressed: () => musicController.skipPrevious(),
                    ),
                    // 播放 / 暂停：实心主色圆钮
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Material(
                        color: scheme.primary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {
                            if (current == null) return;
                            if (isPlaying) {
                              musicController.onPause();
                            } else {
                              musicController.playLocal();
                              notificationHelper.showNewMusicNotification(
                                title: "当前正在播放".tr,
                                body:
                                    "${current.songName}  -----  ${current.decoration}",
                              );
                            }
                          },
                          child: SizedBox(
                            width: 34,
                            height: 34,
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                transitionBuilder: (child, anim) =>
                                    ScaleTransition(scale: anim, child: child),
                                child:
                                    musicController.loadingUrl.value.isNotEmpty
                                        ? SizedBox(
                                            key: const ValueKey('buffering'),
                                            width: 17,
                                            height: 17,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                scheme.onPrimary,
                                              ),
                                            ),
                                          )
                                        : Icon(
                                            isPlaying
                                                ? Icons.pause_rounded
                                                : Icons.play_arrow_rounded,
                                            key: ValueKey(isPlaying),
                                            color: scheme.onPrimary,
                                            size: 21,
                                          ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    _ctrlButton(
                      scheme,
                      icon: Icons.skip_next_rounded,
                      tooltip: "下一首".tr,
                      onPressed: () => musicController.skipNext(),
                    ),
                    // 播放队列入口 + 数量角标
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _ctrlButton(
                          scheme,
                          icon: Icons.queue_music_rounded,
                          tooltip: "播放队列".tr,
                          onPressed: () => Get.toNamed(RoutePath.MUSICCHOOSE),
                        ),
                        if (count > 0)
                          Positioned(
                            right: 2,
                            top: 0,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              constraints: const BoxConstraints(minWidth: 14),
                              height: 14,
                              decoration: BoxDecoration(
                                color: scheme.error,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Center(
                                child: Text(
                                  count <= 99 ? "$count" : "99+",
                                  style: const TextStyle(
                                    fontSize: 9,
                                    height: 1,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 细进度条 + 时间（可拖动）
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    _fmt(musicController.totalDuration == null
                        ? null
                        : musicController.totalDuration! * _progress),
                    style: TextStyle(
                        fontSize: 9.5, color: scheme.onSurfaceVariant),
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2.5,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 5),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 11),
                      activeTrackColor: scheme.primary,
                      inactiveTrackColor: scheme.surfaceContainerHighest,
                      thumbColor: scheme.primary,
                    ),
                    child: SizedBox(
                      height: 20,
                      child: Slider(
                        value: _progress.clamp(0.0, 1.0),
                        onChanged: (value) {
                          setState(() => _progress = value);
                          musicController.setPosition(value * 100);
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 34,
                  child: Text(
                    _fmt(musicController.totalDuration),
                    textAlign: TextAlign.end,
                    style: TextStyle(
                        fontSize: 9.5, color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverFallback(ColorScheme scheme) => _CoverFallback(scheme: scheme);

  /// 统一的紧凑图标按钮
  Widget _ctrlButton(
    ColorScheme scheme, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButtonNoRipple(
      hoverColor: scheme.primaryContainer,
      focusColor: scheme.primaryContainer,
      highlightColor: scheme.secondaryContainer,
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 34, height: 34),
      onPressed: onPressed,
      icon: Icon(icon, color: scheme.onSurface, size: 21),
    );
  }
}

class _CoverFallback extends StatelessWidget {
  final ColorScheme scheme;
  const _CoverFallback({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.music_note,
        size: 20,
        color: scheme.onPrimaryContainer,
      ),
    );
  }
}
