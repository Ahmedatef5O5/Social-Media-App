/// Build-time metadata, supplied the same way `AppSecrets` already is:
/// `--dart-define-from-file=.env` locally, `--dart-define` in CI.
///
/// Deliberately NOT `package_info_plus` — that would add a dependency and a
/// platform channel call to the startup path for three strings the build
/// already knows.
class BuildInfo {
  BuildInfo._();

  /// Mirrors `version:` in pubspec.yaml (currently `1.0.0+2`).
  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '0.0.0-dev',
  );

  static const String buildNumber = String.fromEnvironment(
    'BUILD_NUMBER',
    defaultValue: '0',
  );

  /// `dev` | `staging` | `production`.
  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  /// Short commit SHA, injected by CI so a Crashlytics issue points at an
  /// exact revision.
  static const String commitSha = String.fromEnvironment(
    'COMMIT_SHA',
    defaultValue: 'local',
  );

  static bool get isProduction => environment == 'production';
}
