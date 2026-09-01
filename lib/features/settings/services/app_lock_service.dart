import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../repository/settings_repository.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:local_auth/error_codes.dart' as auth_error;

enum BiometricAvailability {
  available,
  noHardware,
  notEnrolled,
  lockedOut,
  permanentlyLockedOut,
  passcodeNotSet,
  unknown,
}

class AppLockService with WidgetsBindingObserver {
  AppLockService._();
  static final AppLockService instance = AppLockService._();

  final LocalAuthentication _auth = LocalAuthentication();

  static const Duration lockTimeout = Duration(seconds: 30);

  DateTime? _pausedAt;
  bool _initialised = false;

  final ValueNotifier<bool> lockNotifier = ValueNotifier<bool>(false);

  bool get isLocked => lockNotifier.value;

  void init() {
    if (_initialised) return;
    _initialised = true;
    WidgetsBinding.instance.addObserver(this);

    if (_shouldEnforceLock()) {
      lockNotifier.value = true;
    }
  }

  void dispose() {
    if (!_initialised) return;
    WidgetsBinding.instance.removeObserver(this);
    _initialised = false;
  }

  bool _hasActiveSession() => SupabaseProvider.auth.currentSession != null;

  bool _shouldEnforceLock() =>
      SettingsRepository.instance.biometricLock && _hasActiveSession();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_shouldEnforceLock()) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _pausedAt ??= DateTime.now();
        break;
      case AppLifecycleState.resumed:
        final pausedAt = _pausedAt;
        _pausedAt = null;
        if (pausedAt == null) return;
        final elapsed = DateTime.now().difference(pausedAt);
        if (elapsed >= lockTimeout) {
          lockNotifier.value = true;
        }
        break;
      default:
        break;
    }
  }

  BiometricAvailability? lastUnlockFailureReason;

  Future<bool> unlock() async {
    lastUnlockFailureReason = null;
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheckBiometrics = await _auth.canCheckBiometrics;

      if (!isSupported && !canCheckBiometrics) {
        lockNotifier.value = false;
        return true;
      }

      final didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please verify your identity to open the app.',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        lockNotifier.value = false;
      }
      return didAuthenticate;
    } on PlatformException catch (e) {
      lastUnlockFailureReason = _mapAuthErrorCode(e.code);
      debugPrint('[AppLockService] unlock error: ${e.code} ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[AppLockService] unlock error: $e');
      return false;
    }
  }

  Future<BiometricAvailability> checkBiometricAvailability() async {
    try {
      final isDeviceSupported = await _auth.isDeviceSupported();
      if (!isDeviceSupported) {
        return BiometricAvailability.passcodeNotSet;
      }

      final canCheckBiometrics = await _auth.canCheckBiometrics;
      final enrolledBiometrics = await _auth.getAvailableBiometrics();

      if (!canCheckBiometrics && enrolledBiometrics.isEmpty) {
        return BiometricAvailability.noHardware;
      }

      if (enrolledBiometrics.isEmpty) {
        return BiometricAvailability.notEnrolled;
      }

      return BiometricAvailability.available;
    } on PlatformException catch (e) {
      debugPrint(
        '[AppLockService] checkBiometricAvailability error: ${e.code}',
      );
      return _mapAuthErrorCode(e.code);
    } catch (e) {
      debugPrint('[AppLockService] checkBiometricAvailability error: $e');
      return BiometricAvailability.unknown;
    }
  }

  BiometricAvailability _mapAuthErrorCode(String code) {
    switch (code) {
      case auth_error.notEnrolled:
        return BiometricAvailability.notEnrolled;
      case auth_error.notAvailable:
        return BiometricAvailability.noHardware;
      case auth_error.lockedOut:
        return BiometricAvailability.lockedOut;
      case auth_error.permanentlyLockedOut:
        return BiometricAvailability.permanentlyLockedOut;
      case auth_error.passcodeNotSet:
        return BiometricAvailability.passcodeNotSet;
      default:
        return BiometricAvailability.unknown;
    }
  }

  Future<bool> verifyDeviceSupportsBiometrics() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      return isSupported && canCheckBiometrics;
    } catch (e) {
      debugPrint('[AppLockService] verifyDeviceSupportsBiometrics error: $e');
      return false;
    }
  }
}
