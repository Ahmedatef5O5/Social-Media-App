import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_media_app/core/supabase/supabase_provider.dart';
import 'package:social_media_app/features/settings/repository/settings_repository.dart';

/// Mirrors the three notification toggles (Push / Message Previews / Call
/// Notifications) to `public.users` so the Send-Notification edge function can
/// enforce them server-side.

class NotificationPrefsSyncService {
  NotificationPrefsSyncService._();
  static final NotificationPrefsSyncService instance =
      NotificationPrefsSyncService._();

  static const String _kDirty = 'settings_notification_prefs_dirty';
  static const String _kSyncedOnce = 'settings_notification_prefs_synced_once';

  bool _inFlight = false;
  bool _rerunRequested = false;

  /// Called right after a toggle changes.
  Future<void> markDirtyAndSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kDirty, true);
    } catch (e) {
      debugPrint('[PrefsSync] could not persist dirty flag: $e');
    }
    await _sync();
  }

  /// Called on launch: syncs if a previous attempt failed, or once per install
  /// so existing users get their current values on the server after updating.
  Future<void> syncIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dirty = prefs.getBool(_kDirty) ?? false;
      final syncedOnce = prefs.getBool(_kSyncedOnce) ?? false;
      if (!dirty && syncedOnce) return;
    } catch (_) {
      // If we cannot read the flags, syncing is still the safe choice.
    }
    await _sync();
  }

  Future<void> _sync() async {
    if (_inFlight) {
      // A toggle changed while a request was running: send the latest values
      // once the current request finishes.
      _rerunRequested = true;
      return;
    }
    if (!SupabaseProvider.isAuthenticated) return;

    _inFlight = true;
    try {
      do {
        _rerunRequested = false;

        final repo = SettingsRepository.instance;
        await repo.init();

        await SupabaseProvider.client.rpc(
          'update_my_notification_prefs',
          params: {
            'p_push': repo.pushNotifications,
            'p_previews': repo.messagePreviews,
            'p_calls': repo.callNotifications,
          },
        );

        final prefs = await SharedPreferences.getInstance();
        // Only clear "dirty" if nothing changed during the request.
        if (!_rerunRequested) {
          await prefs.setBool(_kDirty, false);
        }
        await prefs.setBool(_kSyncedOnce, true);
      } while (_rerunRequested);
    } catch (e) {
      // Stay dirty; retried on next launch.
      debugPrint('[PrefsSync] sync failed (will retry later): $e');
    } finally {
      _inFlight = false;
    }
  }
}
