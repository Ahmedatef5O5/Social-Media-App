import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:social_media_app/core/supabase/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/settings/repository/settings_repository.dart';
import '../utilities/supabase_constants.dart';

class PresenceService with WidgetsBindingObserver {
  PresenceService._();
  static final PresenceService instance = PresenceService._();

  bool _initialised = false;
  String? _userId;

  Timer? _heartbeatTimer;
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  StreamSubscription<AuthState>? _authSub;

  Future<void> init() async {
    final user = SupabaseProvider.user;
    if (user == null) return;
    if (_initialised && _userId == user.id) return;

    _userId = user.id;
    _initialised = true;

    WidgetsBinding.instance.addObserver(this);

    await _setOnline(true);
    _startHeartbeat();

    await _authSub?.cancel();

    _authSub = SupabaseProvider.authChanges.listen((data) async {
      switch (data.event) {
        case AuthChangeEvent.signedOut:
          await _setOnline(false);
          await dispose();

        case AuthChangeEvent.signedIn:
          final newUserId = data.session?.user.id;
          if (newUserId != null && newUserId != _userId) {
            _initialised = false;
            _userId = null;
            await init();
          }

        case AuthChangeEvent.tokenRefreshed:
          break;

        default:
          break;
      }
    });
  }

  Future<void> dispose() async {
    if (!_initialised) return;
    _stopHeartbeat();
    WidgetsBinding.instance.removeObserver(this);
    await _authSub?.cancel();
    _authSub = null;

    _initialised = false;
    _userId = null;
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      _setOnline(
        true,
      ).catchError((e) => debugPrint('[PresenceService] heartbeat error: $e'));
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _setOnline(true);
        _startHeartbeat();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _stopHeartbeat();
        _setOnline(false);
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }

  Future<void> setVisibility(bool visible) async {
    if (visible) {
      await _setOnline(true);
      _startHeartbeat();
    } else {
      _stopHeartbeat();
      await _setOnline(false);
    }
  }

  Future<void> _setOnline(bool isOnline) async {
    final user = SupabaseProvider.user;
    if (user == null) return;

    final uid = _userId ?? SupabaseProvider.id;

    final bool effectiveOnline =
        isOnline && SettingsRepository.instance.onlineStatus;

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await SupabaseProvider.client
          .from(SupabaseConstants.userPresence)
          .upsert({
            PresenceColumns.userId: uid,
            PresenceColumns.isOnline: effectiveOnline,
            PresenceColumns.lastSeen: now,
            PresenceColumns.updatedAt: now,
          }, onConflict: PresenceColumns.userId);
    } catch (e) {
      debugPrint('[PresenceService] _setOnline($isOnline) error: $e');
    }
  }

  static bool isConsideredOnline({
    required bool isOnline,
    required DateTime? updatedAt,
  }) {
    if (!isOnline) return false;
    if (updatedAt == null) return false;
    final diff = DateTime.now().toUtc().difference(updatedAt.toUtc());
    return diff.inSeconds <= 90;
  }
}
