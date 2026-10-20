enum TwoFactorFailureKind {
  invalidCode,
  challengeExpired,
  rateLimited,
  aalRequired,
  noFactor,
  offline,
  notEnabledOnProject,
  unknown,
}

/// The only error type that leaves the two_factor service layer.
class TwoFactorFailure implements Exception {
  final TwoFactorFailureKind kind;
  final String message;

  const TwoFactorFailure(this.kind, this.message);

  const TwoFactorFailure.unknown()
    : this(
        TwoFactorFailureKind.unknown,
        'Something went wrong. Please try again.',
      );

  const TwoFactorFailure.noFactor()
    : this(
        TwoFactorFailureKind.noFactor,
        'Two-factor authentication is not set up on this account.',
      );

  @override
  String toString() => 'TwoFactorFailure($kind): $message';
}

/// Outcome of redeeming a backup code (`redeem_mfa_recovery_code`).
class RedeemResult {
  final bool ok;

  /// `invalid` | `locked` | `no_factor` (null when [ok]).
  final String? reason;
  final int? attemptsLeft;
  final int? retryAfterSeconds;

  const RedeemResult({
    required this.ok,
    this.reason,
    this.attemptsLeft,
    this.retryAfterSeconds,
  });

  bool get isLocked => reason == 'locked';

  factory RedeemResult.fromJson(Map<String, dynamic> json) => RedeemResult(
    ok: json['ok'] == true,
    reason: json['reason'] as String?,
    attemptsLeft: (json['attempts_left'] as num?)?.toInt(),
    retryAfterSeconds: (json['retry_after_seconds'] as num?)?.toInt(),
  );
}
