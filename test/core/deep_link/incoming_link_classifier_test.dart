import 'package:flutter_test/flutter_test.dart';
import 'package:social_media_app/core/deep_link/services/incoming_link_classifier.dart';

void main() {
  group('IncomingLinkClassifier.classify', () {
    test('custom scheme callback is an auth link', () {
      expect(
        IncomingLinkClassifier.classify('socialapp://login-callback?code=abc'),
        IncomingLinkKind.authCallback,
      );
      expect(
        IncomingLinkClassifier.classify(
          'socialapp://login-callback#error=access_denied&error_code=otp_expired',
        ),
        IncomingLinkKind.authCallback,
      );
    });

    test('recovery app link is an auth link', () {
      expect(
        IncomingLinkClassifier.classify(
          'https://social-media-app-98f58.web.app/auth/recovery#token_hash=h&type=recovery',
        ),
        IncomingLinkKind.authCallback,
      );
    });

    test('supabase verify endpoint is an auth link', () {
      expect(
        IncomingLinkClassifier.classify(
          'https://abc.supabase.co/auth/v1/verify?token=t&type=recovery',
        ),
        IncomingLinkKind.authCallback,
      );
    });

    test('post/story/join links are content links', () {
      expect(
        IncomingLinkClassifier.classify(
          'https://social-media-app-98f58.web.app/post/123',
        ),
        IncomingLinkKind.contentLink,
      );
    });

    test('ordinary shares stay shares', () {
      expect(
        IncomingLinkClassifier.classify('https://example.com/a'),
        IncomingLinkKind.other,
      );
      expect(
        IncomingLinkClassifier.classify('hello world'),
        IncomingLinkKind.other,
      );
      expect(IncomingLinkClassifier.classify(''), IncomingLinkKind.other);
    });
  });

  group('IncomingLinkClassifier.parseError / params', () {
    test('reads error from fragment', () {
      final uri = Uri.parse(
        'socialapp://login-callback#error=access_denied&error_code=otp_expired&error_description=Email+link+is+invalid',
      );
      final err = IncomingLinkClassifier.parseError(uri);
      expect(err, isNotNull);
      expect(err!.code, 'otp_expired');
    });

    test('reads error from query', () {
      final err = IncomingLinkClassifier.parseError(
        Uri.parse('socialapp://login-callback?error=server_error'),
      );
      expect(err?.code, 'server_error');
    });

    test('no error on a healthy recovery link', () {
      final uri = Uri.parse(
        'https://social-media-app-98f58.web.app/auth/recovery#token_hash=h&type=recovery',
      );
      expect(IncomingLinkClassifier.parseError(uri), isNull);
      final p = IncomingLinkClassifier.params(uri);
      expect(p['token_hash'], 'h');
      expect(p['type'], 'recovery');
    });
  });
}
