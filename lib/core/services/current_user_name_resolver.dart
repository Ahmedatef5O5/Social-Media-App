import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../features/profile/services/user_services.dart';
import '../cache/constants/snapshot_keys.dart';
import '../cache/services/local_snapshot_store.dart';
import '../supabase/supabase_provider.dart';
import 'call_identity.dart';

/// Resolves the signed-in user's real display name for a call.
///
/// Uses a 3-tier cache-first lookup (memory -> LocalSnapshotStore -> bounded
/// network lookup -> auth metadata) so answering a call never stalls on slow
/// or waking mobile networks.
///
/// Never returns `'Loading...'` or `'Me'`.
class CurrentUserNameResolver {
  const CurrentUserNameResolver._();

  static const Duration _lookupTimeout = Duration(milliseconds: 1500);

  static String? _cachedUserId;
  static String? _cachedName;

  static void clearCache() {
    _cachedUserId = null;
    _cachedName = null;
  }

  static Future<String> resolve({UserService? userService}) async {
    final user = SupabaseProvider.user;
    if (user == null) return 'Unknown';

    if (userService == null) {
      if (_cachedUserId == user.id &&
          !CallIdentity.isPlaceholderName(_cachedName)) {
        return _cachedName!;
      }

      final snapshotName = _readSnapshotName(user.id);
      if (snapshotName != null) {
        _cachedUserId = user.id;
        _cachedName = snapshotName;
        unawaited(_refreshInBackground(user.id));
        return snapshotName;
      }
    }

    try {
      final fetched = await (userService ?? UserService())
          .fetchUserName(user.id)
          .timeout(_lookupTimeout);
      final clean = fetched?.trim();
      if (clean != null && !CallIdentity.isPlaceholderName(clean)) {
        _cachedUserId = user.id;
        _cachedName = clean;
        return clean;
      }
    } catch (e) {
      debugPrint('[CurrentUserNameResolver] users lookup failed: $e');
    }

    final meta = user.userMetadata;
    for (final key in const ['name', 'full_name', 'display_name']) {
      final value = meta?[key];
      if (value is String && !CallIdentity.isPlaceholderName(value)) {
        final clean = value.trim();
        _cachedUserId = user.id;
        _cachedName = clean;
        return clean;
      }
    }

    final email = user.email;
    if (email != null && email.contains('@')) {
      final local = email.split('@').first.trim();
      if (!CallIdentity.isPlaceholderName(local)) return local;
    }
    return 'User';
  }

  static String? _readSnapshotName(String userId) {
    try {
      final map = LocalSnapshotStore.instance.readObject(
        SnapshotKeys.currentUser,
      );
      if (map == null || map['id'] != userId) return null;
      final name = (map['name'] as String?)?.trim();
      if (name != null && !CallIdentity.isPlaceholderName(name)) {
        return name;
      }
    } catch (_) {}
    return null;
  }

  static Future<void> _refreshInBackground(String userId) async {
    try {
      final fetched = await UserService()
          .fetchUserName(userId)
          .timeout(const Duration(seconds: 4));
      final clean = fetched?.trim();
      if (clean != null &&
          !CallIdentity.isPlaceholderName(clean) &&
          SupabaseProvider.idOrNull == userId) {
        _cachedUserId = userId;
        _cachedName = clean;
      }
    } catch (_) {}
  }
}
