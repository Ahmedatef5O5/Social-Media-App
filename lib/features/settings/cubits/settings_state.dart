import '../../../core/presence/models/presence_privacy.dart';
import '../repository/settings_repository.dart';

/// Typed, presentation-agnostic errors. The cubit has no `BuildContext`, so it
/// reports WHAT went wrong and the view maps it to localized text.
enum SettingsError {
  privacyUpdateFailed,
  visibilityUpdateFailed,
  identityNotVerified,
  biometricNoHardware,
  biometricNotEnrolled,
  biometricLockedOut,
  biometricPermanentlyLockedOut,
  biometricPasscodeNotSet,
  biometricUnknown,
}

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
  final int? recoveryCodesCount;
  final String languageCode;
  final SettingsError? error;

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
    required this.languageCode,
    this.recoveryCodesCount,
    this.error,
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
      languageCode: repo.languageCode,
    );
  }

  /// `error` is intentionally NOT carried over: each emit either sets a fresh
  /// error or clears it (same one-shot semantics the old `errorMessage` had).
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
    int? recoveryCodesCount,
    String? languageCode,
    SettingsError? error,
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
      recoveryCodesCount: recoveryCodesCount ?? this.recoveryCodesCount,
      languageCode: languageCode ?? this.languageCode,
      error: error,
    );
  }
}
