import '../../../core/supabase/supabase_provider.dart';
import '../../../core/utilities/supabase_constants.dart';

class ConnectionsService {
  final _supabase = SupabaseProvider.client;

  Future<List<Map<String, dynamic>>> getMyConnections() async {
    final currentId = SupabaseProvider.id;

    final friendRows = await _supabase
        .from(SupabaseConstants.friendships)
        .select(
          'requester_id, addressee_id, '
          'requester:requester_id(id,name,image_url), '
          'addressee:addressee_id(id,name,image_url)',
        )
        .eq(FriendshipColumns.status, 'accepted')
        .or('requester_id.eq.$currentId,addressee_id.eq.$currentId');

    final followingRows = await _supabase
        .from(SupabaseConstants.follows)
        .select('following:following_id(id,name,image_url)')
        .eq(FollowColumns.followerId, currentId);

    final followerRows = await _supabase
        .from(SupabaseConstants.follows)
        .select('follower:follower_id(id,name,image_url)')
        .eq(FollowColumns.followingId, currentId);

    final Map<String, Map<String, dynamic>> merged = {};
    for (final row in (friendRows as List)) {
      final isRequester = row[FriendshipColumns.requesterId] == currentId;
      final user =
          (isRequester ? row['addressee'] : row['requester'])
              as Map<String, dynamic>;
      merged[user['id'] as String] = user;
    }
    for (final row in (followingRows as List)) {
      final user = row['following'] as Map<String, dynamic>;
      merged[user['id'] as String] = user;
    }
    for (final row in (followerRows as List)) {
      final user = row['follower'] as Map<String, dynamic>;
      merged[user['id'] as String] = user;
    }
    return merged.values.toList();
  }

  Future<Set<String>> getMyConnectionIds() async {
    final list = await getMyConnections();
    return list.map((u) => u['id'] as String).toSet();
  }
}
