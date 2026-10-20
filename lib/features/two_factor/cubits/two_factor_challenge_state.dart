enum TwoFactorChallengeMode { totp, backup }

class TwoFactorChallengeState {
  final TwoFactorChallengeMode mode;
  final bool submitting;
  final String? error;

  /// Remaining pause, null when not paused.
  final Duration? lockRemaining;

  /// Which input the pause applies to (a backup-code pause must not block the
  /// authenticator field and vice versa).
  final TwoFactorChallengeMode? lockMode;
  final int consecutiveInvalid;
  final bool completed;

  /// True when a backup code was used: 2FA is now OFF and the user should be
  /// invited to set it up again.
  final bool reenrollRequired;

  const TwoFactorChallengeState({
    this.mode = TwoFactorChallengeMode.totp,
    this.submitting = false,
    this.error,
    this.lockRemaining,
    this.lockMode,
    this.consecutiveInvalid = 0,
    this.completed = false,
    this.reenrollRequired = false,
  });

  bool get isLocked =>
      lockRemaining != null &&
      lockRemaining! > Duration.zero &&
      lockMode == mode;

  bool get showClockHint =>
      mode == TwoFactorChallengeMode.totp && consecutiveInvalid >= 2;

  static const Object _unset = Object();

  TwoFactorChallengeState copyWith({
    TwoFactorChallengeMode? mode,
    bool? submitting,
    Object? error = _unset,
    Object? lockRemaining = _unset,
    Object? lockMode = _unset,
    int? consecutiveInvalid,
    bool? completed,
    bool? reenrollRequired,
  }) => TwoFactorChallengeState(
    mode: mode ?? this.mode,
    submitting: submitting ?? this.submitting,
    error: identical(error, _unset) ? this.error : error as String?,
    lockRemaining:
        identical(lockRemaining, _unset)
            ? this.lockRemaining
            : lockRemaining as Duration?,
    lockMode:
        identical(lockMode, _unset)
            ? this.lockMode
            : lockMode as TwoFactorChallengeMode?,
    consecutiveInvalid: consecutiveInvalid ?? this.consecutiveInvalid,
    completed: completed ?? this.completed,
    reenrollRequired: reenrollRequired ?? this.reenrollRequired,
  );
}
