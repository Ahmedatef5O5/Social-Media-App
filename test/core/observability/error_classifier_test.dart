import 'package:flutter_test/flutter_test.dart';
import 'package:social_media_app/core/errors/exceptions.dart';
import 'package:social_media_app/core/observability/error_category.dart';
import 'package:social_media_app/core/supabase/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// PRIORITY: P1 — core logic.
///
/// Classification decides what reaches Crashlytics. Get it wrong in one
/// direction and the dashboard fills with "user was on the metro" noise
/// until nobody reads it; get it wrong in the other and a real data-loss
/// bug is invisible. Both failure modes are silent in production, which is
/// exactly why they need a test.
void main() {
  group('policy table', () {
    test('only fatalCrash is fatal', () {
      final fatal = ErrorCategory.values.where((c) => c.isFatal).toList();
      expect(fatal, [ErrorCategory.fatalCrash]);
    });

    test('network and businessExpected never reach Crashlytics', () {
      expect(ErrorCategory.network.shouldReportToCrashlytics, isFalse);
      expect(ErrorCategory.businessExpected.shouldReportToCrashlytics, isFalse);
    });

    test('every other category does reach Crashlytics', () {
      const silent = {ErrorCategory.network, ErrorCategory.businessExpected};
      for (final category in ErrorCategory.values) {
        if (silent.contains(category)) continue;
        expect(
          category.shouldReportToCrashlytics,
          isTrue,
          reason: '${category.key} should be reported',
        );
      }
    });
  });

  group('ErrorClassifier.classify', () {
    test('the app-wide "no-internet" sentinel is connectivity, not a bug', () {
      expect(
        ErrorClassifier.classify(Exception('no-internet')),
        ErrorCategory.network,
      );
    });

    test('socket / host-lookup / timeout failures are connectivity', () {
      expect(
        ErrorClassifier.classify(Exception('SocketException: failed')),
        ErrorCategory.network,
      );
      expect(
        ErrorClassifier.classify(Exception('Failed host lookup: supabase.co')),
        ErrorCategory.network,
      );
      expect(
        ErrorClassifier.classify(Exception('Connection Timeout')),
        ErrorCategory.network,
      );
    });

    test(
      'a wrong password is an expected business outcome, not an incident',
      () {
        expect(
          ErrorClassifier.classify(
            const AuthException(
              'Invalid login credentials',
              code: 'invalid_credentials',
            ),
          ),
          ErrorCategory.businessExpected,
        );
      },
    );

    test('an unexpected auth failure IS an incident', () {
      expect(
        ErrorClassifier.classify(
          const AuthException(
            'refresh_token_not_found',
            code: 'refresh_token_not_found',
          ),
        ),
        ErrorCategory.authentication,
      );
    });

    test('UnauthenticatedException is an auth incident — reaching it means '
        'something called a signed-in-only path while signed out', () {
      expect(
        ErrorClassifier.classify(UnauthenticatedException()),
        ErrorCategory.authentication,
      );
    });

    test('PGRST116 (single() matched no rows) is expected, other PostgREST '
        'codes are database incidents', () {
      expect(
        ErrorClassifier.classify(
          const PostgrestException(message: 'no rows', code: 'PGRST116'),
        ),
        ErrorCategory.businessExpected,
      );
      expect(
        ErrorClassifier.classify(
          const PostgrestException(message: 'denied', code: '42501'),
        ),
        ErrorCategory.database,
      );
    });

    test('StorageException maps to media upload', () {
      expect(
        ErrorClassifier.classify(StorageException('quota exceeded')),
        ErrorCategory.mediaUpload,
      );
    });

    test('a cancelled upload is the user changing their mind', () {
      expect(
        ErrorClassifier.classify(const UploadCanceledException()),
        ErrorCategory.businessExpected,
      );
    });

    test('deserialization failures are their own category — these are the '
        'ones that silently poison the Hive snapshot caches', () {
      expect(
        ErrorClassifier.classify(const FormatException('bad json')),
        ErrorCategory.parsing,
      );
      expect(
        ErrorClassifier.classify(
          Exception("type 'Null' is not a subtype of type 'String'"),
        ),
        ErrorCategory.parsing,
      );
    });

    test('Hive box failures are cache incidents', () {
      expect(
        ErrorClassifier.classify(Exception('HiveError: Box not found')),
        ErrorCategory.cache,
      );
    });

    test('anything unrecognised falls back to handledException, which IS '
        'reported — an unknown error must never be silently dropped', () {
      final category = ErrorClassifier.classify(Exception('who knows'));
      expect(category, ErrorCategory.handledException);
      expect(category.shouldReportToCrashlytics, isTrue);
    });

    test('classify never throws, whatever it is handed', () {
      for (final input in <Object>[
        'a raw string',
        42,
        StateError('boom'),
        Object(),
      ]) {
        expect(() => ErrorClassifier.classify(input), returnsNormally);
      }
    });
  });
}
