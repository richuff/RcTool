import 'package:flutter/material.dart';
import 'package:rctool/repository/entity/Music.dart';

/// @ClassName SongRow
/// @Description 横向歌曲卡片：封面 + 渐变信息条 + 播放/移除按钮。
///             信息条与圆形按钮垂直居中对齐（此前因外层边距导致横条偏上、
///             按钮偏下），并修复亮色主题下白色图标不可见的问题。
/// @Author richuff
/// @Version 2.1
class SongRow extends StatelessWidget {
  final Music music;
  final bool playing;
  final VoidCallback? onPlayToggle;
  final VoidCallback? onRemove;
  final IconData removeIcon;
  final Color? removeColor;
  final String? detail;

  const SongRow({
    super.key,
    required this.music,
    this.playing = false,
    this.onPlayToggle,
    this.onRemove,
    this.removeIcon = Icons.close,
    this.removeColor,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bool hasPlay = onPlayToggle != null;
    final bool hasRemove = onRemove != null;

    // 信息条与按钮共用的垂直中心：横条 40 高，按钮 38 高
    const double barTop = 18;
    const double buttonTop = 19;

    // 为右侧按钮预留文字空间
    final double rightPadding = hasPlay && hasRemove
        ? 92
        : hasPlay
            ? 54
            : hasRemove
                ? 50
                : 12;

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      child: SizedBox(
        height: 78,
        child: Stack(
          children: [
            // 渐变信息条
            Positioned(
              left: 0,
              right: 0,
              top: barTop,
              height: 40,
              child: Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(left: 88, right: rightPadding),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      scheme.primaryContainer.withOpacity(0.86),
                      scheme.secondaryContainer.withOpacity(0.78),
                      scheme.tertiary.withOpacity(0.24),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withOpacity(0.16),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: Text(
                  detail ?? "${music.songName}  -----  ${music.decoration}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            // 封面
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ],
                  image: music.imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(music.imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: music.imageUrl.isEmpty
                    ? Icon(Icons.music_note, color: scheme.onSurfaceVariant)
                    : null,
              ),
            ),
            // 播放 / 暂停（与横条垂直居中对齐）
            if (hasPlay)
              Positioned(
                right: hasRemove ? 44 : 6,
                top: buttonTop,
                child: _CircleButton(
                  backgroundColor:
                      playing ? scheme.primary : scheme.surface,
                  onTap: onPlayToggle,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      playing ? Icons.pause : Icons.play_arrow_sharp,
                      key: ValueKey(playing),
                      size: 20,
                      color: playing ? scheme.onPrimary : scheme.onSurface,
                    ),
                  ),
                ),
              ),
            // 移除 / 删除
            if (hasRemove)
              Positioned(
                right: 6,
                top: buttonTop,
                child: _CircleButton(
                  backgroundColor: scheme.surface,
                  onTap: onRemove,
                  child: Icon(
                    removeIcon,
                    size: 18,
                    color: removeColor ?? scheme.onSurface,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 统一风格的圆形按钮
class _CircleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color backgroundColor;

  const _CircleButton({
    required this.child,
    this.onTap,
    this.backgroundColor = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: scheme.shadow,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 38, height: 38, child: Center(child: child)),
      ),
    );
  }
}
