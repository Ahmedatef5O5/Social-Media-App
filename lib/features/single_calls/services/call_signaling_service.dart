import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/call_busy_checker.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../models/call_model.dart';

class CallSignalingService {
  SupabaseClient get _supabase => SupabaseProvider.client;

  Future<void> sendCallRequest(CallModel call) async {
    await cleanupStaleCallsForUser(call.callerId);
    await _supabase.from('calls').upsert(call.toMap());
  }

  Future<void> cleanupStaleCallsForUser(String userId) async {
    if (userId.isEmpty) return;
    try {
      await _supabase
          .from('calls')
          .update({'status': CallStatus.ended.name})
          .or('caller_id.eq.$userId,receiver_id.eq.$userId')
          .inFilter('status', [
            CallStatus.ringing.name,
            CallStatus.accepted.name,
          ]);
    } catch (e) {
      debugPrint('[CallSignalingService] cleanupStaleCallsForUser error: $e');
    }
  }

  Future<void> updateCallStatus(String callId, CallStatus status) async {
    await _supabase
        .from('calls')
        .update({'status': status.name})
        .eq('call_id', callId);
  }

  Stream<List<Map<String, dynamic>>> get incomingCallsStream {
    final user = SupabaseProvider.user;
    if (user == null) return const Stream.empty();

    return _supabase
        .from('calls')
        .stream(primaryKey: ['call_id'])
        .eq('receiver_id', user.id)
        .map((list) {
          final cutoff = DateTime.now().toUtc().subtract(
            const Duration(seconds: 45),
          );
          return list.where((call) {
            final status = call['status'] as String?;
            if (status != CallStatus.ringing.name) return false;

            final startTimeStr = call['start_time'] as String?;
            if (startTimeStr != null) {
              final startTime = DateTime.tryParse(startTimeStr)?.toUtc();
              if (startTime != null) return startTime.isAfter(cutoff);
            }

            final callId = call['call_id'] as String? ?? '';
            if (callId.startsWith('room_')) {
              final ms = int.tryParse(callId.substring(5));
              if (ms != null) {
                final created = DateTime.fromMillisecondsSinceEpoch(
                  ms,
                  isUtc: true,
                );
                return created.isAfter(cutoff);
              }
            }
            return true;
          }).toList();
        });
  }

  Stream<List<Map<String, dynamic>>> callStatusStream(String callId) =>
      _supabase
          .from('calls')
          .stream(primaryKey: ['call_id'])
          .eq('call_id', callId);

  Future<bool> isUserBusy(String userId) async {
    final busy = await CallBusyChecker.findBusyUserIds([userId]);
    return busy.contains(userId);
  }
}
