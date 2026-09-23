import 'package:social_media_app/core/supabase/supabase_provider.dart';
import 'package:social_media_app/core/utilities/supabase_constants.dart';
import '../../auth/data/models/user_data.dart';
import '../models/friend_list_item_model.dart';
import '../models/friends_page_model.dart';

class FriendshipServices {
  final _supabase = SupabaseProvider.client;

  static const String _getUserFriendsRpc = 'get_user_friends';

  Future<List<FriendListItemModel>> getFriends(
    String userId, {
    int limit = 30,
    int offset = 0,
  }) async {
    final page = await getFriendsPage(userId, limit: limit, offset: offset);
    return page.items;
  }

  Future<FriendsPage> getFriendsPage(
    String userId, {
    int limit = 30,
    int offset = 0,
  }) async {
    final rows = await _supabase.rpc(
      _getUserFriendsRpc,
      params: {'p_user_id': userId, 'p_limit': limit, 'p_offset': offset},
    );

    int? totalCount;
    final items = <FriendListItemModel>[];
    for (final row in rows as List) {
      final map = row as Map<String, dynamic>;
      totalCount ??= (map['total_count'] as num?)?.toInt();
      items.add(
        FriendListItemModel(
          user: UserData.fromMap(map),
          friendshipId: map['friendship_id'] as String,
        ),
      );
    }
    return FriendsPage(items: items, totalCount: totalCount);
  }

  Future<void> unfriend(String friendshipId) async {
    await _supabase
        .from(SupabaseConstants.friendships)
        .delete()
        .eq(FriendshipColumns.id, friendshipId);
  }

  Future<List<FriendListItemModel>> searchFriends({
    required String userId,
    required String query,
    int limit = 30,
    int offset = 0,
  }) async {
    final rows = await _supabase.rpc(
      'search_friends',
      params: {
        'p_query': query,
        'p_user_id': userId,
        'p_limit': limit,
        'p_offset': offset,
      },
    );
    return (rows as List).map((row) {
      final map = row as Map<String, dynamic>;
      return FriendListItemModel(
        user: UserData.fromMap(map),
        friendshipId: map['friendship_id'] as String,
      );
    }).toList();
  }

  Future<String> sendFriendRequest(String addresseeId) async {
    final row =
        await _supabase
            .from(SupabaseConstants.friendships)
            .insert({
              FriendshipColumns.requesterId: SupabaseProvider.id,
              FriendshipColumns.addresseeId: addresseeId,
            })
            .select(FriendshipColumns.id)
            .single();
    return row[FriendshipColumns.id] as String;
  }

  Future<void> cancelFriendRequest(String friendshipId) async {
    await _supabase
        .from(SupabaseConstants.friendships)
        .delete()
        .eq(FriendshipColumns.id, friendshipId);
  }

  Future<bool> acceptFriendRequest(String friendshipId) async {
    final updatedRows = await _supabase
        .from(SupabaseConstants.friendships)
        .update({
          FriendshipColumns.status: 'accepted',
          FriendshipColumns.respondedAt:
              DateTime.now().toUtc().toIso8601String(),
        })
        .eq(FriendshipColumns.id, friendshipId)
        .eq(FriendshipColumns.status, 'pending')
        .eq(FriendshipColumns.addresseeId, SupabaseProvider.id)
        .select(FriendshipColumns.id);
    return (updatedRows as List).isNotEmpty;
  }

  Future<void> rejectFriendRequest(String friendshipId) async {
    await _supabase
        .from(SupabaseConstants.friendships)
        .delete()
        .eq(FriendshipColumns.id, friendshipId);
  }
}
