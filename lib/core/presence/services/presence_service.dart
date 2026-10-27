import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:social_media_app/core/supabase/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../features/settings/repository/settings_repository.dart';
import '../../utilities/supabase_constants.dart';
import '../../services/network_status_service.dart';

class PresenceService with WidgetsBindingObserver {
  static final PresenceService instance = PresenceService._();

  PresenceService._();

  bool _initialised = false;
  String? _userId;
  bool _writing = false;
  bool? _pendingOnlineTarget;

  Timer? _heartbeatTimer;
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  static const int _lastSeenEveryNHeartbeats = 10;
  int _heartbeatCount = 0;

  StreamSubscription<AuthState>? _authSub;

  Future<void> init() async {
    final user = SupabaseProvider.user;
    if (user == null) return;
    if (_initialised && _userId == user.id) return;

    _userId = user.id;
    _initialised = true;

    WidgetsBinding.instance.addObserver(this);

    await _syncPresence(true);
    _startHeartbeat();

    await _authSub?.cancel();

    _authSub = SupabaseProvider.authChanges.listen((data) async {
      switch (data.event) {
        case AuthChangeEvent.signedOut:
          await _syncPresence(false);
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
    _heartbeatTimer = Timer.periodic(
      _heartbeatInterval,
      (_) => _heartbeatTick(),
    );
  }

  Future<void> _heartbeatTick() async {
    if (_writing) return;

    final isConnected = await NetworkStatusService.instance.isConnected();
    if (!isConnected) return;

    await _syncPresence(true, heartbeat: true);
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _syncPresence(true);
        _startHeartbeat();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _stopHeartbeat();
        _syncPresence(false);
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }

  Future<void> setVisibility(bool visible) async {
    if (visible) {
      await _syncPresence(true);
      _startHeartbeat();
    } else {
      _stopHeartbeat();
      await _syncPresence(false);
    }
  }

  Future<void> _syncPresence(bool isOnline, {bool heartbeat = false}) async {
    if (_writing) {
      if (!heartbeat) {
        _pendingOnlineTarget = isOnline;
      }
      return;
    }

    _writing = true;
    try {
      await _setOnline(isOnline, heartbeat: heartbeat);
      while (_pendingOnlineTarget != null) {
        final nextTarget = _pendingOnlineTarget!;
        _pendingOnlineTarget = null;
        await _setOnline(nextTarget);
      }
    } finally {
      _writing = false;
    }
  }

  bool _isTransientSocketReset(Object error) {
    if (error is SocketException) return true;
    final msg = error.toString();
    return msg.contains('Connection reset by peer') ||
        msg.contains('Connection closed before full header was received') ||
        msg.contains('Software caused connection abort');
  }

  Future<void> _setOnline(bool isOnline, {bool heartbeat = false}) async {
    final user = SupabaseProvider.user;
    if (user == null) return;

    final isConnected = await NetworkStatusService.instance.isConnected();
    if (!isConnected) return;

    final uid = _userId ?? SupabaseProvider.id;

    final bool effectiveOnline =
        isOnline && SettingsRepository.instance.onlineStatus;

    if (heartbeat && !effectiveOnline) return;

    _heartbeatCount = heartbeat ? _heartbeatCount + 1 : 0;
    final bool touchLastSeen =
        !heartbeat || _heartbeatCount % _lastSeenEveryNHeartbeats == 0;

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final now = DateTime.now().toUtc().toIso8601String();
        await SupabaseProvider.client
            .from(SupabaseConstants.userPresence)
            .upsert(
              {
                PresenceColumns.userId: uid,
                PresenceColumns.isOnline: effectiveOnline,
                if (touchLastSeen) PresenceColumns.lastSeen: now,
                PresenceColumns.updatedAt: now,
              },
              onConflict: PresenceColumns.userId,
              defaultToNull: false,
            );
        return;
      } catch (e) {
        if (attempt == 0 && _isTransientSocketReset(e)) {
          await Future<void>.delayed(const Duration(milliseconds: 250));
          continue;
        }
        debugPrint('[PresenceService] _setOnline($isOnline) error: $e');
        return;
      }
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

  Future<void> forceSyncNow() async {
    if (!_initialised) return;
    await _syncPresence(true);
    debugPrint('[PresenceService] Force-synced after connectivity restored ✅');
    _startHeartbeat();
  }
}
