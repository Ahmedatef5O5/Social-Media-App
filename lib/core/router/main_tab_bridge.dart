import 'dart:async';
import 'package:flutter/material.dart';
import 'app_routes.dart';

/// Indexes of the tabs hosted by `CustomBottomNavBar`.
abstract final class MainTabs {
  static const int home = 0;
  static const int discover = 1;
  static const int chats = 2;
  static const int profile = 3;
}

class MainTabBridge {
  MainTabBridge._();
  static final MainTabBridge instance = MainTabBridge._();

  final StreamController<int> _requests = StreamController<int>.broadcast();

  /// Tab switch requests, consumed by `CustomBottomNavBar`.
  Stream<int> get requests => _requests.stream;

  void jumpTo(int tabIndex) => _requests.add(tabIndex);

  /// Closes every page above the main screen and shows the current user's own
  /// profile tab.
  static void openMyProfileTab(BuildContext context) {
    Navigator.of(context, rootNavigator: true).popUntil(
      (route) => route.isFirst || route.settings.name == AppRoutes.homeRoute,
    );
    instance.jumpTo(MainTabs.profile);
  }
}
