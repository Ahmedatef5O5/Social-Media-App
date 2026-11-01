import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../core/services/cloudinary_storage_services.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../models/group_join_request_model.dart';
import '../models/group_model.dart';
import '../models/group_profile_model.dart';

/// Social layer of a group: profile, join requests, posting policy and cover.
/// Stateless; every rule is enforced server-side (RLS + SECURITY DEFINER RPCs).
class GroupSocialService {
  GroupSocialService();

  final _supabase = SupabaseProvider.client;

  CloudinaryStorageServices get _storage => CloudinaryStorageServices.instance;

  Future<GroupProfileModel?> getGroupProfile(String groupId) async {
    final rows = await _supabase.rpc(
      SupabaseConstants.getGroupProfileRpc,
      params: {'p_group_id': groupId},
    );
    final list = (rows as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) return null;
    return GroupProfileModel.fromMap(list.first);
  }

  /// Returns the resulting request status ('pending' or 'accepted' when the
  /// caller already is an active member).
  Future<GroupJoinRequestStatus> requestToJoin(String groupId) async {
    final status = await _supabase.rpc(
      SupabaseConstants.requestJoinGroupRpc,
      params: {'p_group_id': groupId},
    );
    return GroupJoinRequestStatus.fromDb(status as String?);
  }

  Future<List<GroupJoinRequestModel>> getPendingRequests(String groupId) async {
    final rows = await _supabase.rpc(
      SupabaseConstants.getGroupJoinRequestsRpc,
      params: {'p_group_id': groupId},
    );
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(GroupJoinRequestModel.fromMap)
        .toList();
  }

  Future<void> reviewRequest(String requestId, {required bool accept}) async {
    await _supabase.rpc(
      SupabaseConstants.reviewJoinRequestRpc,
      params: {
        'p_request_id': requestId,
        'p_status': accept ? 'accepted' : 'rejected',
      },
    );
  }

  /// Live status of MY request for [groupId] (RLS limits rows to my own).
  Stream<GroupJoinRequestStatus> watchMyRequestStatus(String groupId) {
    final myId = SupabaseProvider.id;
    return _supabase
        .from(SupabaseConstants.groupJoinRequests)
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .map((rows) {
          for (final r in rows) {
            if (r['user_id'] == myId) {
              return GroupJoinRequestStatus.fromDb(r['status'] as String?);
            }
          }
          return GroupJoinRequestStatus.none;
        });
  }

  /// Live count of pending requests (admins only see rows through RLS).
  Stream<int> watchPendingCount(String groupId) {
    return _supabase
        .from(SupabaseConstants.groupJoinRequests)
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .map((rows) => rows.where((r) => r['status'] == 'pending').length);
  }

  Future<void> updateWhoCanPost(String groupId, GroupWhoCanPost value) async {
    final res =
        await _supabase
            .from(SupabaseConstants.groups)
            .update({GroupColumns.whoCanPost: value.dbValue})
            .eq(GroupColumns.id, groupId)
            .select();
    if (res.isEmpty) throw Exception('Database update blocked by RLS Policy!');
  }

  Future<({String url, String? publicId})> uploadCover(File file) async {
    final r = await _storage.uploadFile(
      file,
      'covers',
      'groups',
      filePrefix: 'group_cover_',
    );
    return (url: r.secureUrl, publicId: r.publicId);
  }

  Future<void> updateCover(String groupId, String url, String? publicId) async {
    final res =
        await _supabase
            .from(SupabaseConstants.groups)
            .update({
              GroupColumns.coverUrl: url,
              if (publicId != null) GroupColumns.coverPublicId: publicId,
            })
            .eq(GroupColumns.id, groupId)
            .select();
    if (res.isEmpty) throw Exception('Database update blocked by RLS Policy!');
  }

  Future<Map<String, int>> getMemberCounts(List<String> groupIds) async {
    if (groupIds.isEmpty) return {};
    try {
      final rows = await _supabase.rpc(
        SupabaseConstants.getGroupsMemberCountsRpc,
        params: {'p_group_ids': groupIds},
      );
      return {
        for (final r in (rows as List).cast<Map<String, dynamic>>())
          r['group_id'] as String: (r['members_count'] as num).toInt(),
      };
    } catch (e) {
      debugPrint('[GroupSocialService] member counts failed: $e');
      return {};
    }
  }
}
