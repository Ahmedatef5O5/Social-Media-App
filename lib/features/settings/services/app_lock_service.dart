import 'package:flutter/widgets.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../repository/settings_repository.dart';

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

  Future<bool> unlock() async {
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
    } catch (e) {
      debugPrint('[AppLockService] unlock error: $e');
      return false;
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
