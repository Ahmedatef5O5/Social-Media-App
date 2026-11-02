import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart' as sb;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../observability/build_info.dart';
import '../../observability/observability.dart';
import '../../services/incoming_call_navigation_guard.dart';
import '../cubit/update_state.dart';
import '../models/update_event_payload.dart';
import '../models/update_info.dart';
import '../models/update_track.dart';
import 'installation_identity_manager.dart';
import 'update_telemetry_reporter.dart';

/// Wraps [sb.ShorebirdUpdater] with fail-safe guards.
///
/// Hard rules this class keeps:
///  * It NEVER throws to a caller and never blocks `main()` / `runApp()`:
///    [initialize] is meant to be `unawaited(...)`ed after the first frame.
///  * It never checks/downloads while the user is in a call or an upload runs
///    (see [extraBusyChecks]).
///  * It never restarts the app. A downloaded patch applies on the next launch.
///  * Debug builds (`isAvailable == false`) are a complete no-op.
class ShorebirdUpdateService {
  ShorebirdUpdateService({
    sb.ShorebirdUpdater? updater,
    UpdateTelemetryReporter? telemetry,
    InstallationIdentityManager? identity,
    Future<UpdatePolicy> Function()? policyLoader,
    bool Function()? isUserBusy,
    List<bool Function()> extraBusyChecks = const [],
    DateTime Function()? clock,
    Future<SharedPreferences> Function()? prefsLoader,
    AppUpdateTrack? track,
    String? releaseVersion,
    Future<void> Function()? waitForFirstFrame,
    this.confirmDelay = const Duration(seconds: 15),
    this.checkTimeout = const Duration(seconds: 30),
    this.downloadTimeout = const Duration(minutes: 5),
  }) : _updater = updater,
       telemetry = telemetry ?? UpdateTelemetryReporter(),
       _identity = identity ?? InstallationIdentityManager(),
       _policyLoader = policyLoader ?? _loadPolicyFromServer,
       _isUserBusy = isUserBusy ?? _defaultIsUserBusy,
       _extraBusyChecks = extraBusyChecks,
       _clock = clock ?? DateTime.now,
       _prefsLoader = prefsLoader ?? SharedPreferences.getInstance,
       _configuredTrack = track ?? AppUpdateTrack.parse(BuildInfo.shorebirdTrack),
       _releaseVersion = releaseVersion ?? BuildInfo.releaseVersion,
       _waitForFirstFrame =
           waitForFirstFrame ?? (() => WidgetsBinding.instance.endOfFrame);

  /// App-wide instance (created lazily; tests construct their own).
  static final ShorebirdUpdateService instance = ShorebirdUpdateService();

  static const String lastCheckPrefsKey = 'update_last_check_ms_v1';
  static const String lastReportedPatchPrefsKey = 'update_last_reported_patch_v1';

  sb.ShorebirdUpdater? _updater;
  final UpdateTelemetryReporter telemetry;
  final InstallationIdentityManager _identity;
  final Future<UpdatePolicy> Function() _policyLoader;
  final bool Function() _isUserBusy;
  final List<bool Function()> _extraBusyChecks;
  final DateTime Function() _clock;
  final Future<SharedPreferences> Function() _prefsLoader;
  final AppUpdateTrack _configuredTrack;
  final String _releaseVersion;
  final Future<void> Function() _waitForFirstFrame;
  final Duration confirmDelay;
  final Duration checkTimeout;
  final Duration downloadTimeout;

  final StreamController<UpdateState> _controller =
      StreamController<UpdateState>.broadcast();
  UpdatePolicy _policy = UpdatePolicy.defaults;
  UpdateInfo _info = const UpdateInfo(
    updaterAvailable: false,
    track: AppUpdateTrack.stable,
  );
  UpdateState _state = const UpdateInitial(
    UpdateInfo(updaterAvailable: false, track: AppUpdateTrack.stable),
  );
  bool _checking = false;
  bool _initialized = false;
  Timer? _confirmTimer;

  Stream<UpdateState> get states => _controller.stream;
  UpdateState get state => _state;
  UpdateInfo get info => _info;
  UpdatePolicy get policy => _policy;

  /// `ShorebirdUpdater()` touches native code; create it lazily and tolerate
  /// platforms/builds where it cannot be constructed.
  sb.ShorebirdUpdater? get _safeUpdater {
    try {
      return _updater ??= sb.ShorebirdUpdater();
    } catch (_) {
      return null;
    }
  }

