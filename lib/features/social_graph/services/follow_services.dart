import 'package:social_media_app/core/supabase/supabase_provider.dart';
import 'package:social_media_app/core/utilities/supabase_constants.dart';

class FollowServices {
  final _supabase = SupabaseProvider.client;

  Future<void> followUser(String followingId) async {
    await _supabase.from(SupabaseConstants.follows).insert({
      FollowColumns.followerId: SupabaseProvider.id,
      FollowColumns.followingId: followingId,
    });
  }

  Future<void> unfollowUser(String followingId) async {
    await _supabase.from(SupabaseConstants.follows).delete().match({
      FollowColumns.followerId: SupabaseProvider.id,
      FollowColumns.followingId: followingId,
    });
  }

  Future<Set<String>> getFollowingSubset(List<String> candidateIds) async {
    if (candidateIds.isEmpty) return {};
    final rows = await _supabase
        .from(SupabaseConstants.follows)
        .select(FollowColumns.followingId)
        .eq(FollowColumns.followerId, SupabaseProvider.id)
        .inFilter(FollowColumns.followingId, candidateIds);
    return (rows as List)
        .map((r) => r[FollowColumns.followingId] as String)
        .toSet();
  }
}
