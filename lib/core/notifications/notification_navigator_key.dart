import 'package:flutter/material.dart';

/// Global navigator key shared across the whole app so that notification
/// taps, deep links, and share-intent handling can push routes without a
/// [BuildContext] of their own.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
