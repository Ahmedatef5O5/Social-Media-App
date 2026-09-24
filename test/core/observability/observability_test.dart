import 'package:flutter_test/flutter_test.dart';
import 'package:social_media_app/core/observability/crash_reporter.dart';
import 'package:social_media_app/core/observability/error_category.dart';
import 'package:social_media_app/core/observability/observability.dart';

/// PRIORITY: P1.
///
/// The buffering behaviour here is load-bearing: `main.dart` installs
/// `FlutterError.onError` before Firebase exists. If the buffer silently
/// dropped those early reports, the single most valuable crash bucket —
/// "crashes during startup" — would be permanently invisible, and nobody
/// would ever notice, because the symptom is an EMPTY dashboard.
void main() {
  late RecordingCrashReporter reporter;

  setUp(() {
    Observability.resetForTest();
    reporter = RecordingCrashReporter();
  });

  Future<void> attach() => obs.attachReporter(
    reporter,
    environment: 'test',
    appVersion: '1.0.0',
    buildNumber: '2',
  );

  group('startup buffering', () {
    test(
      'errors recorded before a reporter exists are flushed on attach',
      () async {
        await obs.recordError(
          StateError('early boom'),
          StackTrace.current,
          category: ErrorCategory.fatalCrash,
          feature: 'bootstrap',
          fatal: true,
        );

        expect(reporter.errors, isEmpty, reason: 'not attached yet');

        await attach();

        expect(reporter.errors, hasLength(1));
        expect(reporter.errors.single.fatal, isTrue);
        expect(reporter.errors.single.category, ErrorCategory.fatalCrash);
      },
    );

    test('breadcrumbs and custom keys are replayed too', () async {
      await obs.breadcrumb('supabase init started', feature: 'bootstrap');
      await obs.setContext('cold_start', true);

      await attach();

      expect(reporter.logs, contains('[bootstrap] supabase init started'));
      expect(reporter.customKeys['cold_start'], true);
    });

    test('attach stamps environment, version and build number', () async {
      await attach();

      expect(reporter.customKeys['environment'], 'test');
      expect(reporter.customKeys['app_version'], '1.0.0');
      expect(reporter.customKeys['build_number'], '2');
    });

    test('the buffer is bounded so a crash loop before init cannot grow '
        'unbounded in memory', () async {
      for (var i = 0; i < 500; i++) {
        await obs.breadcrumb('spam $i');
      }
      await attach();
      expect(reporter.logs.length, lessThanOrEqualTo(64));
    });
  });

  group('routing by category', () {
    test(
      'a network error produces a breadcrumb but NO Crashlytics issue',
      () async {
        await attach();

        await obs.recordError(
          Exception('SocketException: failed'),
          StackTrace.current,
          feature: 'feed',
          operation: 'fetchPosts',
        );

        expect(reporter.errors, isEmpty);
        expect(reporter.logs.any((l) => l.contains('network')), isTrue);
      },
    );

    test('an expected business error produces nothing at all', () async {
      await attach();

      await obs.recordError(
        Exception('no rows'),
        null,
        category: ErrorCategory.businessExpected,
      );

      expect(reporter.errors, isEmpty);
      expect(reporter.logs, isEmpty);
    });

    test('an unclassified error is auto-classified and reported', () async {
      await attach();

      await obs.recordError(StateError('boom'), StackTrace.current);

      expect(reporter.errors.single.category, ErrorCategory.handledException);
      expect(reporter.errors.single.fatal, isFalse);
    });

    test('feature, operation and the current context ride along with the '
        'report, which is what makes an issue diagnosable', () async {
      await attach();
      await obs.setScreen('ChatDetailsView');

      await obs.recordError(
        StateError('boom'),
        StackTrace.current,
        feature: 'single_chat',
        operation: 'sendMessage',
      );

      final info = reporter.errors.single.information.join('|');
      expect(info, contains('feature: single_chat'));
      expect(info, contains('operation: sendMessage'));
      expect(info, contains('screen: ChatDetailsView'));
    });
  });

  group('user identity is never stored raw', () {
    test(
      'the Supabase uuid is hashed before it reaches the reporter',
      () async {
        await attach();
        const userId = '4f9b3f0a-1111-2222-3333-444455556666';

        await obs.setSessionUser(userId);

        expect(reporter.userIdentifier, isNot(contains(userId)));
        expect(reporter.userIdentifier, hasLength(12));
        expect(reporter.customKeys['session_state'], 'authenticated');
      },
    );

    test('the same uuid always hashes to the same identifier, so crashes '
        'can still be grouped per account', () {
      expect(Observability.hashUserId('abc'), Observability.hashUserId('abc'));
      expect(
        Observability.hashUserId('abc'),
        isNot(Observability.hashUserId('abd')),
      );
    });

    test('signing out clears the identifier', () async {
      await attach();
      await obs.setSessionUser('abc');
      await obs.setSessionUser(null);

      expect(reporter.userIdentifier, '');
      expect(reporter.customKeys['session_state'], 'anonymous');
    });
  });

  group('trace', () {
    test('a successful fast operation leaves a breadcrumb and a duration '
        'key, but no issue', () async {
      await attach();

      final result = await obs.trace(
        'feed_load',
        () async => 42,
        feature: 'feed',
      );

      expect(result, 42);
      expect(reporter.errors, isEmpty);
      expect(reporter.customKeys.containsKey('last_feed_load_ms'), isTrue);
      expect(reporter.logs.any((l) => l.contains('feed_load ok')), isTrue);
    });

    test('a failing operation reports the error and rethrows, so callers '
        'keep their existing error handling', () async {
      await attach();

      await expectLater(
        obs.trace('feed_load', () async => throw StateError('boom')),
        throwsStateError,
      );

      expect(reporter.errors, hasLength(1));
      expect(reporter.errors.single.reason, contains('failed after'));
    });

    test('a slow-but-successful operation raises its own issue', () async {
      await attach();

      await obs.trace(
        'slow_thing',
        () async => Future<void>.delayed(const Duration(milliseconds: 30)),
        slowAfter: const Duration(milliseconds: 1),
      );

      expect(reporter.errors, hasLength(1));
      expect(reporter.errors.single.reason, 'slow operation');
      expect(reporter.errors.single.error, isA<SlowOperationException>());
    });
  });

  test('a reporter that throws can never take the app down with it', () async {
    await obs.attachReporter(
      _ExplodingReporter(),
      environment: 'test',
      appVersion: '1.0.0',
      buildNumber: '2',
    );

    await expectLater(
      obs.recordError(StateError('boom'), StackTrace.current),
      completes,
    );
  });
}

class _ExplodingReporter implements CrashReporter {
  @override
  Future<void> log(String message) async => throw StateError('sink down');

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    required ErrorCategory category,
    String? reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  }) async => throw StateError('sink down');

  @override
  Future<void> setCollectionEnabled(bool enabled) async =>
      throw StateError('sink down');

  @override
  Future<void> setCustomKey(String key, Object value) async =>
      throw StateError('sink down');

  @override
  Future<void> setUserIdentifier(String identifier) async =>
      throw StateError('sink down');
}
