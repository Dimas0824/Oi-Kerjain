import 'package:flutter/material.dart';

import 'ui_palette.dart';

class UITypography {
  const UITypography._();

  static const TextStyle pageTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    color: UIPalette.textSecondary,
    height: 1.2,
  );

  static const TextStyle sectionLabel = TextStyle(
    fontSize: 10,
    letterSpacing: 1,
    color: UIPalette.textMuted,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle bodyStrong = TextStyle(
    color: UIPalette.textSecondary,
    fontSize: 14,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle body = TextStyle(
    color: UIPalette.textSecondary,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle captionStrong = TextStyle(
    color: UIPalette.textMuted,
    fontSize: 11,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle caption = TextStyle(
    color: UIPalette.textMuted,
    fontSize: 10,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle micro = TextStyle(
    color: UIPalette.textMuted,
    fontSize: 9,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
  );

  static const TextStyle input = TextStyle(
    color: UIPalette.textSecondary,
    fontWeight: FontWeight.w700,
    fontSize: 13,
  );

  static const TextStyle inputHint = TextStyle(
    color: UIPalette.textMuted,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle button = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle error = TextStyle(
    color: Colors.redAccent,
    fontWeight: FontWeight.w700,
    fontSize: 12,
  );
}
