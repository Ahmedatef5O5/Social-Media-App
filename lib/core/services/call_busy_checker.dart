import 'package:flutter/foundation.dart';
import '../supabase/supabase_provider.dart';

/// Server-side "is this user already on a call?" lookup, used by the SENDER of
/// a call so busy members are not interrupted.
///
/// Note: The receiver's own device ALWAYS enforces busy protection locally
/// (in-memory + SharedPreferences across isolates) and auto-rejects 1:1 calls
/// or drops group call pushes while in an active call. Because the `calls`
/// table has no heartbeat column, we only treat very fresh `calls` rows as
/// busy on the sender side so an abnormal app exit never locks a user out.
class CallBusyChecker {
  const CallBusyChecker._();

  static const Duration _ringingFreshFor = Duration(seconds: 45);
  static const Duration _singleAcceptedFreshFor = Duration(seconds: 90);
  static const Duration _heartbeatFreshFor = Duration(seconds: 60);

  static Future<Set<String>> findBusyUserIds(
    Iterable<String> userIds, {
    String? excludeCallId,
  }) async {
    final ids = userIds.where((e) => e.isNotEmpty).toSet().toList();
    if (ids.isEmpty) return <String>{};

    final busy = <String>{};
    final now = DateTime.now().toUtc();
    final idList = ids.join(',');

    try {
      final rows = await SupabaseProvider.client
          .from('calls')
          .select('call_id, caller_id, receiver_id, status, start_time')
          .inFilter('status', ['ringing', 'accepted'])
          .or('caller_id.in.($idList),receiver_id.in.($idList)')
          .limit(200);

      for (final row in rows as List) {
        final callId = row['call_id'] as String? ?? '';
        if (excludeCallId != null && callId == excludeCallId) continue;

        final status = row['status'] as String? ?? '';
        final createdAt = _singleCallCreatedAt(row, callId);
        if (createdAt == null) continue;

        final age = now.difference(createdAt);
        if (status == 'ringing' && age > _ringingFreshFor) continue;
        if (status == 'accepted' && age > _singleAcceptedFreshFor) continue;

        final caller = row['caller_id'] as String?;
        final receiver = row['receiver_id'] as String?;
        if (caller != null && ids.contains(caller)) busy.add(caller);
        if (receiver != null && ids.contains(receiver)) busy.add(receiver);
      }
    } catch (e) {
      debugPrint('[CallBusyChecker] 1:1 lookup failed: $e');
    }

    try {
      final rows = await SupabaseProvider.client
          .from('group_calls')
          .select('call_id, initiator_id, status, started_at, last_heartbeat_at')
          .inFilter('initiator_id', ids)
          .inFilter('status', ['ringing', 'accepted', 'ongoing'])
          .limit(200);

      for (final row in rows as List) {
        final callId = row['call_id'] as String? ?? '';
        if (excludeCallId != null && callId == excludeCallId) continue;

        final status = row['status'] as String? ?? '';
        final startedAt = DateTime.tryParse(row['started_at']?.toString() ?? '');
        final heartbeat = DateTime.tryParse(
          row['last_heartbeat_at']?.toString() ?? '',
        );

        if (status == 'ringing') {
          if (startedAt == null ||
              now.difference(startedAt.toUtc()) > _ringingFreshFor) {
            continue;
          }
        } else {
          final ref = heartbeat ?? startedAt;
          if (ref == null || now.difference(ref.toUtc()) > _heartbeatFreshFor) {
            continue;
          }
        }

        final initiator = row['initiator_id'] as String?;
        if (initiator != null) busy.add(initiator);
      }
    } catch (e) {
      debugPrint('[CallBusyChecker] group lookup failed: $e');
    }

    return busy;
  }

  static DateTime? _singleCallCreatedAt(Map row, String callId) {
    final startTime = DateTime.tryParse(row['start_time']?.toString() ?? '');
    if (startTime != null) return startTime.toUtc();

    if (callId.startsWith('room_')) {
      final ms = int.tryParse(callId.substring(5));
      if (ms != null) {
        return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
      }
    }
    return null;
  }
}
