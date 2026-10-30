import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:social_media_app/core/guards/system_gate_decision.dart';
import 'package:social_media_app/core/observability/build_info.dart';
import 'package:social_media_app/core/services/app_system_status.dart';
import 'package:social_media_app/core/supabase/supabase_provider.dart';

/// Calls `get_app_system_status`. Injectable so tests never touch Supabase.
typedef SystemStatusFetcher = Future<Object?> Function(String? appVersion);

/// Remote App Control (Feature B).
///
/// Fetches `public.get_app_system_status(p_app_version)` and exposes the result
/// as [status]. It refreshes:
///   * once during bootstrap ([init], fire-and-forget),
///   * whenever the app returns to the foreground ([AppLifecycleState.resumed]),
///   * after every sign-in / sign-out ([onAuthChanged]) because bypass and
///     suspension are per-user,
///   * at the next maintenance / suspension boundary the server reported, and
///   * every [pollInterval] while the app is in the foreground.
///
/// FAIL-OPEN: a network error, timeout, or malformed payload keeps the last
/// known status (initially [AppSystemStatus.open]). An offline cold start is
/// therefore never blocked. Suspension is enforced by the database (RLS), so
/// the client screen is only a courtesy and can safely be missing offline.
class SystemControlService with WidgetsBindingObserver {
  SystemControlService({
    SystemStatusFetcher? fetcher,
    DateTime Function()? now,
    String? Function()? appVersion,
    bool Function()? isAuthenticated,
    this.minInterval = const Duration(seconds: 15),
    this.timeout = const Duration(seconds: 15),
    this.pollInterval = const Duration(minutes: 5),
  }) : _fetcher = fetcher ?? _rpcFetcher,
       _now = now ?? DateTime.now,
       _appVersion = appVersion ?? currentAppVersion,
       _isAuthenticated = isAuthenticated ?? _supabaseAuthenticated;

  static final SystemControlService instance = SystemControlService();

  /// Non-forced refreshes closer together than this are skipped.
  final Duration minInterval;

  /// Hard cap for one RPC, so a hung socket cannot pin the in-flight slot.
  final Duration timeout;

  final Duration pollInterval;

  final SystemStatusFetcher _fetcher;
  final DateTime Function() _now;
  final String? Function() _appVersion;
  final bool Function() _isAuthenticated;

  final ValueNotifier<AppSystemStatus> status = ValueNotifier(
    AppSystemStatus.open,
  );

  /// Bumped on every sign-in/out so the gate re-evaluates even when the status
  /// payload itself did not change.
  final ValueNotifier<int> authEpoch = ValueNotifier(0);

  /// Staff who are signed out during maintenance may open the login screen to
  /// authenticate (bypass is per-user, so it cannot be known before sign-in).
  final ValueNotifier<bool> staffSignInMode = ValueNotifier(false);

  Future<void>? _inFlight;
  bool _rerunForced = false;
  DateTime? _lastAttempt;
  Timer? _pollTimer;
  Timer? _boundaryTimer;
  bool _initialised = false;
  _BackBlocker? _backBlocker;

  bool get isAuthenticated => _isAuthenticated();

  /// What the gate currently shows (none = app usable).
  GateScreen get currentGate => decideGate(
    status.value,
    authenticated: _isAuthenticated(),
    staffSignInMode: staffSignInMode.value,
  );

  /// Idempotent. Never awaits the network: bootstrap must not wait on it.
  void init() {
    if (_initialised) return;
    _initialised = true;
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
    unawaited(refresh(force: true));
  }

  void dispose() {
    if (_initialised) {
      WidgetsBinding.instance.removeObserver(this);
      _initialised = false;
    }
    _pollTimer?.cancel();
    _boundaryTimer?.cancel();
    final blocker = _backBlocker;
    if (blocker != null) {
      WidgetsBinding.instance.removeObserver(blocker);
      _backBlocker = null;
    }
  }

  /// Call BEFORE `runApp`. The observer must be registered ahead of
  /// `WidgetsApp`'s own, because the first observer to return true from
  /// `didPopRoute` wins; otherwise Android's back button would silently pop
  /// routes hidden behind a blocking screen.
  void attachBackBlocker() {
    if (_backBlocker != null) return;
    final blocker = _BackBlocker(() => currentGate != GateScreen.none);
    _backBlocker = blocker;
    WidgetsBinding.instance.addObserver(blocker);
  }

