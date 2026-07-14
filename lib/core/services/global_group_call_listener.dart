import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/group_calls/services/group_call_signaling_service.dart';
import '../../features/group_calls/views/incoming_group_call_screen.dart';
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
  StreamSubscription<AuthState>? _authSub;

  late final GroupCallSignalingService _signaling;

  String? _currentlyShowingCallId;

  @override
  void initState() {
    super.initState();

    _signaling = context.read<GroupCallSignalingService>();

    _listenToAuth();

    final userId = SupabaseProvider.idOrNull;
    if (userId != null) {
      _startIncomingCallListener(userId);
    }
  }

  void _listenToAuth() {
    _authSub = SupabaseProvider.authChanges.listen((authState) {
      switch (authState.event) {
        case AuthChangeEvent.signedIn:
          final userId = authState.session?.user.id;
          if (userId != null) {
            _startIncomingCallListener(userId);
          }
          break;

        case AuthChangeEvent.signedOut:
          _stopIncomingCallListener();
          break;

        default:
          break;
      }
    });
  }

  void _startIncomingCallListener(String userId) {
    _incomingCallSub?.cancel();

    _incomingCallSub = _signaling.incomingGroupCallsStream(userId).listen((
      calls,
    ) {
      if (!mounted) return;
      if (calls.isEmpty) return;

      final activeCall = calls.first;

      if (_currentlyShowingCallId == activeCall.callId) return;

      _currentlyShowingCallId = activeCall.callId;

      navigatorKey.currentState
          ?.push(
            MaterialPageRoute(
              builder: (_) => IncomingGroupCallScreen(call: activeCall),
            ),
          )
          .then((_) {
            _currentlyShowingCallId = null;
          });
    });
  }

  void _stopIncomingCallListener() {
    _incomingCallSub?.cancel();
    _incomingCallSub = null;
    _currentlyShowingCallId = null;
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _incomingCallSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