  static bool _defaultIsUserBusy() {
    try {
      return IncomingCallNavigationGuard.isUserBusyWithAnotherCall();
    } catch (_) {
      return false; // fail open: a guard bug must not disable updates
    }
  }

  static Future<UpdatePolicy> _loadPolicyFromServer() async {
    try {
      final raw = await Supabase.instance.client
          .rpc('get_update_policy')
          .timeout(const Duration(seconds: 8));
      return UpdatePolicy.fromJson(raw);
    } catch (_) {
      return UpdatePolicy.defaults;
    }
  }

  /// Reads the Crashlytics context for the running binary. Cheap, bounded to
  /// 2 s and never throws, so `_initObservability()` can call it before the
  /// first frame.
  static Future<Map<String, Object>> readObservabilityContext({
    sb.ShorebirdUpdater? updater,
  }) async {
    try {
      final u = updater ?? sb.ShorebirdUpdater();
      final available = u.isAvailable;
      var patch = 0;
      if (available) {
        final current = await u.readCurrentPatch().timeout(const Duration(seconds: 2));
        patch = current?.number ?? 0;
      }
      return {
        'patch_number': patch, // 0 = base release, no patch applied
        'shorebird_available': available,
        'shorebird_track': BuildInfo.shorebirdTrack,
      };
    } catch (_) {
      return {
        'patch_number': 0,
        'shorebird_available': false,
        'shorebird_track': BuildInfo.shorebirdTrack,
      };
    }
  }

  /// Safe to `unawaited`. Idempotent.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      // Let the first frame render before touching anything.
      await _waitForFirstFrame();

      final updater = _safeUpdater;
      final available = updater?.isAvailable ?? false;
      int? patchNumber;
      if (available) {
        patchNumber = (await _readPatch(updater!))?.number;
      }
      _info = UpdateInfo(
        updaterAvailable: available,
        track: _configuredTrack,
        currentPatch: patchNumber,
      );
      _emit(UpdateInitial(_info));
      if (!available) return;

      _policy = await _policyLoader();
      telemetry.enabled = _policy.telemetryEnabled;
      await _applyObservabilityContext();

      await telemetry.flush();
      await _reportLaunchOfPatch(patchNumber);

