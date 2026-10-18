import '../models/two_factor_enrollment.dart';

enum TwoFactorSetupStep {
  intro,
  enrolling,
  scan,
  enterCode,
  verifying,
  generatingCodes,
  recoveryCodes,

  /// `enroll` failed (no QR to show).
  failure,

  /// The code was verified (2FA IS active) but recovery codes could not be
  /// generated; the user can retry without repeating the verification.
  codesError,
}

class TwoFactorSetupState {
  final TwoFactorSetupStep step;
  final TwoFactorEnrollment? enrollment;
  final List<String> codes;
  final String? error;
  final int invalidAttempts;

  const TwoFactorSetupState({
    this.step = TwoFactorSetupStep.intro,
    this.enrollment,
    this.codes = const [],
    this.error,
    this.invalidAttempts = 0,
  });

  /// After two wrong codes the most likely cause is a skewed phone clock.
  bool get showClockHint => invalidAttempts >= 2;

  /// True once the factor is verified: leaving now keeps 2FA enabled.
  bool get isActive =>
      step == TwoFactorSetupStep.generatingCodes ||
      step == TwoFactorSetupStep.recoveryCodes ||
      step == TwoFactorSetupStep.codesError;

  static const Object _unset = Object();

  TwoFactorSetupState copyWith({
    TwoFactorSetupStep? step,
    TwoFactorEnrollment? enrollment,
    List<String>? codes,
    Object? error = _unset,
    int? invalidAttempts,
  }) => TwoFactorSetupState(
    step: step ?? this.step,
    enrollment: enrollment ?? this.enrollment,
    codes: codes ?? this.codes,
    error: identical(error, _unset) ? this.error : error as String?,
    invalidAttempts: invalidAttempts ?? this.invalidAttempts,
  );
}
