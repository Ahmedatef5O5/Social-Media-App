class AppSecrets {
  AppSecrets._();

  // ── Supabase ──
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  // ── Cloudinary ──
  static const String cloudinaryCloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
  );

  static const String cloudinaryUploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
  );

  // ── ZegoCloud ──
  static const int zegoAppId = int.fromEnvironment(
    'ZEGO_APP_ID',
    defaultValue: 0,
  );

  // ── FCM ──
  static const String fcmProjectId = String.fromEnvironment('FCM_PROJECT_ID');

  // ── Giphy (Comments → GIF picker) ──
  static const String giphyApiKey = String.fromEnvironment('GIPHY_API_KEY');

  static void assertSecretsLoaded() {
    assert(
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty,
      '\n\n❌ AppSecrets are not loaded!\n'
      'Please run the app using this command:\n'
      '  flutter run --dart-define-from-file=.env\n'
      'Or configure your launch.json file (check .vscode/launch.json).\n',
    );
  }
}
