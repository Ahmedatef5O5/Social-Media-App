import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/settings/cubits/settings_state.dart';
import '../../../core/presence/services/presence_service.dart';
import '../../auth/data/models/user_data.dart';
import '../../home/cubits/home_cubit/home_cubit.dart';
import '../../profile/services/user_services.dart';
import '../../../core/presence/model/presence_privacy.dart';
import '../repository/settings_repository.dart';
import '../services/app_lock_service.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final UserService _userService;
  final HomeCubit _homeCubit;

  SettingsCubit({
    required UserService userService,
    required HomeCubit homeCubit,
    UserData? currentUser,
  }) : _userService = userService,
       _homeCubit = homeCubit,
       super(
         SettingsState.fromRepository(
           presencePrivacy:
               currentUser?.presencePrivacy ?? PresencePrivacy.friends,
           presenceVisibleTo: currentUser?.presenceVisibleTo ?? const [],
         ),
       );

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
          errorMessage: 'Failed to update privacy setting.',
        ),
      );
      emit(state.copyWith(errorMessage: null));
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
          errorMessage: 'Failed to update visibility list.',
        ),
      );
      emit(state.copyWith(errorMessage: null));
    }
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
