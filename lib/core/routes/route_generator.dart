import 'package:flutter/material.dart';

import '../../features/devices/presentation/screens/devices_screen.dart';
import '../../features/sender/presentation/screens/sender_screen.dart';
import 'app_routes.dart';

/// Centralized route generator handling named routes and transition animations.
abstract final class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.sender:
        return MaterialPageRoute<void>(
          builder: (_) => const SenderScreen(),
          settings: settings,
        );
      case AppRoutes.devices:
        return MaterialPageRoute<void>(
          builder: (_) => const DevicesScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Page Not Found')),
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
          settings: settings,
        );
    }
  }
}
