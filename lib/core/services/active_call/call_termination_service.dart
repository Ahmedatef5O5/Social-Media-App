import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:livekit_client/livekit_client.dart';
import 'call_control_message.dart';
import 'cubits/active_call_session_cubit.dart';
import 'pip/call_pip_cubit.dart';

class CallTerminationService {
  const CallTerminationService._();

  static const Duration _publishTimeout = Duration(milliseconds: 800);

  /// Ends the active call.

  static Future<void> endActiveCall({
    required CallPipCubit pipCubit,
    required ActiveCallSessionCubit sessionCubit,
    required Future<void> Function() signalEnd,
    Map<String, dynamic>? endMessage,
  }) async {
    final room = pipCubit.state.room;

    // 1. Data packet first — awaited (bounded) so it is on the wire before
    //    the disconnect below can abort it.
    if (endMessage != null && room != null) {
      await _publishEndMessage(room, endMessage);
    }

    // 2. Kick off the Supabase signal WITHOUT awaiting it yet: its first
    //    network write is issued right now, before teardown starts.
    final signalFuture = _runSignalEnd(signalEnd);

    // 3. Local teardown runs while the signal is already in flight.
    try {
      await pipCubit.reset();
    } catch (e) {
      debugPrint('[CallTerminationService] reset failed: $e');
    }

    await signalFuture;

    sessionCubit.endSession();

    try {
      await FlutterForegroundTask.stopService();
    } catch (e) {
      debugPrint('[CallTerminationService] stopService failed: $e');
    }
  }

  static Future<void> _runSignalEnd(Future<void> Function() signalEnd) async {
    try {
      await signalEnd();
    } catch (e) {
      debugPrint('[CallTerminationService] signalEnd failed: $e');
    }
  }

  static Future<void> _publishEndMessage(
    Room room,
    Map<String, dynamic> message,
  ) async {
    try {
      await room.localParticipant
          ?.publishData(
            CallControlMessage.encode(message),
            reliable: true,
            topic: CallControlMessage.topic,
          )
          .timeout(_publishTimeout);
    } catch (e) {
      // Best effort: the Supabase signal below is the durable fallback.
      debugPrint('[CallTerminationService] publishData failed: $e');
    }
  }

  static void popRouteIfActive(BuildContext context) {
    if (!context.mounted) return;
    final route = ModalRoute.of(context);
    if (route == null || !route.isActive) return;
    if (route.isCurrent) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).removeRoute(route);
    }
  }
}
