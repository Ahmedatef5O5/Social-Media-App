import 'package:flutter/foundation.dart';
import '../../features/profile/services/user_services.dart';
import '../supabase/supabase_provider.dart';

/// Resolves the signed-in user's real display name for a call.
///
/// Group-call screens used to start with the placeholder `'Loading...'`
/// (fetched asynchronously) and one entry point hard-coded `'Me'`. If the
/// call connected first, that placeholder was sent to LiveKit as the
/// participant name and shown to everyone in the call.
///
/// Never returns `'Loading...'` or `'Me'`.
class CurrentUserNameResolver {
  const CurrentUserNameResolver._();

  static const Duration _lookupTimeout = Duration(seconds: 4);

  static Future<String> resolve({UserService? userService}) async {
    final user = SupabaseProvider.user;
    if (user == null) return 'Unknown';

    try {
      final fetched = await (userService ?? UserService())
          .fetchUserName(user.id)
          .timeout(_lookupTimeout);
      if (fetched != null && fetched.trim().isNotEmpty) return fetched.trim();
    } catch (e) {
      debugPrint('[CurrentUserNameResolver] users lookup failed: $e');
    }

    final meta = user.userMetadata;
    for (final key in const ['name', 'full_name', 'display_name']) {
      final value = meta?[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }

    final email = user.email;
    if (email != null && email.contains('@')) {
      final local = email.split('@').first.trim();
      if (local.isNotEmpty) return local;
    }
    return 'User';
  }
}
