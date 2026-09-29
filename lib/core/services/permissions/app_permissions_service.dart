import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../notifications/notification_navigator_key.dart';
import '../../supabase/supabase_provider.dart';
import '../../toast/app_toast.dart';

class AppPermissionsService {
  AppPermissionsService._();

  static final AppPermissionsService instance = AppPermissionsService._();

  static const String _kInitialRequestedKey =
      'initial_media_permissions_requested_v1';

  Future<void>? _initialInFlight;

  // Serialises [ensureCallPermissions]: a double tap on "Call" must never
  // stack two permission dialogs on top of each other.
  Future<void> _callPermissionTail = Future<void>.value();

  // ── Warm-up ────────────────────────────────────────────────────────────

  Future<void> requestInitialMediaPermissionsIfNeeded() {
    final inFlight = _initialInFlight;
    if (inFlight != null) return inFlight;

    final future = _runInitialRequest().whenComplete(
      () => _initialInFlight = null,
    );
    _initialInFlight = future;
    return future;
  }

  Future<void> _runInitialRequest() async {
    // Not signed in yet (login screen): do NOT consume the one-time flag.
    if (SupabaseProvider.idOrNull == null) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kInitialRequestedKey) ?? false) return;

    try {
      // Sequential on purpose — two simultaneous OS dialogs are dropped by
      // Android and the second permission silently stays undetermined.
      await Permission.microphone.request();
      await Permission.camera.request();
    } catch (e) {
      debugPrint('[AppPermissionsService] initial request failed: $e');
      return;
    }

    await prefs.setBool(_kInitialRequestedKey, true);
  }

  // ── Pre-call guard ─────────────────────────────────────────────────────

  Future<bool> hasCallPermissions({required bool isVideo}) async {
    if (!await Permission.microphone.isGranted) return false;
    if (isVideo && !await Permission.camera.isGranted) return false;
    return true;
  }

  Future<bool> ensureCallPermissions({
    required bool isVideo,
    BuildContext? context,
  }) {
    final completer = Completer<bool>();
    _callPermissionTail = _callPermissionTail.then((_) async {
      try {
        completer.complete(await _ensure(isVideo: isVideo, context: context));
      } catch (e, s) {
        debugPrint('[AppPermissionsService] ensureCallPermissions: $e\n$s');
        if (!completer.isCompleted) completer.complete(false);
      }
    });
    return completer.future;
  }

  Future<bool> _ensure({
    required bool isVideo,
    required BuildContext? context,
  }) async {
    if (await hasCallPermissions(isVideo: isVideo)) return true;

    final micStatus = await Permission.microphone.request();
    final camStatus =
        isVideo ? await Permission.camera.request() : PermissionStatus.granted;

    if (micStatus.isGranted && camStatus.isGranted) return true;

    final micBlocked = micStatus.isPermanentlyDenied || micStatus.isRestricted;
    final camBlocked =
        isVideo && (camStatus.isPermanentlyDenied || camStatus.isRestricted);

    if (micBlocked || camBlocked) {
      await _promptOpenSettings(
        context: context,
        missingMic: !micStatus.isGranted,
        missingCamera: isVideo && !camStatus.isGranted,
      );
      return false;
    }

    // Denied this time, but the OS will still let us ask again next time.
    AppToast.info(
      isVideo
          ? 'Microphone and camera access are needed for video calls'
          : 'Microphone access is needed for calls',
    );
    return false;
  }

  Future<void> _promptOpenSettings({
    required BuildContext? context,
    required bool missingMic,
    required bool missingCamera,
  }) async {
    final host = navigatorKey.currentContext ?? context;
    if (host == null || !host.mounted) {
      AppToast.info('Enable microphone/camera access in Settings to call');
      return;
    }

    final what =
        missingMic && missingCamera
            ? 'Microphone and Camera'
            : (missingMic ? 'Microphone' : 'Camera');

    final openSettings = await showDialog<bool>(
      context: host,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Permission required'),
            content: Text(
              '$what access is turned off for this app. '
              'Enable it in Settings to make or join calls.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Not now'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
    );

    if (openSettings == true) {
      await openAppSettings();
    }
  }
}
