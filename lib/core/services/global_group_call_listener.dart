import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/group_calls/models/group_call_model.dart';
import '../../features/group_calls/services/group_call_signaling_service.dart';
import '../../features/group_calls/views/incoming_group_call_screen.dart';
import '../bootstrap/app_bootstrap.dart';
import '../../features/settings/repository/settings_repository.dart';
import '../notifications/dispatchers/group_call_dispatcher.dart';
import '../notifications/helpers/notification_app_state_helper.dart';
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
  RealtimeChannel? _ringChannel;
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

  /// Direct "ring me" signal (< 100 ms) sent by another member of an
  /// ongoing group call. The `group_calls` stream below only watches rows
  /// with `status = 'ringing'`, so without this an online user would never
  /// learn that they were rung mid-call.
  void _startRingBroadcastListener(String userId) {
    _stopRingBroadcastListener();

    final channel = SupabaseProvider.client.channel(
      'user_group_call_ring:$userId',
    );
    channel
        .onBroadcast(
          event: 'ring_group_call',
          callback: (payload) => unawaited(_onRingBroadcast(userId, payload)),
        )
        .subscribe();
    _ringChannel = channel;
  }

  Future<void> _onRingBroadcast(
    String userId,
    Map<String, dynamic> raw,
  ) async {
    if (!mounted) return;

    // Depending on the realtime client version the callback receives either
    // the inner payload or the whole broadcast envelope.
    final inner = raw['payload'];
    final data =
        inner is Map ? Map<String, dynamic>.from(inner) : Map<String, dynamic>.from(raw);

    final callId = (data['callId'] ?? data['call_id']) as String? ?? '';
    if (callId.isEmpty) return;

    // The user may have declined this call earlier; a fresh ring overrides it.
    _signaling.clearDeclined(callId, userId);

    try {
      await GroupCallDispatcher.instance.handleIncomingGroupCallData(data);
    } catch (e) {
      debugPrint('[GlobalGroupCallListener] ring broadcast handling failed: $e');
    }
  }

  void _stopRingBroadcastListener() {
    final channel = _ringChannel;
    _ringChannel = null;
    if (channel != null) {
      unawaited(SupabaseProvider.client.removeChannel(channel));
    }
  }

  void _startIncomingCallListener(String userId) {
    _incomingCallSub?.cancel();
    _startRingBroadcastListener(userId);

    _incomingCallSub = _signaling.incomingGroupCallsStream(userId).listen((
      calls,
    ) async {
      if (!mounted || calls.isEmpty) return;

      // "Call Notifications" off: an app that is NOT on screen stays silent
      // (no ringing screen / ringtone). With the app open, the screen opens.
      if (!isAppInForeground() &&
          !SettingsRepository.instance.callNotifications) {
        return;
      }

      // The stream is ordered newest-first and may contain calls THIS user
      // started (or that are already on screen). Looking only at `.first`
      // let one blocked call hide every other ringing call — and let the
      // initiator's own call through in some orderings. Pick the first call
      // the guard does not block.
      GroupCallModel? activeCall;
      for (final call in calls) {
        final blocked = IncomingCallNavigationGuard.shouldBlockIncomingGroupCall(
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
        pushed.then((_) => IncomingCallNavigationGuard.release(incomingCall.callId)),
      );
    });
  }

  void _stopIncomingCallListener() {
    _incomingCallSub?.cancel();
    _incomingCallSub = null;
    _stopRingBroadcastListener();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _incomingCallSub?.cancel();
    _stopRingBroadcastListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