      if (_policy.autoCheckEnabled) {
        await checkForUpdate();
      }
    } catch (e, s) {
      await _fail('initialize', e, s);
    }
  }

  /// Checks for a patch and downloads it. [force] bypasses the auto-check
  /// switch and the minimum interval (used by an explicit "check now").
  Future<void> checkForUpdate({bool force = false}) async {
    if (_checking) return;
    final updater = _safeUpdater;
    if (updater == null || !updater.isAvailable) return;
    if (!force && !_policy.autoCheckEnabled) return;

    if (_policy.blockDuringCalls && _busy()) {
      await obs.breadcrumb('update check skipped: user busy', feature: 'updates');
      return;
    }
    if (!force && !await _intervalElapsed()) return;

    _checking = true;
    try {
      _emit(UpdateChecking(_info));
      final track = _effectiveTrack();
      final status = await updater
          .checkForUpdate(track: _toShorebirdTrack(track))
          .timeout(checkTimeout);
      await _markChecked();
      _info = _info.copyWith(lastCheckedAt: _clock());

      switch (status) {
        case sb.UpdateStatus.upToDate:
          _emit(UpdateConfirmedRunning(_info));
        case sb.UpdateStatus.restartRequired:
          _emit(UpdateReadyToInstall(_info));
        case sb.UpdateStatus.unavailable:
          _emit(UpdateInitial(_info));
        case sb.UpdateStatus.outdated:
          await _downloadLatest(updater, track);
      }
    } catch (e, s) {
      await _fail('check', e, s);
    } finally {
      _checking = false;
    }
  }

  Future<void> _downloadLatest(sb.ShorebirdUpdater updater, AppUpdateTrack track) async {
    _emit(UpdateAvailable(_info, availableTrack: track.wire));
    await _report(UpdateEventType.patchAvailable, details: {'track': track.wire});

    // Re-check busy: the user may have started a call during the status check.
    if (_policy.blockDuringCalls && _busy()) {
      await obs.breadcrumb('update download deferred: user busy', feature: 'updates');
      return;
    }

    _emit(UpdateDownloading(_info));
    await updater.update(track: _toShorebirdTrack(track)).timeout(downloadTimeout);
    await _report(UpdateEventType.patchDownloaded, details: {'track': track.wire});
    _emit(UpdateReadyToInstall(_info));
  }

  /// Called once per process start. A patch number different from the last one
  /// we reported means the engine just applied a new patch (`patch_installed`);
  /// surviving [confirmDelay] without a crash then confirms it
  /// (`confirmed_running`). A crash loop therefore never confirms.
  Future<void> _reportLaunchOfPatch(int? patch) async {
    if (patch == null) return;
    final prefs = await _prefsLoader();
    final last = prefs.getInt(lastReportedPatchPrefsKey);
    if (last != patch) {
      await _report(UpdateEventType.patchInstalled, patch: patch);
    }
    _confirmTimer?.cancel();
    _confirmTimer = Timer(confirmDelay, () async {
      try {
        await _report(UpdateEventType.confirmedRunning, patch: patch);
        await prefs.setInt(lastReportedPatchPrefsKey, patch);
        _emit(UpdateConfirmedRunning(_info));
      } catch (_) {}
    });
  }

  Future<sb.Patch?> _readPatch(sb.ShorebirdUpdater updater) async {
    try {
      return await updater.readCurrentPatch().timeout(const Duration(seconds: 5));
    } catch (_) {
      return null;
    }
  }

  Future<void> _applyObservabilityContext() async {
    final ctx = <String, Object>{
      'patch_number': _info.currentPatch ?? 0,
      'shorebird_available': _info.updaterAvailable,
      'shorebird_track': _effectiveTrack().wire,
    };
    for (final e in ctx.entries) {
      await obs.setContext(e.key, e.value);
    }
  }

  AppUpdateTrack _effectiveTrack() {
    if (_configuredTrack == AppUpdateTrack.staging && !_policy.stagingTrackEnabled) {
      return AppUpdateTrack.stable;
    }
    return _configuredTrack;
  }

  sb.UpdateTrack _toShorebirdTrack(AppUpdateTrack t) =>
      t == AppUpdateTrack.staging ? sb.UpdateTrack.staging : sb.UpdateTrack.stable;

  bool _busy() {
    if (_isUserBusy()) return true;
    for (final check in _extraBusyChecks) {
      try {
        if (check()) return true;
      } catch (_) {}
    }
    return false;
  }

  Future<bool> _intervalElapsed() async {
    try {
      final prefs = await _prefsLoader();
      final last = prefs.getInt(lastCheckPrefsKey);
      if (last == null) return true;
      final elapsed = _clock().difference(DateTime.fromMillisecondsSinceEpoch(last));
      return elapsed >= _policy.minCheckInterval;
    } catch (_) {
      return true;
    }
  }

  Future<void> _markChecked() async {
    try {
      final prefs = await _prefsLoader();
      await prefs.setInt(lastCheckPrefsKey, _clock().millisecondsSinceEpoch);
    } catch (_) {}
  }

  Future<void> _report(
    UpdateEventType type, {
    int? patch,
    Map<String, Object?> details = const {},
    String? error,
  }) async {
    final payload = UpdateEventPayload(
      deviceId: await _identity.getInstallationId(),
      platform: Platform.isIOS ? 'ios' : 'android',
      type: type,
      releaseVersion: _releaseVersion,
      appVersion: BuildInfo.appVersion,
      osVersion: Platform.operatingSystemVersion,
      deviceModel: '',
      occurredAt: _clock(),
      patchNumber: patch,
      currentPatch: _info.currentPatch,
      details: details,
      errorMessage: error == null
          ? null
          : (error.length > 500 ? error.substring(0, 500) : error),
    );
    await telemetry.report(payload);
  }

  Future<void> _fail(String operation, Object error, StackTrace stack) async {
    final message = error is TimeoutException
        ? 'timeout during $operation'
        : error.toString().split('\n').first;
    _emit(UpdateFailed(_info, message));
    try {
      await _report(UpdateEventType.updateFailed, error: message, details: {'op': operation});
      await obs.recordError(
        error,
        stack,
        feature: 'updates',
        operation: operation,
        reason: 'shorebird update failed',
        fatal: false,
      );
    } catch (_) {}
  }

  void _emit(UpdateState next) {
    _state = next;
    if (!_controller.isClosed) _controller.add(next);
  }

  @visibleForTesting
  Future<void> debugReportLaunch(int? patch) => _reportLaunchOfPatch(patch);

  Future<void> dispose() async {
    _confirmTimer?.cancel();
    await _controller.close();
  }
}
