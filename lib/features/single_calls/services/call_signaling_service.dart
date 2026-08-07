import 'package:flutter/foundation.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../model/call_model.dart';

class CallSignalingService {
  final _supabase = SupabaseProvider.client;

  Future<void> sendCallRequest(CallModel call) async {
    await _supabase.from('calls').upsert(call.toMap());
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
          final cutoff = DateTime.now().subtract(const Duration(seconds: 30));
          return list.where((call) {
            final status = call['status'] as String?;
            if (status != CallStatus.ringing.name) return false;

            final startTimeStr = call['start_time'] as String?;
            if (startTimeStr == null) return true;
            final startTime = DateTime.tryParse(startTimeStr);
            if (startTime == null) return true;
            return startTime.isAfter(cutoff);
          }).toList();
        });
  }

  Stream<List<Map<String, dynamic>>> callStatusStream(String callId) =>
      _supabase
          .from('calls')
          .stream(primaryKey: ['call_id'])
          .eq('call_id', callId);

  Future<bool> isUserBusy(String userId) async {
    try {
      final activeSingleCall =
          await _supabase
              .from('calls')
              .select('call_id')
              .or('caller_id.eq.$userId,receiver_id.eq.$userId')
              .inFilter('status', ['ringing', 'accepted'])
              .maybeSingle();
      if (activeSingleCall != null) return true;

      final activeGroupCallAsInitiator =
          await _supabase
              .from('group_calls')
              .select('call_id')
              .eq('initiator_id', userId)
              .inFilter('status', ['ringing', 'accepted', 'ongoing'])
              .maybeSingle();
      return activeGroupCallAsInitiator != null;
    } catch (e) {
      debugPrint('isUserBusy check failed: $e');
      return false;
    }
  }
}
