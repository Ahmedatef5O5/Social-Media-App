import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/group_calls/models/group_call_model.dart';
import '../../features/group_calls/services/group_call_signaling_service.dart';
import '../../features/group_calls/views/incoming_group_call_screen.dart';
import '../bootstrap/app_bootstrap.dart';
import '../notifications/notification_navigator_key.dart';
import '../supabase/supabase_provider.dart';
import 'incoming_call_navigation_guard.dart';

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

  @override
  void initState() {
    super.initState();
    _initAfterBootstrap();
  }

  Future<void> _initAfterBootstrap() async {
    await waitForCoreServicesReady();
    if (!mounted) return;

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
    ) async {
      if (!mounted || calls.isEmpty) return;

      GroupCallModel? activeCall;
      for (final call in calls) {
        final blocked =
            IncomingCallNavigationGuard.shouldBlockIncomingGroupCall(
              callId: call.callId,
              initiatorId: call.initiatorId,
              currentUserId: userId,
            );
        if (!blocked) {
          activeCall = call;
          break;
        }
      }
      if (activeCall == null) return;
      final incomingCall = activeCall;

      if (!IncomingCallNavigationGuard.claim(incomingCall.callId)) return;

      final isMember = await _signaling.isActiveGroupMember(
        groupId: incomingCall.groupId,
        userId: userId,
      );
      if (!mounted || !isMember) {
        IncomingCallNavigationGuard.release(incomingCall.callId);
        return;
      }

      // Re-check after the async gap: this user may have started a call of
      // their own while membership was being verified.
      if (IncomingCallNavigationGuard.isOutgoingGroupCallActive) {
        IncomingCallNavigationGuard.release(incomingCall.callId);
        return;
      }

      final pushed = navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => IncomingGroupCallScreen(call: incomingCall),
        ),
      );
      if (pushed == null) {
        IncomingCallNavigationGuard.release(incomingCall.callId);
        return;
      }
      unawaited(
        pushed.then(
          (_) => IncomingCallNavigationGuard.release(incomingCall.callId),
        ),
      );
    });
  }

  void _stopIncomingCallListener() {
    _incomingCallSub?.cancel();
    _incomingCallSub = null;
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
