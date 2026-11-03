import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// @ClassName PlayAllButton
/// @Description 统一的「播放全部」入口：纯图标圆形按钮，主色渐变 + 柔和投影 +
///              顶部内高光 + 按压缩放，长按有「播放全部」提示。
///              dense 用于 AppBar / 列表小标题这类紧凑位置，默认尺寸用于卡片内；
///              传 count 时在右上角显示数量角标。
/// @Author richuff
/// @Version 2.0
class PlayAllButton extends StatefulWidget {
  final VoidCallback? onPressed;

  /// 可选数量，显示为右上角小角标
  final int? count;

  /// 紧凑尺寸（AppBar、列表头部）
  final bool dense;

  const PlayAllButton({
    super.key,
    required this.onPressed,
    this.count,
    this.dense = false,
  });

  @override
  State<PlayAllButton> createState() => _PlayAllButtonState();
}

class _PlayAllButtonState extends State<PlayAllButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = widget.onPressed != null;
    final size = widget.dense ? 34.0 : 42.0;

    // 主色向深色过渡一档，比纯色块更有体积感；禁用态整体降灰
    final top =
        enabled ? scheme.primary : scheme.onSurfaceVariant.withOpacity(0.28);
    final bottom = enabled
        ? Color.lerp(scheme.primary, scheme.shadow, 0.24)!
        : scheme.onSurfaceVariant.withOpacity(0.2);
    final foreground =
        enabled ? scheme.onPrimary : scheme.onSurfaceVariant.withOpacity(0.75);

    return Tooltip(
      message: '播放全部'.tr,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [top, bottom],
                    ),
                    boxShadow: enabled
                        ? [
                            BoxShadow(
                              color: scheme.primary.withOpacity(
                                Theme.of(context).brightness == Brightness.dark
                                    ? 0.24
                                    : 0.32,
                              ),
                              blurRadius: widget.dense ? 9 : 13,
                              offset: Offset(0, widget.dense ? 2.5 : 4),
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
              // 点击层铺满整个圆（水波被圆形裁剪，不会溢出）
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: widget.onPressed,
                    onHighlightChanged: (value) {
                      if (_pressed == value) return;
                      setState(() => _pressed = value);
                    },
                  ),
                ),
              ),
              // 图标不参与命中测试，点击交给下层的水波层
              IgnorePointer(
                child: Center(
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: widget.dense ? 21 : 26,
                    color: foreground,
                  ),
                ),
              ),
              // 顶部内高光，避免大色块显得平
              if (enabled)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0, 0.55],
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              // 数量角标：默认尺寸才显示，悬在圆的右上角
              if (widget.count != null && !widget.dense)
                Positioned(
                  right: -3,
                  top: -3,
                  child: _CountBadge(count: widget.count!, scheme: scheme),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final ColorScheme scheme;

  const _CountBadge({required this.count, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 16),
      height: 16,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surface,
        shape: count < 10 ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: count < 10 ? null : BorderRadius.circular(8),
        border: Border.all(color: scheme.primary, width: 1.4),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: TextStyle(
          fontSize: 9.5,
          height: 1,
          fontWeight: FontWeight.w800,
          color: scheme.primary,
        ),
      ),
    );
  }
}
