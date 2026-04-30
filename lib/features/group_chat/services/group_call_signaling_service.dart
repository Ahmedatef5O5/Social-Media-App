import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/group_call_model.dart';

class GroupCallSignalingService {
  final _supabase = Supabase.instance.client;

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
            .eq('group_id', groupId)
            .inFilter('status', ['ringing', 'accepted', 'ongoing'])
            .maybeSingle();
    if (existing != null) {
      return GroupCallModel.fromMap(existing);
    }
    final callId = '${groupId}_${DateTime.now().millisecondsSinceEpoch}';
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

    await _supabase.from('group_messages').insert({
      'group_id': groupId,
      'sender_id': currentUserId,
      'sender_name': currentUserName,
      'sender_avatar': initiatorAvatar,
      'message_text': jsonEncode({
        'call_id': callId,
        'group_id': groupId,
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

    if (call.status == GroupCallStatus.ringing) {
      await _supabase
          .from('group_calls')
          .update({
            'status': GroupCallStatus.accepted.name,
            'participant_count': 1,
          })
          .eq('call_id', callId);

      return call.copyWith(
        status: GroupCallStatus.accepted,
        participantCount: 1,
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
          })
          .eq('call_id', callId);

      return call.copyWith(
        status: GroupCallStatus.ongoing,
        participantCount: newCount,
      );
    }

    return call;
  }

  Future<void> rejectCall(String callId) async {
    // reject call
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
              .from('group_messages')
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
        } catch (_) {}

        callData['status'] = 'ended';
        callData['duration'] = duration?.isNotEmpty == true ? duration : '';

        await _supabase
            .from('group_messages')
            .update({'message_text': jsonEncode(callData)})
            .eq('id', existing['id'] as String);
      }
    } catch (e) {
      debugPrint('endCall update message error: $e');
    }
  }

  Future<void> markAsMissed(String callId) async {
    await _supabase
        .from('group_calls')
        .update({
          'status': GroupCallStatus.missed.name,
          'ended_at': DateTime.now().toIso8601String(),
        })
        .eq('call_id', callId)
        .eq('status', GroupCallStatus.ringing.name);

    try {
      final existing =
          await _supabase
              .from('group_messages')
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
        } catch (_) {}

        callData['status'] = 'missed';
        callData['duration'] = null;

        await _supabase
            .from('group_messages')
            .update({'message_text': jsonEncode(callData)})
            .eq('id', existing['id'] as String);
      }
    } catch (e) {
      debugPrint('markAsMissed update message error: $e');
    }
  }

  Stream<GroupCallModel?> activeCallStream(String groupId) {
    return _supabase
        .from('group_calls')
        .stream(primaryKey: ['call_id'])
        .eq('group_id', groupId)
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
          if (active.isEmpty) return null;
          return GroupCallModel.fromMap(active.first);
        });
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
                if (m['initiator_id'] == myUserId) return false;
                final started =
                    DateTime.tryParse(m['started_at'] ?? '')?.toUtc();
                if (started == null) return true;
                return started.isAfter(cutoff);
              })
              .map(GroupCallModel.fromMap)
              .toList();
        });
  }

  Future<GroupCallModel?> getActiveCall(String groupId) async {
    final result =
        await _supabase
            .from('group_calls')
            .select()
            .eq('group_id', groupId)
            .inFilter('status', ['ringing', 'accepted', 'ongoing'])
            .maybeSingle();

    if (result == null) return null;
    return GroupCallModel.fromMap(result);
  }
}
