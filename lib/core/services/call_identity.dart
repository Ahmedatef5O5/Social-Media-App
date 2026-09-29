class CallIdentity {
  const CallIdentity._();

  static final RegExp _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// `true` when [identity] is a Supabase user UUID.
  static bool looksLikeUserId(String identity) => _uuid.hasMatch(identity);

  /// Placeholder names that must never be sent to LiveKit or displayed.
  static bool isPlaceholderName(String? name) {
    if (name == null) return true;
    final trimmed = name.trim();
    return trimmed.isEmpty || trimmed == 'Loading...' || trimmed == 'Me';
  }
}
