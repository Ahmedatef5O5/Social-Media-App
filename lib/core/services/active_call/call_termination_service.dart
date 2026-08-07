import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'cubit/active_call_session_cubit.dart';
import 'pip/call_pip_cubit.dart';

class CallTerminationService {
  const CallTerminationService._();

  static Future<void> endActiveCall({
    required CallPipCubit pipCubit,
    required ActiveCallSessionCubit sessionCubit,

    required Future<void> Function() signalEnd,
  }) async {
    try {
      await pipCubit.reset();
    } catch (e) {
      debugPrint('[CallTerminationService] reset failed: $e');
    }
    try {
      await signalEnd();
    } catch (e) {
      debugPrint('[CallTerminationService] signalEnd failed: $e');
    }
    sessionCubit.endSession();

    try {
      await FlutterForegroundTask.stopService();
    } catch (e) {
      debugPrint('[CallTerminationService] stopService failed: $e');
    }
  }
}
