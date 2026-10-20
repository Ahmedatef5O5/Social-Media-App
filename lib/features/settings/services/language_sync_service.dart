import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_media_app/core/supabase/supabase_provider.dart';
import 'package:social_media_app/core/utilities/supabase_constants.dart';

import '../../../core/localization/app_locale.dart';
import '../repository/settings_repository.dart';

/// Mirrors the device UI language to `public.users.language_code` so the
/// `send-notification` edge function can localize pushes for the receiver.
///
/// The language is a DEVICE preference but the column is per ACCOUNT, so the
/// "already synced" marker is tracked per user id. Consequences:
///  * changing the language while offline simply stays unsynced and is retried
///    on the next launch ([syncIfNeeded]);
///  * logging into a second account on the same device pushes the device
///    language to that account too, instead of leaving its column stale.
class LanguageSyncService {
  LanguageSyncService._();
  static final LanguageSyncService instance = LanguageSyncService._();

  static String _syncedKey(String userId) => 'settings_language_synced_$userId';

  bool _inFlight = false;
  bool _rerunRequested = false;

  /// Called right after the user picks a language.
  Future<void> syncNow() => _sync();

  /// Called on launch / after sign-in (same hook as the notification-prefs sync).
  Future<void> syncIfNeeded() => _sync();

  Future<void> _sync() async {
    if (_inFlight) {
      _rerunRequested = true;
      return;
    }
    if (!SupabaseProvider.isAuthenticated) return;

    _inFlight = true;
    try {
      do {
        _rerunRequested = false;

        final userId = SupabaseProvider.user?.id;
        if (userId == null) return;

        final repo = SettingsRepository.instance;
        await repo.init();
        final code = AppLocale.normalize(repo.languageCode);

        final prefs = await SharedPreferences.getInstance();
        if (prefs.getString(_syncedKey(userId)) == code) continue;

        await SupabaseProvider.client
            .from(SupabaseConstants.users)
            .update({'language_code': code})
            .eq('id', userId);

        await prefs.setString(_syncedKey(userId), code);
      } while (_rerunRequested);
    } catch (e) {
      // Left unsynced; retried on next launch.
      debugPrint('[LanguageSync] sync failed (will retry later): $e');
    } finally {
      _inFlight = false;
    }
  }
}
