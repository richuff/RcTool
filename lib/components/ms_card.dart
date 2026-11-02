import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/controller/favorite_controller.dart';
import 'package:rctool/controller/music_controller.dart';
import 'package:rctool/repository/entity/Music.dart';
import 'package:rctool/utils/notification_helper.dart';

/// @ClassName MSCard
/// @Description 正在播放卡片：封面铺满 + 底部渐隐蒙层，歌名/歌手叠在封面上，
///             右上角收藏、右下角播放/暂停；尺寸由外部按可用空间传入，避免小屏溢出。
/// @Author richuff
/// @Version 2.0
class MSCard extends StatefulWidget {
  final int? id;
  final String url;
  final String image;
  final String decoration;
  final String songName;
  final double width;
  final double height;

  const MSCard(
    this.id,
    this.url,
    this.image,
    this.songName,
    this.decoration, {
    super.key,
    this.width = 300,
    this.height = 500,
  });

  @override
  State<MSCard> createState() => _MSCard();
}

class _MSCard extends State<MSCard> {
  final NotificationHelper notificationHelper = NotificationHelper();
  final MusicController musicController = Get.find<MusicController>();
  final FavoriteController favoriteController = Get.find<FavoriteController>();

  /// 本地收藏态：点击时立刻翻转，避免等待数据库与控制器刷新才变红。
  bool _isFavorite = false;

  bool get _isEmpty =>
      widget.id == null && widget.url.isEmpty && widget.image.isEmpty;

  @override
  void initState() {
    super.initState();
    _isFavorite = favoriteController.isFavorite(widget.id);
    favoriteController.addListener(_syncFavorite);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await favoriteController.ensureLoaded();
      _syncFavorite();
    });
  }

  @override
  void didUpdateWidget(covariant MSCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _isFavorite = favoriteController.isFavorite(widget.id);
    }
  }

  /// 控制器状态变化时同步（其它页面取消/新增收藏也能跟上）。
  void _syncFavorite() {
    if (!mounted) return;
    final latest = favoriteController.isFavorite(widget.id);
    if (latest != _isFavorite) {
      setState(() => _isFavorite = latest);
    }
  }

  Future<void> _toggleFavorite() async {
    if (widget.id == null) return;
    final target = !_isFavorite;
    setState(() => _isFavorite = target);
    try {
      await favoriteController.toggle(widget.id);
      _syncFavorite();
    } catch (e) {
      if (mounted) setState(() => _isFavorite = !target);
      Get.snackbar("收藏失败".tr, "$e", snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  void dispose() {
    favoriteController.removeListener(_syncFavorite);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final music = Music(
      widget.id,
      widget.url,
      widget.image,
      widget.songName,
      widget.decoration,
    );

    return Container(
      width: widget.width,
      height: widget.height,
      margin: const EdgeInsets.only(right: 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.22),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 封面底图
          if (widget.image.isNotEmpty)
            Image.network(
              widget.image,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(scheme),
            )
          else
            _placeholder(scheme),
          // 底部渐隐蒙层，保证文字在任何封面上都可读
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.35, 0.68, 1],
                colors: [
                  Colors.black.withOpacity(0.02),
                  Colors.black.withOpacity(0.45),
                  Colors.black.withOpacity(0.82),
                ],
              ),
            ),
          ),
          // 收藏
          if (!_isEmpty)
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                color: Colors.black.withOpacity(0.32),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _toggleFavorite,
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(scale: anim, child: child),
                        child: Icon(
                          _isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          key: ValueKey(_isFavorite),
                          size: 21,
                          color: _isFavorite
                              ? scheme.error
                              : Colors.white.withOpacity(0.92),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // 歌名 / 歌手
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isEmpty ? '未选择播放的歌曲'.tr : widget.songName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 21,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Colors.black54, blurRadius: 6),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isEmpty ? '从下面的列表里挑一首吧'.tr : widget.decoration,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.white.withOpacity(0.82),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GetBuilder<MusicController>(
                      builder: (controller) {
                        final playing = controller.isPlayingMusic(music);
                        return _playButton(context, controller, music, playing);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _playButton(
    BuildContext context,
    MusicController controller,
    Music music,
    bool playing,
  ) {
    final scheme = Theme.of(context).colorScheme;
    // 未播放态使用主题 surface（暗色下是深色底 + 主色图标），避免暗色主题里出现刺眼的白块
    return Material(
      color: playing ? scheme.primary : scheme.surface,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          if (widget.url.isEmpty) return;
          controller.playOrPauseMusic(music);
          if (!playing) {
            notificationHelper.showNewMusicNotification(
              title: "当前正在播放".tr,
              body: "${widget.songName}  -----  ${widget.decoration}",
            );
          }
        },
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: controller.loadingUrl.value == widget.url &&
                      widget.url.isNotEmpty
                  ? SizedBox(
                      key: const ValueKey('buffering'),
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          playing ? scheme.onPrimary : scheme.primary,
                        ),
                      ),
                    )
                  : Icon(
                      playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      key: ValueKey(playing),
                      size: 26,
                      color: playing ? scheme.onPrimary : scheme.primary,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme scheme) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer,
            scheme.secondaryContainer,
            scheme.tertiaryContainer,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          size: 56,
          color: scheme.onPrimaryContainer.withOpacity(0.55),
        ),
      ),
    );
  }
}