  /// Sign-in, sign-out or MFA completion: bypass and suspension are per-user.
  void onAuthChanged() {
    staffSignInMode.value = false;
    authEpoch.value++;
    unawaited(refresh(force: true));
  }

  void enterStaffSignInMode() {
    staffSignInMode.value = true;
  }

  /// Refreshes the status. Never throws. Single-flight: concurrent callers
  /// share one request; a forced call made while one is running schedules
  /// exactly one more run afterwards (e.g. the user changed mid-request).
  Future<void> refresh({bool force = false}) {
    final running = _inFlight;
    if (running != null) {
      if (force) _rerunForced = true;
      return running;
    }

    final last = _lastAttempt;
    if (!force && last != null && _now().difference(last) < minInterval) {
      return Future<void>.value();
    }

    final future = _fetchOnce().whenComplete(() {
      _inFlight = null;
      if (_rerunForced) {
        _rerunForced = false;
        unawaited(refresh(force: true));
      }
    });
    _inFlight = future;
    return future;
  }

  Future<void> _fetchOnce() async {
    _lastAttempt = _now();
    try {
      final raw = await _fetcher(_appVersion()).timeout(timeout);
      final parsed = AppSystemStatus.tryParse(raw);
      if (parsed == null) {
        debugPrint('[SystemControl] ignored malformed status payload');
        return;
      }
      status.value = parsed; // == ignores serverTime: no needless rebuilds
      _scheduleBoundaryRefresh(parsed);
    } catch (e) {
      // Offline, timeout, RPC missing, RLS... keep the last known state.
      debugPrint('[SystemControl] status fetch failed (keeping last): $e');
    }
  }

  /// Wakes up exactly when maintenance starts/ends or a suspension expires, so
  /// a scheduled window takes effect without waiting for the next poll.
  void _scheduleBoundaryRefresh(AppSystemStatus s) {
    _boundaryTimer?.cancel();
    final reference = s.serverTime ?? _now();

    final candidates =
        <DateTime>[
            if (s.maintenanceEnabled && s.maintenanceStartsAt != null)
              s.maintenanceStartsAt!,
            if (s.maintenanceEnabled && s.maintenanceEndsAt != null)
              s.maintenanceEndsAt!,
            if (s.isCallerSuspended && s.suspensionExpiresAt != null)
              s.suspensionExpiresAt!,
          ].where((t) => t.isAfter(reference)).toList()
          ..sort();

    if (candidates.isEmpty) return;

    var delay =
        candidates.first.difference(reference) + const Duration(seconds: 1);
    // Timers can't be trusted for days; re-check at least daily.
    const maxDelay = Duration(hours: 24);
    if (delay > maxDelay) delay = maxDelay;
    _boundaryTimer = Timer(delay, () => unawaited(refresh(force: true)));
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(pollInterval, (_) => unawaited(refresh()));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _startPolling();
        unawaited(refresh());
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _pollTimer?.cancel();
        break;
      default:
        break;
    }
  }

  /// `1.2.3+45` for the RPC, or null when the build metadata is not a valid
  /// version (local `0.0.0-dev` builds): the server then returns
  /// `update_required: false`, i.e. dev builds are never gated.
  @visibleForTesting
  static String? composeAppVersion(String version, String build) {
    final v = version.trim();
    final b = build.trim();
    if (!RegExp(r'^[0-9]+(\.[0-9]+){0,2}$').hasMatch(v)) return null;
    if (!RegExp(r'^[0-9]+$').hasMatch(b) || b == '0') return v;
    return '$v+$b';
  }

  static String? currentAppVersion() =>
      composeAppVersion(BuildInfo.appVersion, BuildInfo.buildNumber);

  static bool _supabaseAuthenticated() {
    try {
      return SupabaseProvider.isAuthenticated;
    } catch (_) {
      return false;
    }
  }

  static Future<Object?> _rpcFetcher(String? appVersion) {
    return SupabaseProvider.client.rpc(
      'get_app_system_status',
      params: {'p_app_version': appVersion},
    );
  }
}

class _BackBlocker with WidgetsBindingObserver {
  _BackBlocker(this._isBlocking);
  final bool Function() _isBlocking;

  @override
  Future<bool> didPopRoute() async => _isBlocking();
}
