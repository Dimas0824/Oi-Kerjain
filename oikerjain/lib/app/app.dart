import 'package:flutter/material.dart';

import '../core/constants/ui_palette.dart';
import '../core/constants/ui_typography.dart';
import 'router.dart';

class OikerjainApp extends StatelessWidget {
  const OikerjainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Oi!Kerjain',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: UIPalette.base,
        colorScheme: ColorScheme.fromSeed(
          seedColor: UIPalette.accent,
          brightness: Brightness.light,
          surface: UIPalette.base,
        ),
        textTheme: const TextTheme()
            .apply(
              bodyColor: UIPalette.textPrimary,
              displayColor: UIPalette.textPrimary,
            )
            .copyWith(
              titleLarge: UITypography.pageTitle,
              titleSmall: UITypography.sectionLabel,
              bodyMedium: UITypography.body,
              bodySmall: UITypography.caption,
              labelLarge: UITypography.button,
            ),
      ),
      initialRoute: AppRouter.homeRoute,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
