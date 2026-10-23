import '../localization/app_l10n.dart';
import '../../l10n/generated/app_localizations.dart';

class AppValidators {
  static final RegExp _nameRegExp = RegExp(
    r"^[a-zA-Zأ-ي]+(([',. -][a-zA-Zأ-ي ])?[a-zA-Zأ-ي]*)*$",
  );
  static final RegExp _emailRegExp = RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
  );

  static String? validateName(String? value, [AppLocalizations? l10n]) {
    final strings = l10n ?? AppL10n.current;
    if (value == null || value.trim().isEmpty) {
      return strings.valNameRequired;
    }
    if (!_nameRegExp.hasMatch(value.trim())) {
      return strings.valNameInvalid;
    }
    if (value.trim().length < 2) {
      return strings.valNameMinLength;
    }
    return null;
  }

  static String? validateEmail(String? value, [AppLocalizations? l10n]) {
    final strings = l10n ?? AppL10n.current;
    if (value == null || value.trim().isEmpty) {
      return strings.valEmailRequired;
    }
    if (!_emailRegExp.hasMatch(value.trim())) {
      return strings.valEmailInvalid;
    }
    return null;
  }

  static String? validatePassword(String? value, [AppLocalizations? l10n]) {
    final strings = l10n ?? AppL10n.current;
    if (value == null || value.isEmpty) {
      return strings.valPasswordRequired;
    }
    if (value.length < 6) {
      return strings.valPasswordMinLength;
    }
    return null;
  }

  static String? validateConfirmPassword(
    String? value,
    String password, [
    AppLocalizations? l10n,
  ]) {
    final strings = l10n ?? AppL10n.current;
    if (value == null || value.isEmpty) {
      return strings.valConfirmPasswordRequired;
    }
    if (value != password) {
      return strings.valPasswordsDoNotMatch;
    }
    return null;
  }

  static double calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0.0;
    double strength = 0.0;
    if (password.length >= 8) strength += 0.25;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.25;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.25;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.25;
    return strength;
  }
}
