import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/calls/views/incoming_group_call_screen.dart';
import '../../features/group_chat/services/group_call_signaling_service.dart';
import '../services/notification_services.dart';

class GlobalGroupCallListener extends StatefulWidget {
  final Widget child;
  const GlobalGroupCallListener({super.key, required this.child});

  @override
  State<GlobalGroupCallListener> createState() =>
      _GlobalGroupCallListenerState();
}

class _GlobalGroupCallListenerState extends State<GlobalGroupCallListener> {
  StreamSubscription? _incomingCallSub;
  final _signaling = GroupCallSignalingService();

  @override
  void initState() {
    super.initState();
    _initListener();
  }

  void _initListener() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _incomingCallSub = _signaling.incomingGroupCallsStream(userId).listen((
      calls,
    ) {
      if (calls.isNotEmpty && mounted) {
        final activeCall = calls.first;
        if (navigatorKey.currentState != null) {
          navigatorKey.currentState!.push(
            MaterialPageRoute(
              builder: (_) => IncomingGroupCallScreen(call: activeCall),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _incomingCallSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
