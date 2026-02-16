import 'package:flutter/material.dart';

import '../../../core/constants/ui_palette.dart';
import '../../../core/constants/ui_typography.dart';
import 'neu_surface.dart';

class NeuButton extends StatelessWidget {
  const NeuButton({
    super.key,
    required this.child,
    this.onTap,
    this.active = false,
    this.padding,
    this.height,
    this.width,
    this.radius = 16,
    this.foregroundColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool active;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final double? width;
  final double radius;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        foregroundColor ??
        (active ? UIPalette.accent : UIPalette.textSecondary);

    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: active ? 0.98 : 1,
      child: NeuSurface(
        radius: radius,
        pressed: active,
        onTap: onTap,
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: SizedBox(
          height: height,
          width: width,
          child: DefaultTextStyle.merge(
            style: UITypography.button.copyWith(color: effectiveColor),
            child: IconTheme(
              data: IconThemeData(color: effectiveColor, size: 14),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
