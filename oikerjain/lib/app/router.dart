import 'package:flutter/material.dart';

import '../feature/tasks/home/home_page.dart';

class AppRouter {
  static const String homeRoute = '/';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case homeRoute:
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const HomePage(),
          settings: settings,
        );
    }
  }
}
