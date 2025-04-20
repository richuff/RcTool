import 'package:flutter/material.dart';

class IconButtonNoRipple extends StatelessWidget {
  final double? iconSize;

  final VisualDensity? visualDensity;

  final EdgeInsetsGeometry? padding;

  final AlignmentGeometry? alignment;

  final double? splashRadius;

  final Widget icon;

  final Color? focusColor;

  final Color? hoverColor;

  final Color? color;

  final Color? splashColor;

  final Color? highlightColor;

  final Color? disabledColor;

  final VoidCallback? onPressed;

  final MouseCursor? mouseCursor;

  final FocusNode? focusNode;

  final bool autofocus;

  final String? tooltip;

  final bool? enableFeedback;

  final BoxConstraints? constraints;
  final ButtonStyle? style;

  final bool? isSelected;
  final Widget? selectedIcon;

  IconButtonNoRipple(
      {required this.onPressed,
      required this.icon,
      this.iconSize,
      this.visualDensity,
      this.padding,
      this.alignment,
      this.splashRadius,
      this.focusColor,
      this.hoverColor,
      this.color,
      this.splashColor,
      this.highlightColor,
      this.disabledColor,
      this.mouseCursor,
      this.focusNode,
      this.autofocus = false,
      this.tooltip,
      this.enableFeedback,
      this.constraints,
      this.style,
      this.isSelected,
      this.selectedIcon});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: icon,
      iconSize: iconSize,
      visualDensity: visualDensity,
      padding: padding,
      alignment: alignment,
      splashRadius: splashRadius,
      focusColor: focusColor,
      hoverColor: hoverColor,
      color: color,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      disabledColor: disabledColor,
      mouseCursor: mouseCursor,
      focusNode: focusNode,
      autofocus: autofocus,
      tooltip: tooltip,
      enableFeedback: enableFeedback,
      constraints: constraints,
      style: style,
      isSelected: isSelected,
      selectedIcon: selectedIcon,
    );
  }
}
