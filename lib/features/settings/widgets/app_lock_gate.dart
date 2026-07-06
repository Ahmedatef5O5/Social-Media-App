import 'package:flutter/material.dart';
import 'package:social_media_app/features/settings/widgets/app_lock_screen.dart';
import '../services/app_lock_service.dart';

class AppLockGate extends StatefulWidget {
  final Widget child;
  const AppLockGate({super.key, required this.child});

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> {
  @override
  void initState() {
    super.initState();
    AppLockService.instance.init();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppLockService.instance.lockNotifier,
      builder: (context, locked, _) {
        return Stack(
          children: [widget.child, if (locked) const AppLockScreen()],
        );
      },
    );
  }
}
