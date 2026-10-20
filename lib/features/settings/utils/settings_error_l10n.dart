import '../../../core/localization/l10n_extension.dart';
import '../cubits/settings_state.dart';

extension SettingsErrorL10n on AppLocalizations {
  /// Maps the cubit's typed error to the localized message.
  String settingsErrorMessage(SettingsError error) => switch (error) {
    SettingsError.privacyUpdateFailed => settingsErrorPrivacyUpdate,
    SettingsError.visibilityUpdateFailed => settingsErrorVisibilityUpdate,
    SettingsError.identityNotVerified => settingsErrorIdentityNotVerified,
    SettingsError.biometricNoHardware => settingsErrorBiometricNoHardware,
    SettingsError.biometricNotEnrolled => settingsErrorBiometricNotEnrolled,
    SettingsError.biometricLockedOut => settingsErrorBiometricLockedOut,
    SettingsError.biometricPermanentlyLockedOut =>
      settingsErrorBiometricPermanentlyLockedOut,
    SettingsError.biometricPasscodeNotSet =>
      settingsErrorBiometricPasscodeNotSet,
    SettingsError.biometricUnknown => settingsErrorBiometricUnknown,
  };
}
