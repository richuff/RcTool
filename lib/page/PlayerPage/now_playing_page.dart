import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/controller/favorite_controller.dart';
import 'package:rctool/controller/music_controller.dart';
import 'package:rctool/repository/entity/Music.dart';
import 'package:rctool/routers/route_path.dart';
import 'package:rctool/widget/lyric_view.dart';
import 'package:rctool/widget/song_actions_sheet.dart';

/// @ClassName NowPlayingPage
/// @Description 全屏播放页：封面取色虚化背景 + 大封面（Hero 过渡）+ 可拖动进度 +
///              播放模式/上一首/播放暂停/下一首/队列，下滑手势收起。
///              进度区独立成子组件，播放进度刷新只重建进度条本身。
/// @Author richuff
/// @Version 1.1
class NowPlayingPage extends StatefulWidget {
  const NowPlayingPage({super.key});

  @override
  State<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends State<NowPlayingPage> {
  final MusicController controller = Get.find<MusicController>();

  double _dragOffset = 0;

  /// 封面 / 歌词两种视图：点封面看歌词，点歌词上的「封面」按钮切回
  bool _showLyrics = false;

  Music? get _music => controller.currentMusic;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final music = _music;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: GestureDetector(
        // 歌词模式下竖直拖动交给列表滚动，避免和「下滑收起」抢手势
        onVerticalDragUpdate: _showLyrics
            ? null
            : (details) {
                final next = _dragOffset + details.delta.dy;
                if (next < 0) return;
                setState(() => _dragOffset = next.clamp(0.0, 460.0));
              },
        onVerticalDragEnd: _showLyrics
            ? null
            : (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (_dragOffset > 110 || velocity > 700) {
                  Get.back();
                  return;
                }
                setState(() => _dragOffset = 0);
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _dragOffset, 0),
          child: music == null
              ? _emptyState(scheme)
              : Stack(
                  children: [
                    Positioned.fill(child: _backdrop(music, scheme)),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              scheme.surface.withOpacity(0.35),
                              scheme.surface.withOpacity(0.55),
                              scheme.surface.withOpacity(0.94),
                            ],
                            stops: const [0, 0.52, 1],
                          ),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Column(
                        children: [
                          _topBar(scheme),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              child: _showLyrics
                                  ? LyricView(
                                      key: ValueKey('lyrics-${music.url}'),
                                      music: music,
                                    )
                                  : GestureDetector(
                                      key: ValueKey('cover-${music.url}'),
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => setState(
                                          () => _showLyrics = true),
                                      child: _cover(music, scheme),
                                    ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                            child: _title(scheme, music),
                          ),
                          const SizedBox(height: 8),
                          const _PlayerProgress(),
                          const SizedBox(height: 2),
                          _controls(scheme, music),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  /// 封面取色虚化背景（ImageFilter 模糊 + 主题色叠加）
  Widget _backdrop(Music music, ColorScheme scheme) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (music.imageUrl.isNotEmpty)
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 34, sigmaY: 34),
            child: Image.network(
              music.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => ColoredBox(
                color: scheme.primaryContainer,
              ),
            ),
          )
        else
          ColoredBox(color: scheme.primaryContainer),
        ColoredBox(color: scheme.surface.withOpacity(0.35)),
      ],
    );
  }

  Widget _topBar(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: '收起'.tr,
            onPressed: () => Get.back(),
            icon: Icon(Icons.keyboard_arrow_down_rounded,
                size: 28, color: scheme.onSurface),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '正在播放'.tr,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '@index / @count'.trParams({
                    'index': '${controller.position.value + 1}',
                    'count': '${controller.musiclist.length}',
                  }),
                  style: TextStyle(
                    fontSize: 10.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: _showLyrics ? '显示封面'.tr : '显示歌词'.tr,
            onPressed: () => setState(() => _showLyrics = !_showLyrics),
            icon: Icon(
              _showLyrics
                  ? Icons.album_rounded
                  : Icons.lyrics_rounded,
              color: _showLyrics ? scheme.primary : scheme.onSurface,
            ),
          ),
          IconButton(
            tooltip: '播放队列'.tr,
            onPressed: () => Get.toNamed(RoutePath.MUSICCHOOSE),
            icon: Icon(Icons.queue_music_rounded, color: scheme.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _cover(Music music, ColorScheme scheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = (constraints.maxHeight - 8).clamp(120.0, 640.0);
        final size = (constraints.maxWidth * 0.74)
            .clamp(120.0, 360.0)
            .clamp(0.0, maxHeight)
            .toDouble();
        return Center(
          child: Hero(
            tag: 'now-playing-cover',
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withOpacity(0.28),
                    blurRadius: 34,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (music.imageUrl.isNotEmpty)
                    Image.network(
                      music.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _coverFallback(scheme),
                    )
                  else
                    _coverFallback(scheme),
                  // 播放中给封面加一层极淡的主色，避免与背景糊在一起
                  if (controller.isplay.value)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            scheme.primary.withOpacity(0.16),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _coverFallback(ColorScheme scheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primaryContainer, scheme.secondaryContainer],
        ),
      ),
      child: Icon(
        Icons.music_note_rounded,
        size: 64,
        color: scheme.onPrimaryContainer.withOpacity(0.7),
      ),
    );
  }

  Widget _title(ColorScheme scheme, Music music) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                music.songName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Builder(
                builder: (context) {
                  final buffering = controller.loadingUrl.value.isNotEmpty &&
                      controller.loadingUrl.value == music.url;
                  return Text(
                    buffering
                        ? '缓存中 · 首次播放需要下载'.tr
                        : (music.decoration.trim().isEmpty
                            ? '未知歌手'.tr
                            : music.decoration),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: buffering ? scheme.primary : scheme.onSurfaceVariant,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        GetBuilder<FavoriteController>(
          builder: (favorite) {
            final isFavorite = favorite.isFavorite(music.id);
            return IconButton(
              tooltip: isFavorite ? '取消收藏'.tr : '收藏到我的喜欢'.tr,
              onPressed: () async {
                if (music.id == null) return;
                try {
                  await favorite.toggle(music.id);
                } catch (error) {
                  Get.snackbar(
                    '收藏失败'.tr,
                    '$error',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              },
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  key: ValueKey(isFavorite),
                  size: 25,
                  color: isFavorite ? scheme.error : scheme.onSurfaceVariant,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _controls(ColorScheme scheme, Music music) {
    final isPlaying = controller.isplay.value;
    final loading = controller.loadingUrl.value.isNotEmpty &&
        controller.loadingUrl.value == music.url;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _modeButton(scheme),
        IconButton(
          tooltip: '上一首'.tr,
          iconSize: 34,
          onPressed: controller.skipPrevious,
          icon: Icon(Icons.skip_previous_rounded, color: scheme.onSurface),
        ),
        // 主播放键
        Material(
          color: scheme.primary,
          shape: const CircleBorder(),
          elevation: 6,
          shadowColor: scheme.primary.withOpacity(0.5),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              if (isPlaying) {
                controller.onPause();
              } else {
                controller.playLocal();
              }
            },
            child: SizedBox(
              width: 72,
              height: 72,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: loading
                      ? SizedBox(
                          key: const ValueKey('buffering'),
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.6,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              scheme.onPrimary,
                            ),
                          ),
                        )
                      : Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          key: ValueKey(isPlaying),
                          size: 40,
                          color: scheme.onPrimary,
                        ),
                ),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: '下一首'.tr,
          iconSize: 34,
          onPressed: controller.skipNext,
          icon: Icon(Icons.skip_next_rounded, color: scheme.onSurface),
        ),
        IconButton(
          tooltip: '添加到歌单'.tr,
          onPressed: () => showSongActions(context, music),
          icon: Icon(Icons.playlist_add_rounded, color: scheme.onSurface),
        ),
      ],
    );
  }

  /// 播放模式：点一下在 列表循环 → 单曲循环 → 随机 之间切换
  Widget _modeButton(ColorScheme scheme) {
    final mode = controller.playMode.value;
    final icon = switch (mode) {
      PlayMode.loop => Icons.repeat_rounded,
      PlayMode.single => Icons.repeat_one_rounded,
      PlayMode.random => Icons.shuffle_rounded,
    };
    final label = switch (mode) {
      PlayMode.loop => '列表循环'.tr,
      PlayMode.single => '单曲循环'.tr,
      PlayMode.random => '随机播放'.tr,
    };
    return Tooltip(
      message: label,
      child: IconButton(
        onPressed: () {
          final next = switch (mode) {
            PlayMode.loop => PlayMode.single,
            PlayMode.single => PlayMode.random,
            PlayMode.random => PlayMode.loop,
          };
          controller.changePlayMode(next);
        },
        icon: Icon(
          icon,
          size: 22,
          color:
              mode == PlayMode.loop ? scheme.onSurfaceVariant : scheme.primary,
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
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.music_note_rounded,
                  size: 40, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 16),
            Text(
              '您还未选择播放的歌曲'.tr,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '去每日推荐或歌单里挑一首吧'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            FilledButton.tonal(
              onPressed: () => Get.back(),
              child: Text('返回'.tr),
            ),
          ],
        ),
      ),
    );
  }
}

/// 进度条：自己订阅播放器进度，避免整页每 200ms 重建一次。
class _PlayerProgress extends StatefulWidget {
  const _PlayerProgress();

  @override
  State<_PlayerProgress> createState() => _PlayerProgressState();
}

class _PlayerProgressState extends State<_PlayerProgress> {
  final MusicController controller = Get.find<MusicController>();

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;

  Duration _position = Duration.zero;
  Duration? _duration;
  bool _seeking = false;
  double _seekValue = 0;
  String? _lastUrl;

  @override
  void initState() {
    super.initState();
    _duration = controller.totalDuration;
    _lastUrl = controller.currentMusic?.url;
    _positionSub =
        controller.player.onPositionChanged.listen((Duration value) {
      if (!mounted) return;
      final url = controller.currentMusic?.url;
      setState(() {
        // 切歌后旧进度立刻失效，避免进度条停在上一首的位置
        if (url != _lastUrl) {
          _lastUrl = url;
          _position = Duration.zero;
          _seeking = false;
          _seekValue = 0;
        }
        if (!_seeking) _position = value;
      });
    });
    _durationSub = controller.player.onDurationChanged.listen((Duration value) {
      if (!mounted) return;
      setState(() => _duration = value);
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
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
    final total = _duration ?? controller.totalDuration;
    final totalMs = total?.inMilliseconds ?? 0;

    final fraction = _seeking
        ? _seekValue
        : (totalMs > 0
            ? (_position.inMilliseconds / totalMs).clamp(0.0, 1.0)
            : 0.0);

    final played = _seeking
        ? Duration(milliseconds: (totalMs * _seekValue).round())
        : _position;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 15),
              activeTrackColor: scheme.primary,
              inactiveTrackColor: scheme.surfaceContainerHighest,
              thumbColor: scheme.primary,
              overlayColor: scheme.primary.withOpacity(0.12),
            ),
            child: Slider(
              value: fraction,
              onChanged: totalMs <= 0
                  ? null
                  : (value) {
                      setState(() {
                        _seeking = true;
                        _seekValue = value;
                      });
                    },
              onChangeEnd: (value) async {
                await controller.seekToFraction(value);
                if (!mounted) return;
                setState(() {
                  _seeking = false;
                  _position =
                      Duration(milliseconds: (totalMs * value).round());
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _fmt(played),
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  _fmt(total),
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
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
