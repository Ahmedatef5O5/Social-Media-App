import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PresenceService with WidgetsBindingObserver {
  PresenceService._();
  static final PresenceService instance = PresenceService._();

  final _supabase = Supabase.instance.client;

  bool _initialised = false;
  String? _userId;

  Timer? _heartbeatTimer;
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  Future<void> init() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    if (_initialised && _userId == user.id) return;

    _userId = user.id;
    _initialised = true;

    WidgetsBinding.instance.addObserver(this);

    await _setOnline(true);
    _startHeartbeat();

    _supabase.auth.onAuthStateChange.listen((data) async {
      if (data.event == AuthChangeEvent.signedOut) {
        await _setOnline(false);
        await dispose();
      } else if (data.event == AuthChangeEvent.signedIn) {
        _userId = _supabase.auth.currentUser?.id;
        _initialised = false;
        await init();
      }
    });
  }

  Future<void> dispose() async {
    if (!_initialised) return;
    _stopHeartbeat();
    WidgetsBinding.instance.removeObserver(this);
    _initialised = false;
    _userId = null;
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      _setOnline(true);
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
      await _supabase.from('user_presence').upsert({
        'user_id': uid,
        'is_online': isOnline,
        'last_seen': now,
        'updated_at': now,
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
