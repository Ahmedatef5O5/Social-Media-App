import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/call_model.dart';

class CallSignalingService {
  final _supabase = Supabase.instance.client;

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
    final user = _supabase.auth.currentUser;
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
}
