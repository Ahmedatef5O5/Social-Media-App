import 'package:social_media_app/core/supabase/supabase_provider.dart';
import 'package:social_media_app/core/utilities/supabase_constants.dart';
import '../../auth/data/models/user_data.dart';
import '../models/friend_list_item_model.dart';

class FriendshipServices {
  final _supabase = SupabaseProvider.client;

  Future<List<FriendListItemModel>> getFriends(
    String userId, {
    int limit = 30,
    int offset = 0,
  }) async {
    final rows = await _supabase
        .from(SupabaseConstants.friendships)
        .select(
          'id, requester_id, addressee_id, '
          'requester:requester_id(*), addressee:addressee_id(*)',
        )
        .eq(FriendshipColumns.status, 'accepted')
        .or('requester_id.eq.$userId,addressee_id.eq.$userId')
        .range(offset, offset + limit - 1);
    return (rows as List).map((row) {
      final isRequester = row[FriendshipColumns.requesterId] == userId;
      final otherUserMap =
          (isRequester ? row['addressee'] : row['requester'])
              as Map<String, dynamic>;
      return FriendListItemModel(
        user: UserData.fromMap(otherUserMap),
        friendshipId: row[FriendshipColumns.id] as String,
      );
    }).toList();
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

  Future<void> acceptFriendRequest(String friendshipId) async {
    await _supabase
        .from(SupabaseConstants.friendships)
        .update({
          FriendshipColumns.status: 'accepted',
          FriendshipColumns.respondedAt: DateTime.now().toIso8601String(),
        })
        .eq(FriendshipColumns.id, friendshipId);
  }

  Future<void> rejectFriendRequest(String friendshipId) async {
    await _supabase
        .from(SupabaseConstants.friendships)
        .delete()
        .eq(FriendshipColumns.id, friendshipId);
  }
}
