import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// @ClassName PlayAllButton
/// @Description 统一的「播放全部」按钮：主色渐变 + 内高光 + 柔和投影 + 按压缩放。
///              dense 用于 AppBar / 列表小标题这类紧凑位置，默认尺寸用于卡片内。
/// @Author richuff
/// @Version 1.0
class PlayAllButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String? label;

  /// 可选数量，显示为「· 12 首」的小徽标
  final int? count;

  /// 紧凑尺寸（AppBar、列表头部）
  final bool dense;

  const PlayAllButton({
    super.key,
    required this.onPressed,
    this.label,
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
    final height = widget.dense ? 32.0 : 40.0;
    final radius = BorderRadius.circular(widget.dense ? 11 : 13);

    // 主色向深色过渡一档，比纯色块更有体积感；禁用态整体降灰
    final top = enabled
        ? scheme.primary
        : scheme.onSurfaceVariant.withOpacity(0.28);
    final bottom = enabled
        ? Color.lerp(scheme.primary, scheme.shadow, 0.24)!
        : scheme.onSurfaceVariant.withOpacity(0.2);
    final foreground = enabled
        ? scheme.onPrimary
        : scheme.onSurfaceVariant.withOpacity(0.75);

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: widget.dense ? 19 : 24,
          height: widget.dense ? 19 : 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: foreground.withOpacity(enabled ? 0.2 : 0.12),
          ),
          child: Icon(
            Icons.play_arrow_rounded,
            size: widget.dense ? 14 : 17,
            color: foreground,
          ),
        ),
        SizedBox(width: widget.dense ? 5 : 7),
        Text(
          widget.label ?? '播放全部'.tr,
          style: TextStyle(
            fontSize: widget.dense ? 12 : 13.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: foreground,
          ),
        ),
        if (widget.count != null && !widget.dense) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: foreground.withOpacity(0.16),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              '${widget.count}',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
            ),
          ),
        ],
      ],
    );

    return AnimatedScale(
      scale: _pressed ? 0.955 : 1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: DecoratedBox(
        // 阴影画在裁剪之外，圆角跟随按钮本身
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: scheme.primary.withOpacity(
                      Theme.of(context).brightness == Brightness.dark
                          ? 0.24
                          : 0.32,
                    ),
                    blurRadius: widget.dense ? 10 : 14,
                    offset: Offset(0, widget.dense ? 3 : 5),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            // 宽度被拉满时（队列卡片）内容仍然居中
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [top, bottom],
                    ),
                  ),
                ),
              ),
              // 点击层铺满整个按钮（水波在内容之下，不会盖住文字）
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onPressed,
                    onHighlightChanged: (value) {
                      if (_pressed == value) return;
                      setState(() => _pressed = value);
                    },
                  ),
                ),
              ),
              // 内容决定按钮尺寸；不参与命中测试，点击交给下层的水波层
              IgnorePointer(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.dense ? 9 : 14,
                  ),
                  child: SizedBox(
                    height: height,
                    child: Center(widthFactor: 1, child: content),
                  ),
                ),
              ),
              // 顶部内高光，避免大色块显得平
              if (enabled)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: height * 0.55,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.18),
                            Colors.white.withOpacity(0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
