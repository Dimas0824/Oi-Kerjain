import 'package:flutter/material.dart';

import '../../../core/constants/ui_palette.dart';

class NeuSurface extends StatelessWidget {
  const NeuSurface({
    super.key,
    required this.child,
    this.padding,
    this.radius = 20,
    this.pressed = false,
    this.onTap,
    this.color,
    this.duration = const Duration(milliseconds: 180),
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final bool pressed;
  final VoidCallback? onTap;
  final Color? color;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: color ?? UIPalette.base,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: pressed ? UIPalette.pressed() : UIPalette.raisedSmall(),
      border: pressed
          ? Border.all(color: Colors.white.withValues(alpha: 0.65), width: 1)
          : null,
    );

    final body = AnimatedContainer(
      duration: duration,
      curve: Curves.easeOut,
      padding: padding,
      decoration: decoration,
      child: child,
    );

    if (onTap == null) {
      return body;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        splashColor: UIPalette.accent.withValues(alpha: 0.08),
        highlightColor: Colors.transparent,
        child: body,
      ),
    );
  }
}
