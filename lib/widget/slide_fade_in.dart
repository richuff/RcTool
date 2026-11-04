import 'package:flutter/material.dart';

/// @ClassName SlideFadeIn
/// @Description 列表/卡片入场动画：淡入 + 上滑，支持延迟形成错落效果。
/// @Author richuff
/// @Version 2.1
class SlideFadeIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  const SlideFadeIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 360),
    this.offset = const Offset(0, 18),
  });

  @override
  State<SlideFadeIn> createState() => _SlideFadeIn();
}

class _SlideFadeIn extends State<SlideFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _position;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _position = Tween<Offset>(begin: widget.offset, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Opacity(
        opacity: _opacity.value,
        child: Transform.translate(
          offset: _position.value,
          child: widget.child,
        ),
      ),
    );
  }
}

/// 给一组小组件按顺序套上错落入场动画：
/// 第一个先出现，之后每隔 [step] 出现下一个，累计延迟不超过 [maxDelay]。
/// 直接用在 `ListView(children: stagger([...]))` 或 `Column(children: stagger([...]))` 里。
List<Widget> stagger(
  List<Widget> children, {
  Duration step = const Duration(milliseconds: 45),
  Duration maxDelay = const Duration(milliseconds: 360),
  Duration duration = const Duration(milliseconds: 360),
  Offset offset = const Offset(0, 16),
}) {
  return List<Widget>.generate(children.length, (index) {
    final double delayMs = index * step.inMilliseconds.toDouble();
    return SlideFadeIn(
      delay: Duration(
        milliseconds: delayMs.clamp(0, maxDelay.inMilliseconds).round(),
      ),
      duration: duration,
      offset: offset,
      child: children[index],
    );
  });
}
