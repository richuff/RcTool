import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/controller/offline_controller.dart';
import 'package:rctool/repository/entity/Music.dart';

/// @ClassName SongRow
/// @Description 卡片式歌曲行：圆角底卡 + 封面 + 两行信息 + 轻量圆形操作按钮。
///             播放中的行用主色渐变高亮，右侧按钮不再使用厚重阴影，
///             整体与设置页的分组卡片风格保持一致。
/// @Author richuff
/// @Version 3.0
class SongRow extends StatelessWidget {
  final Music music;
  final bool playing;
  final VoidCallback? onPlayToggle;
  final VoidCallback? onRemove;
  final IconData removeIcon;
  final Color? removeColor;

  /// 第二行文案（默认展示歌手），用于「最近播放」这类需要显示时间的场景。
  final String? subtitle;

  /// 队列序号（可选）。传入后在封面左侧显示序号，用于播放队列等有序场景。
  final int? index;

  /// 右侧「…」更多操作按钮（可选）。点击通常打开歌曲操作面板。
  final VoidCallback? onMore;

  /// 是否正在为该歌曲准备缓存（首次播放需要下载）。
  final bool loading;

  /// 搜索关键词：命中时在歌名里高亮显示（大小写不敏感）。
  final String? highlight;

  const SongRow({
    super.key,
    required this.music,
    this.playing = false,
    this.onPlayToggle,
    this.onRemove,
    this.removeIcon = Icons.close_rounded,
    this.removeColor,
    this.subtitle,
    this.index,
    this.onMore,
    this.loading = false,
    this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(16);

    final secondary = subtitle ??
        (music.decoration.trim().isEmpty ? '未知歌手'.tr : music.decoration);

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: playing
                ? [
                    scheme.primaryContainer.withOpacity(0.92),
                    scheme.secondaryContainer.withOpacity(0.66),
                  ]
                : [
                    scheme.surface.withOpacity(0.82),
                    scheme.surface.withOpacity(0.58),
                  ],
          ),
          border: Border.all(
            color: playing
                ? scheme.primary.withOpacity(0.42)
                : scheme.outlineVariant.withOpacity(0.26),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withOpacity(playing ? 0.14 : 0.06),
              blurRadius: playing ? 14 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: radius,
            onTap: onPlayToggle,
            child: Padding(
              padding: EdgeInsets.fromLTRB(index != null ? 8 : 10, 8, 6, 8),
              child: Row(
                children: [
                  if (index != null)
                    SizedBox(
                      width: 20,
                      child: Text(
                        '${index! + 1}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: playing
                              ? scheme.primary
                              : scheme.onSurfaceVariant.withOpacity(0.85),
                        ),
                      ),
                    ),
                  _Cover(music: music, playing: playing, scheme: scheme),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (playing) ...[
                              Icon(
                                Icons.graphic_eq_rounded,
                                size: 14,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: 3),
                            ],
                            Expanded(
                              child: _HighlightedTitle(
                                text: music.songName,
                                keyword: highlight,
                                baseStyle: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: playing
                                      ? scheme.primary
                                      : scheme.onSurface,
                                ),
                                highlightColor: scheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                secondary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            if (loading)
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: _BufferingChip(scheme: scheme),
                              ),
                            if (!loading)
                              _OfflineMark(url: music.url, scheme: scheme),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (onPlayToggle != null)
                    _PlayButton(
                      playing: playing,
                      loading: loading,
                      onTap: onPlayToggle,
                      scheme: scheme,
                    ),
                  if (onRemove != null)
                    _GhostButton(
                      icon: removeIcon,
                      color: removeColor ?? scheme.onSurfaceVariant,
                      onTap: onRemove,
                    ),
                  if (onMore != null)
                    _GhostButton(
                      icon: Icons.more_horiz_rounded,
                      color: scheme.onSurfaceVariant,
                      onTap: onMore,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 封面：圆角矩形 + 轻描边，播放中加一圈主色光晕
class _Cover extends StatelessWidget {
  final Music music;
  final bool playing;
  final ColorScheme scheme;

  const _Cover({
    required this.music,
    required this.playing,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = music.imageUrl.isNotEmpty;
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: scheme.surfaceContainerHighest,
        border: Border.all(
          color: playing
              ? scheme.primary.withOpacity(0.55)
              : Colors.white.withOpacity(
                  Theme.of(context).brightness == Brightness.dark ? 0.06 : 0.5,
                ),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.16),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        image: hasImage
            ? DecorationImage(
                image: NetworkImage(music.imageUrl),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: hasImage
          ? null
          : Icon(
              Icons.music_note_rounded,
              size: 22,
              color: scheme.onSurfaceVariant.withOpacity(0.85),
            ),
    );
  }
}

/// 缓存中提示：小圆点 + 文案，跟随副标题行
class _BufferingChip extends StatelessWidget {
  final ColorScheme scheme;

  const _BufferingChip({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 8,
            height: 8,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '缓存中'.tr,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: scheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 离线条目：已下载到本地时在副标题行尾部显示一个小图标
class _OfflineMark extends StatelessWidget {
  final String url;
  final ColorScheme scheme;

  const _OfflineMark({required this.url, required this.scheme});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<OfflineController>()) return const SizedBox.shrink();
    final offline = Get.find<OfflineController>();
    return Obx(() {
      if (!offline.cachedUrls.contains(url)) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Icon(
          Icons.offline_pin_rounded,
          size: 13,
          color: scheme.primary.withOpacity(0.85),
        ),
      );
    });
  }
}

/// 主操作按钮：播放中为实心主色，未播放为主色淡底
class _PlayButton extends StatelessWidget {
  final bool playing;
  final bool loading;
  final VoidCallback? onTap;
  final ColorScheme scheme;

  const _PlayButton({
    required this.playing,
    required this.loading,
    required this.onTap,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = playing ? scheme.onPrimary : scheme.primary;
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Material(
        color: playing
            ? scheme.primary
            : scheme.primary.withOpacity(
                Theme.of(context).brightness == Brightness.dark ? 0.22 : 0.12,
              ),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: loading
                    ? SizedBox(
                        key: const ValueKey('loading'),
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(foreground),
                        ),
                      )
                    : Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        key: ValueKey(playing),
                        size: 20,
                        color: foreground,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 次要操作按钮：无底色，只在按下时出现水波
class _GhostButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _GhostButton({
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Icon(icon, size: 19, color: color),
      ),
    );
  }
}


/// 歌名按关键词高亮：命中部分用主色淡底胶囊标出，其余保持原样式。
class _HighlightedTitle extends StatelessWidget {
  final String text;
  final String? keyword;
  final TextStyle baseStyle;
  final Color highlightColor;

  const _HighlightedTitle({
    required this.text,
    required this.keyword,
    required this.baseStyle,
    required this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final query = (keyword ?? '').trim();
    if (query.isEmpty) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: baseStyle,
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;

    while (start < text.length) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index < 0) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: TextStyle(
            color: highlightColor,
            backgroundColor: highlightColor.withOpacity(0.16),
            fontWeight: FontWeight.w800,
          ),
        ),
      );
      start = index + query.length;
    }

    if (spans.isEmpty) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: baseStyle,
      );
    }

    return Text.rich(
      TextSpan(style: baseStyle, children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
