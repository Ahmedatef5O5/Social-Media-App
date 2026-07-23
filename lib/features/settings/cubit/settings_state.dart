import '../../../core/presence/model/presence_privacy.dart';
import '../repository/settings_repository.dart';

class SettingsState {
  final bool pushNotifications;
  final bool messagePreviews;
  final bool callNotifications;
  final bool readReceipts;
  final bool onlineStatus;
  final bool biometricLock;
  final bool twoFactor;
  final PresencePrivacy presencePrivacy;
  final List<String> presenceVisibleTo;

  final String? errorMessage;

  const SettingsState({
    required this.pushNotifications,
    required this.messagePreviews,
    required this.callNotifications,
    required this.readReceipts,
    required this.onlineStatus,
    required this.biometricLock,
    required this.twoFactor,
    required this.presencePrivacy,
    required this.presenceVisibleTo,
    this.errorMessage,
  });

  factory SettingsState.fromRepository({
    PresencePrivacy presencePrivacy = PresencePrivacy.friends,
    List<String> presenceVisibleTo = const [],
  }) {
    final repo = SettingsRepository.instance;
    return SettingsState(
      pushNotifications: repo.pushNotifications,
      messagePreviews: repo.messagePreviews,
      callNotifications: repo.callNotifications,
      readReceipts: repo.readReceipts,
      onlineStatus: repo.onlineStatus,
      biometricLock: repo.biometricLock,
      twoFactor: repo.twoFactor,
      presencePrivacy: presencePrivacy,
      presenceVisibleTo: presenceVisibleTo,
    );
  }

  SettingsState copyWith({
    bool? pushNotifications,
    bool? messagePreviews,
    bool? callNotifications,
    bool? readReceipts,
    bool? onlineStatus,
    bool? biometricLock,
    bool? twoFactor,
    PresencePrivacy? presencePrivacy,
    List<String>? presenceVisibleTo,
    String? errorMessage,
  }) {
    return SettingsState(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      messagePreviews: messagePreviews ?? this.messagePreviews,
      callNotifications: callNotifications ?? this.callNotifications,
      readReceipts: readReceipts ?? this.readReceipts,
      onlineStatus: onlineStatus ?? this.onlineStatus,
      biometricLock: biometricLock ?? this.biometricLock,
      twoFactor: twoFactor ?? this.twoFactor,
      presencePrivacy: presencePrivacy ?? this.presencePrivacy,
      presenceVisibleTo: presenceVisibleTo ?? this.presenceVisibleTo,
      errorMessage: errorMessage,
    );
  }
}
