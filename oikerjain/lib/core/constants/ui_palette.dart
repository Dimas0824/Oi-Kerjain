import 'package:flutter/material.dart';

class UIPalette {
  const UIPalette._();

  static const Color base = Color(0xFFE0E5EC);
  static const Color accent = Color(0xFF6B46C1);
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF4A5568);
  static const Color textMuted = Color(0xFFA0AEC0);

  static const Color shadowDark = Color(0xFFB8B9BE);
  static const Color shadowLight = Color(0xFFFFFFFF);

  static List<BoxShadow> raisedMedium() {
    return <BoxShadow>[
      BoxShadow(
        color: shadowDark.withValues(alpha: 0.6),
        offset: const Offset(9, 9),
        blurRadius: 16,
      ),
      BoxShadow(
        color: shadowLight.withValues(alpha: 0.5),
        offset: const Offset(-9, -9),
        blurRadius: 16,
      ),
    ];
  }

  static List<BoxShadow> raisedSmall() {
    return <BoxShadow>[
      BoxShadow(
        color: shadowDark.withValues(alpha: 0.6),
        offset: const Offset(5, 5),
        blurRadius: 10,
      ),
      BoxShadow(
        color: shadowLight.withValues(alpha: 0.5),
        offset: const Offset(-5, -5),
        blurRadius: 10,
      ),
    ];
  }

  static List<BoxShadow> pressed() {
    return <BoxShadow>[
      BoxShadow(
        color: shadowDark.withValues(alpha: 0.45),
        offset: const Offset(2, 2),
        blurRadius: 6,
        spreadRadius: -1,
      ),
      BoxShadow(
        color: shadowLight.withValues(alpha: 0.75),
        offset: const Offset(-2, -2),
        blurRadius: 6,
        spreadRadius: -1,
      ),
    ];
  }
}
