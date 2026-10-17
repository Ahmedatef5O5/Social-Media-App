enum IncomingLinkKind {
  /// Anything that belongs to the authentication flow (recovery, OAuth
  /// callback, Supabase verify errors). Must never reach the share flow.
  authCallback,

  /// A post / story / group-invite link that belongs to this app.
  contentLink,

  /// Plain text / any other URL: a genuine user share.
  other,
}

class AuthLinkError {
  final String code;
  final String? description;
  const AuthLinkError(this.code, [this.description]);

  @override
  String toString() => 'AuthLinkError($code)';
}

class IncomingLinkClassifier {
  IncomingLinkClassifier._();

  /// Firebase Hosting domain that carries the verified Android App Links.
  /// Single source of truth: `ShareIntentService` no longer keeps its own copy.
  static const String appHost = 'social-media-app-98f58.web.app';

  /// Custom scheme kept for OAuth (Facebook / Microsoft) callbacks.
  static const String authScheme = 'socialapp';

  static const String recoveryPath = '/auth/recovery';

  /// `redirectTo` used for password-recovery emails. The email template turns
  /// it into `<this url>#token_hash=...&type=recovery`.
  static const String recoveryRedirectUrl = 'https://$appHost$recoveryPath';

  static Uri? tryParse(String raw) {
    final text = raw.trim();
    if (text.isEmpty || text.contains(RegExp(r'\s'))) return null;
    return Uri.tryParse(text);
  }

  static IncomingLinkKind classify(String raw) {
    final uri = tryParse(raw);
    if (uri == null) return IncomingLinkKind.other;
    return classifyUri(uri);
  }

  static IncomingLinkKind classifyUri(Uri uri) {
    if (!uri.hasScheme) return IncomingLinkKind.other;
    final scheme = uri.scheme.toLowerCase();

    // The custom scheme is only ever used by the auth flow.
    if (scheme == authScheme) return IncomingLinkKind.authCallback;

    if (scheme == 'https' || scheme == 'http') {
      final path = uri.path;

      // Supabase hosted verify / callback endpoints.
      if (path.startsWith('/auth/v1/')) return IncomingLinkKind.authCallback;

      if (uri.host.toLowerCase() == appHost) {
        if (path == '/auth' || path.startsWith('/auth/')) {
          return IncomingLinkKind.authCallback;
        }
        return IncomingLinkKind.contentLink;
      }
    }
    return IncomingLinkKind.other;
  }

  /// Query parameters merged with fragment parameters
  /// (`#token_hash=...&type=recovery`, `#error=access_denied&...`).
  static Map<String, String> params(Uri uri) {
    final out = <String, String>{...uri.queryParameters};
    final fragment = uri.fragment;
    if (fragment.contains('=')) {
      try {
        out.addAll(Uri.splitQueryString(fragment));
      } catch (_) {
        // Malformed fragment: ignore, the query part is still usable.
      }
    }
    return out;
  }

  /// Returns the auth error carried by a callback URL, or `null` when the URL
  /// has none. Example:
  /// `#error=access_denied&error_code=otp_expired&error_description=...`
  static AuthLinkError? parseError(Uri uri) {
    final p = params(uri);
    final hasError =
        p.containsKey('error') ||
        p.containsKey('error_code') ||
        p.containsKey('error_description');
    if (!hasError) return null;
    return AuthLinkError(
      p['error_code'] ?? p['error'] ?? 'unknown',
      p['error_description'],
    );
  }
}
