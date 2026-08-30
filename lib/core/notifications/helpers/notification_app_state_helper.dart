import 'package:flutter/widgets.dart';

/// Whether the app is currently in the foreground (resumed lifecycle
/// state). Call/group-call dispatchers use this to decide whether to show
/// a heads-up notification or navigate straight into the call screen.
bool isAppInForeground() =>
    WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
