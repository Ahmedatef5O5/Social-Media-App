import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/features/auth/views/auth_view.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.authRoute:
        return CupertinoPageRoute(
          builder: (_) => const AuthView(),
          settings: settings,
        );

      default:
        return CupertinoPageRoute(
          builder:
              (_) => Scaffold(
                body: Column(
                  children: [Text('No route found ${settings.name}')],
                ),
              ),
          settings: settings,
        );
    }
  }
}
