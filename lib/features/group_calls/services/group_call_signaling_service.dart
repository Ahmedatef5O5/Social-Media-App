import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/services/incoming_call_navigation_guard.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../../group_chats/services/group_notification_dispatcher.dart';
import '../models/group_call_model.dart';

class GroupCallSignalingService {
  final _supabase = SupabaseProvider.client;
  final Map<String, Set<String>> _declinedBy = {};
  bool _hasDeclined(String callId, String userId) =>
      _declinedBy[callId]?.contains(userId) ?? false;

  static const Duration _endedConfirmationWindow = Duration(seconds: 2);

  static const Duration _heartbeatStaleAfter = Duration(seconds: 40);

  Future<List<String>> getGroupMemberIds(String groupId) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.groupMembers)
          .select(GroupMemberColumns.userId)
          .eq(GroupMemberColumns.groupId, groupId);

      return (response as List)
          .map((e) => e[GroupMemberColumns.userId] as String)
          .toList();
    } catch (e) {
      debugPrint('getGroupMemberIds error: $e');
      return [];
    }
  }

  Future<GroupCallModel> initiateCall({
    required String groupId,
    required String groupName,
    String? groupAvatarUrl,
    required String currentUserId,
    required String currentUserName,
    required GroupCallType type,
  }) async {
    final existing =
        await _supabase
            .from('group_calls')
            .select()
            .eq(GroupMemberColumns.groupId, groupId)
            .inFilter('status', ['ringing', 'accepted', 'ongoing'])
            .maybeSingle();

    if (existing != null && !await _healIfStale(existing)) {
      return GroupCallModel.fromMap(existing);
    }

    final callId = '${groupId}_${DateTime.now().millisecondsSinceEpoch}';

    // Register this call as OURS before the row exists and before any push
    // is fired. From this instant the realtime stream / FCM echo of our own
    // call can never open an IncomingGroupCallScreen on this device.
    IncomingCallNavigationGuard.markLocallyInitiated(callId);

    final model = GroupCallModel(
      callId: callId,
      groupId: groupId,
      groupName: groupName,
      groupAvatarUrl: groupAvatarUrl,
      initiatorId: currentUserId,
      initiatorName: currentUserName,
      status: GroupCallStatus.ringing,
      type: type,
      startedAt: DateTime.now(),
      participantCount: 0,
    );
    await _supabase.from('group_calls').insert(model.toMap());

    final initiatorProfile =
        await _supabase
            .from('users')
            .select('image_url')
            .eq('id', currentUserId)
            .maybeSingle();
    final initiatorAvatar = initiatorProfile?['image_url'] as String? ?? '';

    await _supabase.from(SupabaseConstants.groupMessages).insert({
      GroupMemberColumns.groupId: groupId,
      'sender_id': currentUserId,
      'sender_name': currentUserName,
      'sender_avatar': initiatorAvatar,
      'message_text': jsonEncode({
        'call_id': callId,
        GroupMemberColumns.groupId: groupId,
        'call_type': type == GroupCallType.video ? 'video' : 'audio',
        'status': 'ringing',
        'initiator_id': currentUserId,
        'initiator_name': currentUserName,
        'initiator_avatar': initiatorAvatar,
        'group_avatar_url': groupAvatarUrl ?? '',
        'duration': null,
      }),
      'message_type': 'call',
    });

    unawaited(
      GroupNotificationDispatcher.instance.notifyIncomingCall(
        groupId: groupId,
        callId: callId,
        groupName: groupName,
        groupAvatarUrl: groupAvatarUrl ?? '',
        callerId: currentUserId,
        callerName: currentUserName,
        callType: type == GroupCallType.video ? 'video' : 'audio',
        startedAt: model.startedAt.toIso8601String(),
      ),
    );

    return model;
  }

  Future<GroupCallModel> acceptCall(String callId) async {
    final existing =
        await _supabase
            .from('group_calls')
            .select()
            .eq('call_id', callId)
            .single();

    final call = GroupCallModel.fromMap(existing);
    final nowIso = DateTime.now().toUtc().toIso8601String();

    if (call.status == GroupCallStatus.ringing) {
      // ringing -> accepted: the initiator is already in the room (they enter
      // LiveKit from OutgoingGroupCallScreen without touching the counter),
      // so the first acceptor makes it TWO participants: initiator + acceptor.
      // Writing 1 here made `leaveCall` think a 2-person call had one person
      // and end/keep it incorrectly.
      const int initiatorPlusFirstAcceptor = 2;
      await _supabase
          .from('group_calls')
          .update({
            'status': GroupCallStatus.accepted.name,
            'participant_count': initiatorPlusFirstAcceptor,
            'last_heartbeat_at': nowIso,
          })
          .eq('call_id', callId);

      return call.copyWith(
        status: GroupCallStatus.accepted,
        participantCount: initiatorPlusFirstAcceptor,
        lastHeartbeatAt: DateTime.parse(nowIso),
      );
    }

    if (call.status == GroupCallStatus.accepted ||
        call.status == GroupCallStatus.ongoing) {
      final newCount = call.participantCount + 1;
      await _supabase
          .from('group_calls')
          .update({
            'status': GroupCallStatus.ongoing.name,
            'participant_count': newCount,
            'last_heartbeat_at': nowIso,
          })
          .eq('call_id', callId);

      return call.copyWith(
        status: GroupCallStatus.ongoing,
        participantCount: newCount,
        lastHeartbeatAt: DateTime.parse(nowIso),
      );
    }

    return call;
  }

  Future<void> rejectCall(String callId) async {
    final userId = SupabaseProvider.id;
    (_declinedBy[callId] ??= {}).add(userId);
    Timer(const Duration(seconds: 60), () => _declinedBy.remove(callId));
  }

  Future<void> sendHeartbeat(String callId) async {
    try {
      await _supabase
          .from('group_calls')
          .update({
            'last_heartbeat_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('call_id', callId)
          .inFilter('status', [
            GroupCallStatus.accepted.name,
            GroupCallStatus.ongoing.name,
          ]);
    } catch (e) {
      debugPrint('[GroupCallSignaling] sendHeartbeat failed: $e');
    }
  }

  Future<void> leaveCall(String callId) async {
    final existing =
        await _supabase
            .from('group_calls')
            .select('participant_count, status')
            .eq('call_id', callId)
            .maybeSingle();
    if (existing == null) return;

    final status = existing['status'] as String;
    if (status != GroupCallStatus.accepted.name &&
        status != GroupCallStatus.ongoing.name) {
      return;
    }

    final count = (existing['participant_count'] as int?) ?? 0;
    final newCount = (count - 1).clamp(0, count);

    if (newCount < 2) {
      await endCall(callId, participantCount: newCount);
      return;
    }

    await _supabase
        .from('group_calls')
        .update({'participant_count': newCount})
        .eq('call_id', callId)
        .eq('status', status);
  }

  Future<void> endCall(
    String callId, {
    String? duration,
    int? participantCount,
  }) async {
    await _supabase
        .from('group_calls')
        .update({
          'status': GroupCallStatus.ended.name,
          'ended_at': DateTime.now().toIso8601String(),
          if (duration != null) 'duration': duration,
          if (participantCount != null) 'participant_count': participantCount,
        })
        .eq('call_id', callId);

    try {
      final existing =
          await _supabase
              .from(SupabaseConstants.groupMessages)
              .select('id, message_text')
              .eq('message_type', 'call')
              .ilike('message_text', '%$callId%')
              .maybeSingle();

      if (existing != null) {
        Map<String, dynamic> callData = {};
        try {
          callData =
              jsonDecode(existing['message_text'] as String)
                  as Map<String, dynamic>;
        } catch (e) {
          debugPrint(
            '[GroupCallSignaling] failed to decode existing call payload: $e',
          );
        }
        callData['status'] = 'ended';
        callData['duration'] = duration?.isNotEmpty == true ? duration : '';

        await _supabase
            .from(SupabaseConstants.groupMessages)
            .update({'message_text': jsonEncode(callData)})
            .eq('id', existing['id'] as String);
      }
    } catch (e) {
      debugPrint('endCall update message error: $e');
    }
  }

  Future<void> markAsMissed(String callId) async {
    final updated =
        await _supabase
            .from('group_calls')
            .update({
              'status': GroupCallStatus.missed.name,
              'ended_at': DateTime.now().toIso8601String(),
            })
            .eq('call_id', callId)
            .eq('status', GroupCallStatus.ringing.name)
            .select();

    final rows = updated as List;
    final wasRinging = rows.isNotEmpty;

    try {
      final existing =
          await _supabase
              .from(SupabaseConstants.groupMessages)
              .select('id, message_text')
              .eq('message_type', 'call')
              .ilike('message_text', '%$callId%')
              .maybeSingle();

      if (existing != null) {
        Map<String, dynamic> callData = {};
        try {
          callData =
              jsonDecode(existing['message_text'] as String)
                  as Map<String, dynamic>;
        } catch (e) {
          debugPrint(
            '[GroupCallSignaling] failed to decode call payload for update: $e',
          );
        }

        callData['status'] = 'missed';
        callData['duration'] = null;

        await _supabase
            .from(SupabaseConstants.groupMessages)
            .update({'message_text': jsonEncode(callData)})
            .eq('id', existing['id'] as String);
      }
    } catch (e) {
      debugPrint('markAsMissed update message error: $e');
    }

    if (wasRinging) {
      final row = rows.first as Map<String, dynamic>;
      final groupId = row[GroupMemberColumns.groupId] as String?;
      final initiatorId = row['initiator_id'] as String?;
      if (groupId != null && initiatorId != null) {
        unawaited(
          GroupNotificationDispatcher.instance.notifyCallCancelled(
            groupId: groupId,
            callId: callId,
            initiatorId: initiatorId,
          ),
        );
      }
    }
  }

  bool _isHeartbeatStale(Map<String, dynamic> row) {
    final status = row['status'] as String?;
    if (status != GroupCallStatus.accepted.name &&
        status != GroupCallStatus.ongoing.name) {
      return false;
    }

    final raw = row['last_heartbeat_at'] ?? row['started_at'];
    final ts = DateTime.tryParse(raw?.toString() ?? '')?.toUtc();
    if (ts == null) return false; // fail-safe: never reap on missing data

    return DateTime.now().toUtc().difference(ts) > _heartbeatStaleAfter;
  }

  Future<bool> _healIfStale(Map<String, dynamic> row) async {
    if (!_isHeartbeatStale(row)) return false;

    final callId = row['call_id'] as String;
    debugPrint(
      '[GroupCallSignaling] reaping abandoned call $callId (heartbeat stale)',
    );
    await endCall(callId, participantCount: 0);
    return true;
  }

  Stream<GroupCallModel?> activeCallStream(String groupId) {
    final rawStream = _supabase
        .from('group_calls')
        .stream(primaryKey: ['call_id'])
        .eq(GroupMemberColumns.groupId, groupId)
        .map((list) {
          final active =
              list
                  .where(
                    (m) => [
                      'ringing',
                      'accepted',
                      'ongoing',
                    ].contains(m['status']),
                  )
                  .toList();
          if (active.isNotEmpty) {
            return _CallSnapshot.active(GroupCallModel.fromMap(active.first));
          }

          final hasTerminalRow = list.any(
            (m) => ['ended', 'missed'].contains(m['status']),
          );
          return hasTerminalRow
              ? const _CallSnapshot.confirmedEnded()
              : const _CallSnapshot.ambiguous();
        });

    return _debounceNullTransitions(groupId, rawStream);
  }

  Stream<GroupCallModel?> _debounceNullTransitions(
    String groupId,
    Stream<_CallSnapshot> source,
  ) {
    late StreamController<GroupCallModel?> controller;
    StreamSubscription<_CallSnapshot>? sourceSub;
    Timer? confirmTimer;
    Timer? staleWatchTimer;
    GroupCallModel? lastConfirmedCall;

    Future<void> confirmAndMaybeEmitNull() async {
      if (controller.isClosed) return;
      try {
        final confirmed = await getActiveCall(groupId);
        if (controller.isClosed) return;
        if (confirmed == null) {
          lastConfirmedCall = null;
          controller.add(null);
        }
      } catch (e) {
        debugPrint(
          '[GroupCallSignaling] ended-confirmation re-check failed: $e',
        );
      }
    }

    Future<void> pollForAbandonedCall() async {
      if (controller.isClosed || lastConfirmedCall == null) return;
      try {
        final confirmed = await getActiveCall(groupId);
        if (controller.isClosed) return;
        if (confirmed == null && lastConfirmedCall != null) {
          lastConfirmedCall = null;
          controller.add(null);
        }
      } catch (e) {
        debugPrint('[GroupCallSignaling] stale-call poll failed: $e');
      }
    }

    controller = StreamController<GroupCallModel?>.broadcast(
      onListen: () {
        sourceSub = source.listen(
          (snapshot) {
            confirmTimer?.cancel();

            if (snapshot.call != null) {
              lastConfirmedCall = snapshot.call;
              controller.add(snapshot.call);
              return;
            }

            if (snapshot.confirmedEnded) {
              lastConfirmedCall = null;
              controller.add(null);
              return;
            }

            if (lastConfirmedCall == null) {
              controller.add(null);
              return;
            }

            confirmTimer = Timer(
              _endedConfirmationWindow,
              confirmAndMaybeEmitNull,
            );
          },
          onError: (e, st) {
            if (!controller.isClosed) controller.addError(e, st);
          },
          onDone: () {
            if (!controller.isClosed) controller.close();
          },
        );
        staleWatchTimer = Timer.periodic(
          _heartbeatStaleAfter,
          (_) => pollForAbandonedCall(),
        );
      },
      onCancel: () {
        confirmTimer?.cancel();
        staleWatchTimer?.cancel();
        sourceSub?.cancel();
      },
    );

    return controller.stream;
  }

  Stream<List<GroupCallModel>> incomingGroupCallsStream(String myUserId) {
    return _supabase
        .from('group_calls')
        .stream(primaryKey: ['call_id'])
        .eq('status', 'ringing')
        .map((list) {
          final cutoff = DateTime.now().toUtc().subtract(
            const Duration(seconds: 45),
          );

          return list
              .where((m) {
                final initiatorId = m['initiator_id'] ?? m['initiatorId'];
                if (initiatorId == myUserId) return false;

                final callId = m['call_id'] as String?;
                if (callId != null && _hasDeclined(callId, myUserId)) {
                  return false;
                }

                final startedStr = m['started_at'];
                if (startedStr != null) {
                  final started =
                      DateTime.tryParse(startedStr.toString())?.toUtc();
                  if (started != null && started.isBefore(cutoff)) return false;
                }
                return true;
              })
              .map((m) => GroupCallModel.fromMap(m))
              .toList();
        });
  }

  Future<GroupCallModel?> getActiveCall(String groupId) async {
    final result =
        await _supabase
            .from('group_calls')
            .select()
            .eq(GroupMemberColumns.groupId, groupId)
            .inFilter('status', ['ringing', 'accepted', 'ongoing'])
            .maybeSingle();

    if (result == null) return null;
    if (await _healIfStale(result)) return null;
    return GroupCallModel.fromMap(result);
  }

  Future<bool> isActiveGroupMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      final row =
          await _supabase
              .from(SupabaseConstants.groupMembers)
              .select(GroupMemberColumns.membershipStatus)
              .eq(GroupMemberColumns.groupId, groupId)
              .eq(GroupMemberColumns.userId, userId)
              .maybeSingle();

      return row != null &&
          row[GroupMemberColumns.membershipStatus] == 'active';
    } catch (e) {
      debugPrint('isActiveGroupMember check failed: $e');
      return true;
    }
  }
}

class _CallSnapshot {
  final GroupCallModel? call;
  final bool confirmedEnded;

  const _CallSnapshot.active(GroupCallModel call)
    : call = call,
      confirmedEnded = false;
  const _CallSnapshot.confirmedEnded() : call = null, confirmedEnded = true;
  const _CallSnapshot.ambiguous() : call = null, confirmedEnded = false;
}
