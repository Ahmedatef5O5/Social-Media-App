import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utilities/supabase_constants.dart';

class PresenceService with WidgetsBindingObserver {
  PresenceService._();
  static final PresenceService instance = PresenceService._();

  final _supabase = Supabase.instance.client;

  bool _initialised = false;
  String? _userId;

  Timer? _heartbeatTimer;
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  StreamSubscription<AuthState>? _authSub;

  Future<void> init() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    if (_initialised && _userId == user.id) return;

    _userId = user.id;
    _initialised = true;

    WidgetsBinding.instance.addObserver(this);

    await _setOnline(true);
    _startHeartbeat();

    await _authSub?.cancel();

    _authSub = _supabase.auth.onAuthStateChange.listen((data) async {
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

  Future<void> _setOnline(bool isOnline) async {
    final uid = _userId ?? _supabase.auth.currentUser?.id;
    if (uid == null) return;

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _supabase.from(SupabaseConstants.userPresence).upsert({
        'user_id': uid,
        PresenceColumns.isOnline: isOnline,
        'last_seen': now,
        PresenceColumns.updatedAt: now,
      }, onConflict: 'user_id');
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
