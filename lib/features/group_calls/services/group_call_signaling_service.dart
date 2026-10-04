import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show RealtimeChannel, RealtimeSubscribeStatus;
import '../../../core/services/call_busy_checker.dart';
import '../../../core/services/fcm_services.dart';
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

  /// Forgets a previous decline so a user who is deliberately re-rung
  /// ("Ring" in the members sheet) is not filtered out by [_declinedBy].
  void clearDeclined(String callId, [String? userId]) {
    if (userId == null) {
      _declinedBy.remove(callId);
      return;
    }
    final declined = _declinedBy[callId];
    if (declined == null) return;
    declined.remove(userId);
    if (declined.isEmpty) _declinedBy.remove(callId);
  }

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
    final existingCall = await getActiveCall(groupId);
    if (existingCall != null) {
      return existingCall;
    }

    final callId = '${groupId}_${DateTime.now().millisecondsSinceEpoch}';

    IncomingCallNavigationGuard.markLocallyInitiated(callId);

    final now = DateTime.now().toUtc();

    final model = GroupCallModel(
      callId: callId,
      groupId: groupId,
      groupName: groupName,
      groupAvatarUrl: groupAvatarUrl,
      initiatorId: currentUserId,
      initiatorName: currentUserName,
      status: GroupCallStatus.ringing,
      type: type,
      startedAt: now,
      participantCount: 0,
    );
    await _supabase.from('group_calls').insert({
      ...model.toMap(),
      'started_at': now.toIso8601String(),
      'last_heartbeat_at': now.toIso8601String(),
    });

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

    unawaited(
      _updateCallMessage(callId, status: 'ongoing', onlyIfNotTerminal: true),
    );

    if (call.status == GroupCallStatus.ringing) {
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

  /// Rings ONE member of a group call that is already running.

  Future<void> ringGroupMember({
    required GroupCallModel call,
    required String targetMemberId,
    required String ringerUserId,
    required String ringerUserName,
  }) async {
    if (targetMemberId.isEmpty || targetMemberId == ringerUserId) return;

    final busy = await CallBusyChecker.findBusyUserIds([
      targetMemberId,
    ], excludeCallId: call.callId);
    if (busy.contains(targetMemberId)) {
      debugPrint(
        '[GroupCallSignaling] $targetMemberId is busy â€” ring skipped',
      );
      return;
    }

    final callType = call.type == GroupCallType.video ? 'video' : 'audio';
    final startedAtIso = call.startedAt.toUtc().toIso8601String();

    await Future.wait([
      _sendRingBroadcast(targetMemberId, {
        'target_user_ids': [targetMemberId],
        'callId': call.callId,
        'groupId': call.groupId,
        'groupName': call.groupName,
        'groupAvatarUrl': call.groupAvatarUrl ?? '',
        'callerId': ringerUserId,
        'callerName': ringerUserName,
        'callType': callType,
        'startedAt': startedAtIso,
      }),
      _sendRingPush(
        call: call,
        targetMemberId: targetMemberId,
        ringerUserId: ringerUserId,
        ringerUserName: ringerUserName,
        callType: callType,
        startedAtIso: startedAtIso,
      ),
    ]);
  }

  Future<void> _sendRingBroadcast(
    String targetMemberId,
    Map<String, dynamic> payload,
  ) async {
    RealtimeChannel? channel;
    try {
      channel = _supabase.channel('user_group_call_ring:$targetMemberId');
      final ready = Completer<void>();
      channel.subscribe((status, [error]) {
        if (ready.isCompleted) return;
        if (status == RealtimeSubscribeStatus.subscribed ||
            status == RealtimeSubscribeStatus.channelError ||
            status == RealtimeSubscribeStatus.timedOut ||
            status == RealtimeSubscribeStatus.closed) {
          ready.complete();
        }
      });
      await ready.future.timeout(const Duration(seconds: 3), onTimeout: () {});

      await channel.sendBroadcastMessage(
        event: 'ring_group_call',
        payload: payload,
      );
    } catch (e) {
      debugPrint('[GroupCallSignaling] ring broadcast failed: $e');
    } finally {
      final toRemove = channel;
      if (toRemove != null) {
        Timer(const Duration(seconds: 1), () {
          unawaited(_supabase.removeChannel(toRemove));
        });
      }
    }
  }

  Future<void> _sendRingPush({
    required GroupCallModel call,
    required String targetMemberId,
    required String ringerUserId,
    required String ringerUserName,
    required String callType,
    required String startedAtIso,
  }) async {
    try {
      final token = await _resolveFcmToken(
        groupId: call.groupId,
        targetMemberId: targetMemberId,
        ringerUserId: ringerUserId,
      );
      if (token == null || token.isEmpty) return;

      await FcmService.instance.sendGroupCallNotification(
        receiverFcmToken: token,
        callId: call.callId,
        groupId: call.groupId,
        groupName: call.groupName,
        groupAvatarUrl: call.groupAvatarUrl ?? '',
        callerId: ringerUserId,
        callerName: ringerUserName,
        callType: callType,
        startedAt: startedAtIso,
      );
    } catch (e) {
      debugPrint('[GroupCallSignaling] ring push failed: $e');
    }
  }

  Future<String?> _resolveFcmToken({
    required String groupId,
    required String targetMemberId,
    required String ringerUserId,
  }) async {
    try {
      final response = await _supabase.rpc(
        SupabaseConstants.groupGroupFcmTokens,
        params: {
          'p_group_id': groupId,
          'p_exclude_user_id': ringerUserId,
          'p_respect_mute': false,
        },
      );
      for (final row in response as List) {
        if (row['user_id'] == targetMemberId) {
          final token = row['fcm_token'] as String?;
          if (token != null && token.isNotEmpty) return token;
        }
      }
    } catch (e) {
      debugPrint('[GroupCallSignaling] get_group_fcm_tokens failed: $e');
    }

    try {
      final data =
          await _supabase
              .from('users')
              .select('fcm_token')
              .eq('id', targetMemberId)
              .maybeSingle();
      return data?['fcm_token'] as String?;
    } catch (e) {
      debugPrint('[GroupCallSignaling] users.fcm_token lookup failed: $e');
      return null;
    }
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
    // "00:00" / "0:00" / blank are never a real duration.
    String? effectiveDuration = normalizeDuration(duration);

    String? previousStatus;
    try {
      final row =
          await _supabase
              .from('group_calls')
              .select('started_at, status, duration')
              .eq('call_id', callId)
              .maybeSingle();

      if (row != null) {
        previousStatus = row['status'] as String?;
        final wasConnected =
            previousStatus == GroupCallStatus.accepted.name ||
            previousStatus == GroupCallStatus.ongoing.name;

        if (effectiveDuration == null) {
          final existingDuration = normalizeDuration(
            row['duration'] as String?,
          );
          if (existingDuration != null) {
            effectiveDuration = existingDuration;
          } else if (wasConnected) {
            final startedAt = DateTime.tryParse(
              row['started_at']?.toString() ?? '',
            );
            if (startedAt != null) {
              effectiveDuration = _computeDuration(
                startedAt.toUtc(),
                DateTime.now().toUtc(),
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[GroupCallSignaling] endCall row lookup failed: $e');
    }

    if (previousStatus == GroupCallStatus.ringing.name &&
        effectiveDuration == null) {
      await markAsMissed(callId);
      return;
    }

    try {
      await _supabase
          .from('group_calls')
          .update({
            'status': GroupCallStatus.ended.name,
            'ended_at': DateTime.now().toUtc().toIso8601String(),
            if (effectiveDuration != null) 'duration': effectiveDuration,
            if (participantCount != null) 'participant_count': participantCount,
          })
          .eq('call_id', callId)
          .inFilter('status', [
            GroupCallStatus.ringing.name,
            GroupCallStatus.accepted.name,
            GroupCallStatus.ongoing.name,
          ]);
    } catch (e) {
      debugPrint('[GroupCallSignaling] endCall update failed: $e');
      rethrow;
    }

    await _updateCallMessage(
      callId,
      status: 'ended',
      duration: effectiveDuration ?? '',
    );
  }

  /// Returns `null` for anything that is not a real, non-zero duration
  /// (`null`, blank, `00:00`, `0:00`, `00:00:00`).
  static String? normalizeDuration(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty ||
        trimmed == '00:00' ||
        trimmed == '0:00' ||
        trimmed == '00:00:00') {
      return null;
    }
    return trimmed;
  }

  Future<void> syncCallMessageStatus(
    String callId, {
    String? fallbackDuration,
  }) async {
    try {
      Map<String, dynamic>? row;
      var status = '';
      for (var attempt = 0; attempt < 5; attempt++) {
        row =
            await _supabase
                .from('group_calls')
                .select(
                  'status, started_at, ended_at, duration, '
                  'participant_count, last_heartbeat_at',
                )
                .eq('call_id', callId)
                .maybeSingle();
        if (row == null) return;
        status = row['status'] as String? ?? '';
        if (status == GroupCallStatus.ended.name ||
            status == GroupCallStatus.missed.name) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 1500));
      }
      if (row == null) return;

      if (status == GroupCallStatus.missed.name) {
        await _updateCallMessage(callId, status: 'missed', duration: null);
        return;
      }
      if (status != GroupCallStatus.ended.name) return;

      var duration = normalizeDuration(row['duration'] as String?) ?? '';
      if (duration.isEmpty) {
        duration = computeConnectedDuration(row) ?? '';
        final fallback = normalizeDuration(fallbackDuration);
        if (duration.isEmpty && fallback != null) {
          duration = fallback;
        }
        if (duration.isNotEmpty) {
          // Backfill the authoritative row too (best effort).
          try {
            await _supabase
                .from('group_calls')
                .update({'duration': duration})
                .eq('call_id', callId);
          } catch (e) {
            debugPrint('[GroupCallSignaling] duration backfill failed: $e');
          }
        }
      }

      await _updateCallMessage(callId, status: 'ended', duration: duration);
    } catch (e) {
      debugPrint('[GroupCallSignaling] syncCallMessageStatus failed: $e');
    }
  }

  static String? computeConnectedDuration(Map<String, dynamic> row) {
    final status = row['status'] as String?;
    if (status == GroupCallStatus.ringing.name ||
        status == GroupCallStatus.missed.name) {
      return null;
    }

    final startedAt = DateTime.tryParse(row['started_at']?.toString() ?? '');
    final endedAt = DateTime.tryParse(row['ended_at']?.toString() ?? '');
    if (startedAt == null || endedAt == null) return null;

    final heartbeat = DateTime.tryParse(
      row['last_heartbeat_at']?.toString() ?? '',
    );

    final heartbeatMoved =
        heartbeat != null &&
        heartbeat.toUtc().difference(startedAt.toUtc()).inSeconds >= 1;
    final participants = (row['participant_count'] as int?) ?? 0;
    if (!heartbeatMoved && participants <= 1) return null;

    final elapsed = endedAt.toUtc().difference(startedAt.toUtc());
    if (elapsed.inSeconds < 1) return null;

    return _formatDuration(elapsed);
  }

  static String _computeDuration(DateTime startedAtUtc, DateTime endedAtUtc) {
    var diff = endedAtUtc.difference(startedAtUtc);
    if (diff.inSeconds < 1) diff = const Duration(seconds: 1);
    return _formatDuration(diff);
  }

  static String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  Future<void> _updateCallMessage(
    String callId, {
    required String status,
    String? duration,
    bool onlyIfNotTerminal = false,
  }) async {
    try {
      final existing =
          await _supabase
              .from(SupabaseConstants.groupMessages)
              .select('id, message_text')
              .eq('message_type', 'call')
              .ilike('message_text', '%$callId%')
              .limit(1)
              .maybeSingle();
      if (existing == null) return;

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

      final currentStatus = callData['status'] as String?;
      if (onlyIfNotTerminal &&
          (currentStatus == 'ended' || currentStatus == 'missed')) {
        return;
      }

      callData['status'] = status;
      if (status == 'ended') {
        callData['duration'] = duration ?? '';
      } else if (status == 'missed') {
        callData['duration'] = null;
      }

      await _supabase
          .from(SupabaseConstants.groupMessages)
          .update({'message_text': jsonEncode(callData)})
          .eq('id', existing['id'] as String);
    } catch (e) {
      debugPrint('[GroupCallSignaling] _updateCallMessage($status) error: $e');
    }
  }

  Future<void> markAsMissed(String callId) async {
    final updated =
        await _supabase
            .from('group_calls')
            .update({
              'status': GroupCallStatus.missed.name,
              'ended_at': DateTime.now().toUtc().toIso8601String(),
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

  static const Duration _ringingStaleAfter = Duration(seconds: 50);

  bool _isHeartbeatStale(Map<String, dynamic> row) {
    final status = row['status'] as String?;
    if (status == GroupCallStatus.ringing.name) {
      final startedRaw = row['started_at'] ?? row['last_heartbeat_at'];
      final startedTs =
          DateTime.tryParse(startedRaw?.toString() ?? '')?.toUtc();
      if (startedTs == null) return true;
      return DateTime.now().toUtc().difference(startedTs) > _ringingStaleAfter;
    }
    if (status != GroupCallStatus.accepted.name &&
        status != GroupCallStatus.ongoing.name) {
      return false;
    }

    final raw = row['last_heartbeat_at'] ?? row['started_at'];
    final ts = DateTime.tryParse(raw?.toString() ?? '')?.toUtc();
    if (ts == null) return false;

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
    final rows = await _supabase
        .from('group_calls')
        .select()
        .eq(GroupMemberColumns.groupId, groupId)
        .inFilter('status', ['ringing', 'accepted', 'ongoing'])
        .order('started_at', ascending: false);

    final list = (rows as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) return null;

    GroupCallModel? freshCall;
    for (final row in list) {
      if (freshCall == null && !await _healIfStale(row)) {
        freshCall = GroupCallModel.fromMap(row);
      } else {
        final staleId = row['call_id'] as String?;
        if (staleId != null && staleId.isNotEmpty) {
          unawaited(endCall(staleId, participantCount: 0));
        }
      }
    }
    return freshCall;
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
