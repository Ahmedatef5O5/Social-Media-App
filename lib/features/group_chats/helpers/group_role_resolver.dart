import '../../../core/supabase/supabase_provider.dart';

/// Cached "am I owner/admin of this group?" lookup, used by post menus to
/// offer moderation (delete any group post) without loading a roster.
/// The server (RLS) remains the source of truth.
class GroupRoleResolver {
  GroupRoleResolver._();

  static final Map<String, Future<bool>> _cache = {};

  static Future<bool> isAdmin(String groupId) {
    final uid = SupabaseProvider.idOrNull;
    if (uid == null) return Future.value(false);
    return _cache.putIfAbsent(groupId, () async {
      try {
        final res = await SupabaseProvider.client.rpc(
          'is_group_admin',
          params: {'p_group_id': groupId, 'p_user_id': uid},
        );
        return res == true;
      } catch (_) {
        return false;
      }
    });
  }

  /// Call after promote / demote / leave so the next lookup is fresh.
  static void invalidate([String? groupId]) {
    if (groupId == null) {
      _cache.clear();
    } else {
      _cache.remove(groupId);
    }
  }
}
