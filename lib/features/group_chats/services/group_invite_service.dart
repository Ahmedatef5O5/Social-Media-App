import 'package:flutter/material.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../models/group_invite_preview.dart';
import '../models/group_invite_state.dart';
import '../models/group_model.dart';
import 'group_membership_service.dart';

class GroupInviteService {
  GroupInviteService({GroupMembershipService? membershipService})
    : _membershipService = membershipService ?? GroupMembershipService();

  final _supabase = SupabaseProvider.client;
  final GroupMembershipService _membershipService;

  String get currentUserId => SupabaseProvider.id;

  final Map<String, GroupInviteState?> _inviteStateCache = {};

  bool hasCachedInviteState(String groupId) =>
      _inviteStateCache.containsKey(groupId);

  GroupInviteState? getCachedInviteState(String groupId) =>
      _inviteStateCache[groupId];

  Future<GroupInviteState?> getGroupInviteState(String groupId) async {
    final row =
        await _supabase
            .from(SupabaseConstants.groups)
            .select('invite_hash, invite_expires_at, invite_join_count')
            .eq('id', groupId)
            .maybeSingle();

    final state =
        (row == null || row['invite_hash'] == null)
            ? null
            : GroupInviteState.fromMap(row);

    _inviteStateCache[groupId] = state;
    return state;
  }

  Future<GroupInviteState> generateGroupInviteLink(
    String groupId, {
    Duration? expiresIn,
  }) async {
    try {
      final row =
          await _supabase
              .rpc(
                'generate_group_invite_link',
                params: {
                  'p_group_id': groupId,
                  'p_expires_in_hours': expiresIn?.inHours,
                },
              )
              .single();
      final state = GroupInviteState.fromMap(row);
      _inviteStateCache[groupId] = state;
      return state;
    } catch (e, s) {
      debugPrint('❌ generateGroupInviteLink Error: $e\n$s');
      throw Exception('Failed to generate group invite link: $e');
    }
  }

  Future<void> revokeGroupInviteLink(String groupId) async {
    await _supabase.rpc(
      'revoke_group_invite_link',
      params: {'p_group_id': groupId},
    );
    _inviteStateCache[groupId] = null;
  }

  Future<GroupInvitePreview> getGroupInvitePreview(String inviteHash) async {
    final row =
        await _supabase
            .rpc(
              'get_group_invite_preview',
              params: {'p_invite_hash': inviteHash},
            )
            .single();
    return GroupInvitePreview.fromMap(row);
  }

  Future<GroupModel> joinGroupViaInvite(String inviteHash) async {
    final row =
        await _supabase
            .rpc('join_group_via_invite', params: {'p_invite_hash': inviteHash})
            .single();
    final group = GroupModel.fromMap(row);

    final names = await _membershipService.fetchUserNames([currentUserId]);
    await _membershipService.sendSystemEvent(
      groupId: group.id,
      type: 'member_joined_via_invite',
      actorId: currentUserId,
      actorName: names[currentUserId] ?? 'Someone',
    );

    return group;
  }
}