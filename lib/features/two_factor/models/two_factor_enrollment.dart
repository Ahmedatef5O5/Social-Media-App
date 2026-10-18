/// Result of `mfa.enroll`, with SDK types stripped so views stay SDK-free.
class TwoFactorEnrollment {
  final String factorId;

  /// Raw `<svg>` markup, ready for `SvgPicture.string`.
  final String qrSvg;

  /// Base32 secret for manual entry.
  final String secret;

  /// `otpauth://` URI, openable in an authenticator app on the same phone.
  final String otpauthUri;

  const TwoFactorEnrollment({
    required this.factorId,
    required this.qrSvg,
    required this.secret,
    required this.otpauthUri,
  });
}
