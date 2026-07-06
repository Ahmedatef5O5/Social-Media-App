import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/settings/cubit/settings_state.dart';
import '../../../core/services/presence_service.dart';
import '../repository/settings_repository.dart';
import '../services/app_lock_service.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(SettingsState.fromRepository());

  Future<void> setPushNotifications(bool value) async {
    await SettingsRepository.instance.setPushNotifications(value);
    emit(state.copyWith(pushNotifications: value));
  }

  Future<void> setMessagePreviews(bool value) async {
    await SettingsRepository.instance.setMessagePreviews(value);
    emit(state.copyWith(messagePreviews: value));
  }

  Future<void> setCallNotifications(bool value) async {
    await SettingsRepository.instance.setCallNotifications(value);
    emit(state.copyWith(callNotifications: value));
  }

  Future<void> setReadReceipts(bool value) async {
    await SettingsRepository.instance.setReadReceipts(value);
    emit(state.copyWith(readReceipts: value));
  }

  Future<void> setOnlineStatus(bool value) async {
    await SettingsRepository.instance.setOnlineStatus(value);
    await PresenceService.instance.setVisibility(value);
    emit(state.copyWith(onlineStatus: value));
  }

  Future<void> setTwoFactor(bool value) async {
    await SettingsRepository.instance.setTwoFactor(value);
    emit(state.copyWith(twoFactor: value));
  }

  Future<void> toggleBiometricLock(bool value) async {
    if (value) {
      final supported =
          await AppLockService.instance.verifyDeviceSupportsBiometrics();
      if (!supported) {
        emit(
          state.copyWith(
            errorMessage:
                'Your device does not support fingerprint or Face ID, or neither has been registered in the system settings.',
          ),
        );
        emit(state.copyWith(errorMessage: null));
        return;
      }

      final confirmed = await AppLockService.instance.unlock();
      if (!confirmed) {
        emit(
          state.copyWith(
            errorMessage:
                'Your identity has not been verified; please try again.',
          ),
        );
        emit(state.copyWith(errorMessage: null));
        return;
      }
    }

    await SettingsRepository.instance.setBiometricLock(value);
    emit(state.copyWith(biometricLock: value));
  }
}
