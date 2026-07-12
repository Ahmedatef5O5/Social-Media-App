import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/group_calls/views/incoming_group_call_screen.dart';
import '../../features/group_calls/services/group_call_signaling_service.dart';
import '../services/notification_services.dart';
import '../supabase/supabase_provider.dart';

class GlobalGroupCallListener extends StatefulWidget {
  final Widget child;
  const GlobalGroupCallListener({super.key, required this.child});

  @override
  State<GlobalGroupCallListener> createState() =>
      _GlobalGroupCallListenerState();
}

class _GlobalGroupCallListenerState extends State<GlobalGroupCallListener> {
  StreamSubscription? _incomingCallSub;
  late final GroupCallSignalingService _signaling;
  String? _currentlyShowingCallId;

  @override
  void initState() {
    super.initState();
    _signaling = context.read<GroupCallSignalingService>();
    _initListener();
  }

  void _initListener() {
    final userId = SupabaseProvider.id;

    _incomingCallSub = _signaling.incomingGroupCallsStream(userId).listen((
      calls,
    ) {
      if (!mounted) return;
      if (calls.isEmpty) return;

      final activeCall = calls.first;

      if (_currentlyShowingCallId == activeCall.callId) return;
      _currentlyShowingCallId = activeCall.callId;

      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!
            .push(
              MaterialPageRoute(
                builder: (_) => IncomingGroupCallScreen(call: activeCall),
              ),
            )
            .then((_) {
              _currentlyShowingCallId = null;
            });
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
