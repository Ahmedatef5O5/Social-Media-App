import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../notifications/notification_navigator_key.dart';
import '../../supabase/supabase_provider.dart';
import '../../toast/app_toast.dart';
import 'package:social_media_app/core/localization/app_l10n.dart';

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

    AppToast.info(
      isVideo
          ? AppL10n.current.enableMicrophoneCameraAccess
          : AppL10n.current.microphonePermissionIsRequired,
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
      AppToast.info(AppL10n.current.enableMicrophoneCameraAccess);
      return;
    }

    final isAr = AppL10n.isArabic;
    final what =
        missingMic && missingCamera
            ? (isAr ? 'الميكروفون والكاميرا' : 'Microphone and Camera')
            : (missingMic
                ? (isAr ? 'الميكروفون' : 'Microphone')
                : (isAr ? 'الكاميرا' : 'Camera'));

    final openSettings = await showDialog<bool>(
      context: host,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(AppL10n.current.permissionRequired),
            content: Text(AppL10n.current.accessIsTurnedOff(what)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(AppL10n.current.notNow),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(AppL10n.current.openSettings),
              ),
            ],
          ),
    );

    if (openSettings == true) {
      await openAppSettings();
    }
  }
}
