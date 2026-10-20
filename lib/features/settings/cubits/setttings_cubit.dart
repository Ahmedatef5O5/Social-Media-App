import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/settings/cubits/settings_state.dart';
import '../../../core/helpers/safe_emit_mixin.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/notifications/services/notification_prefs_sync_service.dart';
import '../../../core/presence/services/presence_service.dart';
import '../../auth/data/models/user_data.dart';
import '../../home/cubits/home_cubit/home_cubit.dart';
import '../../profile/services/user_services.dart';
import '../../../core/presence/models/presence_privacy.dart';
import '../../two_factor/models/two_factor_status.dart';
import '../../two_factor/services/two_factor_service.dart';
import '../repository/settings_repository.dart';
import '../services/app_lock_service.dart';
import '../services/language_sync_service.dart';
import 'locale_cubit.dart';

class SettingsCubit extends Cubit<SettingsState>
    with SafeEmitMixin<SettingsState> {
  final UserService _userService;
  final HomeCubit _homeCubit;
  final LocaleCubit? _localeCubit;

  SettingsCubit({
    required UserService userService,
    required HomeCubit homeCubit,
    LocaleCubit? localeCubit,
    UserData? currentUser,
  }) : _userService = userService,
       _homeCubit = homeCubit,
       _localeCubit = localeCubit,
       super(
         SettingsState.fromRepository(
           presencePrivacy:
               currentUser?.presencePrivacy ?? PresencePrivacy.friends,
           presenceVisibleTo: currentUser?.presenceVisibleTo ?? const [],
         ),
       ) {
    refreshTwoFactorStatus();
  }

  Future<void> setPushNotifications(bool value) async {
    await SettingsRepository.instance.setPushNotifications(value);
    emit(state.copyWith(pushNotifications: value));
    await NotificationPrefsSyncService.instance.markDirtyAndSync();
  }

  Future<void> setMessagePreviews(bool value) async {
    await SettingsRepository.instance.setMessagePreviews(value);
    emit(state.copyWith(messagePreviews: value));
    await NotificationPrefsSyncService.instance.markDirtyAndSync();
  }

  Future<void> setCallNotifications(bool value) async {
    await SettingsRepository.instance.setCallNotifications(value);
    emit(state.copyWith(callNotifications: value));
    await NotificationPrefsSyncService.instance.markDirtyAndSync();
  }

  Future<void> setReadReceipts(bool value) async {
    await SettingsRepository.instance.setReadReceipts(value);
    emit(state.copyWith(readReceipts: value));
  }

  Future<void> setOnlineStatus(bool value) async {
    await SettingsRepository.instance.setOnlineStatus(value);
    await PresenceService.instance.setVisibility(value);

    if (!value) {
      final previousPrivacy = state.presencePrivacy;
      emit(
        state.copyWith(
          onlineStatus: value,
          presencePrivacy: PresencePrivacy.nobody,
        ),
      );
      try {
        await _userService.updatePresencePrivacy(PresencePrivacy.nobody);
        _homeCubit.currentUserData = _homeCubit.currentUserData?.copyWith(
          presencePrivacy: PresencePrivacy.nobody,
        );
      } catch (e) {
        emit(state.copyWith(presencePrivacy: previousPrivacy));
      }
    } else {
      emit(state.copyWith(onlineStatus: value));
    }
  }

  Future<void> setPresencePrivacy(PresencePrivacy value) async {
    final previous = state.presencePrivacy;
    emit(state.copyWith(presencePrivacy: value));

    try {
      await _userService.updatePresencePrivacy(value);
      _homeCubit.currentUserData = _homeCubit.currentUserData?.copyWith(
        presencePrivacy: value,
      );
    } catch (e) {
      emit(
        state.copyWith(
          presencePrivacy: previous,
          error: SettingsError.privacyUpdateFailed,
        ),
      );
      emit(state.copyWith());
    }
  }

  Future<void> setPresenceVisibleTo(List<String> userIds) async {
    final previous = state.presenceVisibleTo;
    emit(state.copyWith(presenceVisibleTo: userIds));

    try {
      await _userService.updatePresenceVisibleTo(userIds);
      _homeCubit.currentUserData = _homeCubit.currentUserData?.copyWith(
        presenceVisibleTo: userIds,
      );
    } catch (e) {
      emit(
        state.copyWith(
          presenceVisibleTo: previous,
          error: SettingsError.visibilityUpdateFailed,
        ),
      );
      emit(state.copyWith());
    }
  }

  Future<void> setTwoFactor(bool value) async {
    await SettingsRepository.instance.setTwoFactor(value);
    emit(state.copyWith(twoFactor: value));
  }

  Future<void> refreshTwoFactorStatus() async {
    try {
      const service = TwoFactorService();
      final status = await service.status();
      final isEnabled = status == TwoFactorStatus.enabled;
      int? count;
      if (isEnabled) {
        try {
          count = await service.recoveryCodesRemaining();
        } catch (_) {}
      }
      emit(state.copyWith(twoFactor: isEnabled, recoveryCodesCount: count));
    } catch (_) {}
  }

  Future<void> toggleBiometricLock(bool value) async {
    if (value) {
      final availability =
          await AppLockService.instance.checkBiometricAvailability();
      if (availability != BiometricAvailability.available) {
        emit(state.copyWith(error: _biometricError(availability)));
        emit(state.copyWith());
        return;
      }

      final confirmed = await AppLockService.instance.unlock();
      if (!confirmed) {
        final reason = AppLockService.instance.lastUnlockFailureReason;
        emit(
          state.copyWith(
            error:
                reason != null
                    ? _biometricError(reason)
                    : SettingsError.identityNotVerified,
          ),
        );
        emit(state.copyWith());
        return;
      }
    }

    await SettingsRepository.instance.setBiometricLock(value);
    emit(state.copyWith(biometricLock: value));
  }

  SettingsError _biometricError(BiometricAvailability reason) {
    switch (reason) {
      case BiometricAvailability.noHardware:
        return SettingsError.biometricNoHardware;
      case BiometricAvailability.notEnrolled:
        return SettingsError.biometricNotEnrolled;
      case BiometricAvailability.lockedOut:
        return SettingsError.biometricLockedOut;
      case BiometricAvailability.permanentlyLockedOut:
        return SettingsError.biometricPermanentlyLockedOut;
      case BiometricAvailability.passcodeNotSet:
        return SettingsError.biometricPasscodeNotSet;
      case BiometricAvailability.available:
      case BiometricAvailability.unknown:
        return SettingsError.biometricUnknown;
    }
  }

  /// Persists the UI language, flips `MaterialApp.locale` immediately (via the
  /// app-wide [LocaleCubit]) and mirrors the choice to `public.users` so push
  /// notifications are localized server-side.
  Future<void> setLanguage(String code) async {
    final normalized = AppLocale.normalize(code);
    if (normalized == SettingsRepository.instance.languageCode &&
        normalized == state.languageCode) {
      return;
    }

    await SettingsRepository.instance.setLanguageCode(normalized);
    _localeCubit?.apply(normalized);
    if (!isClosed) emit(state.copyWith(languageCode: normalized));
    unawaited(LanguageSyncService.instance.syncNow());
  }
}
