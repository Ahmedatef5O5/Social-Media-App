import 'package:flutter_test/flutter_test.dart';
import 'package:social_media_app/core/errors/supabase_error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// [SupabaseErrorMapper] is the single entry point every non-auth
/// Cubit/Repository routes caught exceptions through before showing
/// anything to the user (per its own doc comment) — which makes it one of
/// the highest-value places in the app to have solid test coverage: a
/// wrong mapping here means a wrong (or blank) message on-screen for a
/// real error the user hit, everywhere in the app at once.
///
/// This is pure logic with no I/O, so every branch is unit-testable
/// exactly as written — no mocks needed.
void main() {
  group('SupabaseErrorMapper.toUserMessage', () {
    test('generic network errors map to the no-internet code', () {
      // NetworkErrorUtils.isNetworkError matches on the exception's
      // stringified text, so a plain Exception with the right wording is
      // enough to hit this branch — no need to construct a real
      // SocketException.
      expect(
        SupabaseErrorMapper.toUserMessage(Exception('SocketException: fail')),
        'no-internet',
      );
      expect(
        SupabaseErrorMapper.toUserMessage(Exception('Failed host lookup')),
        'no-internet',
      );
    });

    test(
      'AuthException is delegated to AuthExceptionHandler, not handled here',
      () {
        // SupabaseErrorMapper must not try to re-map auth errors itself —
        // it hands off to AuthExceptionHandler so auth copy has one
        // source of truth. We only assert the delegation happens and
        // produces AuthExceptionHandler's known output for this code,
        // not AuthExceptionHandler's own branch coverage (that's a
        // separate unit).
        final result = SupabaseErrorMapper.toUserMessage(
          const AuthException(
            'Invalid login credentials',
            code: 'invalid_credentials',
          ),
        );
        expect(result, 'Incorrect email or password. Please try again.');
      },
    );

    group('PostgrestException', () {
      test('503/500 or "service unavailable" → server-down message', () {
        expect(
          SupabaseErrorMapper.toUserMessage(
            const PostgrestException(message: 'x', code: '503'),
          ),
          'Our servers are currently on a break. We will be back shortly.',
        );
        expect(
          SupabaseErrorMapper.toUserMessage(
            const PostgrestException(message: 'x', code: '500'),
          ),
          'Our servers are currently on a break. We will be back shortly.',
        );
        expect(
          SupabaseErrorMapper.toUserMessage(
            const PostgrestException(message: 'Service Unavailable', code: ''),
          ),
          'Our servers are currently on a break. We will be back shortly.',
        );
      });

      test('42501 or "permission denied" → permission message', () {
        expect(
          SupabaseErrorMapper.toUserMessage(
            const PostgrestException(message: 'x', code: '42501'),
          ),
          "You don't have permission to do this.",
        );
        expect(
          SupabaseErrorMapper.toUserMessage(
            const PostgrestException(
              message: 'permission denied for table posts',
              code: '',
            ),
          ),
          "You don't have permission to do this.",
        );
      });

      test('08000/08006 or "connection" → connection message', () {
        expect(
          SupabaseErrorMapper.toUserMessage(
            const PostgrestException(message: 'x', code: '08006'),
          ),
          'Server is currently unavailable. Please try again shortly.',
        );
      });

      test('PGRST116 (.single()/.maybeSingle() mismatch) → not-found', () {
        expect(
          SupabaseErrorMapper.toUserMessage(
            const PostgrestException(message: 'x', code: 'PGRST116'),
          ),
          'The requested data was not found.',
        );
      });

      test('23xxx constraint violations → data-conflict message', () {
        expect(
          SupabaseErrorMapper.toUserMessage(
            const PostgrestException(message: 'x', code: '23505'),
          ),
          "This action couldn't be completed due to a data conflict.",
        );
      });

      test('unrecognized code → generic PostgREST fallback', () {
        expect(
          SupabaseErrorMapper.toUserMessage(
            const PostgrestException(message: 'x', code: 'XYZ999'),
          ),
          "We couldn't complete this request. Please try again.",
        );
      });

      test('null code does not crash — falls through to fallback', () {
        expect(
          SupabaseErrorMapper.toUserMessage(
            const PostgrestException(message: 'some odd error'),
          ),
          "We couldn't complete this request. Please try again.",
        );
      });
    });

    test('StorageException → generic upload/download message', () {
      expect(
        SupabaseErrorMapper.toUserMessage(StorageException('disk full')),
        'File upload/download failed. Please try again.',
      );
    });

    test('timeout errors → "taking too long" message', () {
      expect(
        SupabaseErrorMapper.toUserMessage(Exception('Connection Timeout')),
        'Server is taking too long to respond. Please try again.',
      );
    });

    test('anything unrecognized → generic fallback, never throws', () {
      expect(
        SupabaseErrorMapper.toUserMessage(Exception('totally unexpected')),
        'Something went wrong. Please try again.',
      );
      // Non-Exception objects are valid `Object` too — the mapper must
      // not assume it always receives an Exception.
      expect(
        SupabaseErrorMapper.toUserMessage('a raw string, not an exception'),
        'Something went wrong. Please try again.',
      );
    });

    test('DOCUMENTS EXISTING DEAD CODE: the second isNetworkError() check '
        '(source line ~30) can never run', () {
      // toUserMessage() checks NetworkErrorUtils.isNetworkError(e) at
      // the very top and returns 'no-internet' immediately if true.
      // A second, near-identical check further down returns a longer,
      // friendlier message ('No internet connection. Please check your
      // network.') — but since the first check already caught every
      // network error and returned early, that second branch is
      // unreachable dead code as written today.
      //
      // This test doesn't fix that (changing which message wins is a
      // product decision, not a test's call to make) — it exists so
      // that IF someone "cleans up" the duplicate check without
      // reading closely, this test fails and forces them to notice
      // the short 'no-internet' code is the one actually shown today,
      // not the friendlier sentence.
      final result = SupabaseErrorMapper.toUserMessage(
        Exception('SocketException'),
      );
      expect(result, 'no-internet');
      expect(
        result,
        isNot('No internet connection. Please check your network.'),
      );
    });
  });
}
