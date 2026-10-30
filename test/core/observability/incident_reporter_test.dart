import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_media_app/core/observability/composite_crash_reporter.dart';
import 'package:social_media_app/core/observability/crash_reporter.dart';
import 'package:social_media_app/core/observability/error_category.dart';
import 'package:social_media_app/core/observability/fingerprint_throttle.dart';
import 'package:social_media_app/core/observability/incident_reporter.dart';
import 'package:social_media_app/core/observability/observability.dart';
import 'package:social_media_app/core/observability/overflow_filter.dart';
import 'package:social_media_app/core/services/active_screen_tracker.dart';

/// PRIORITY: P1.
///
/// These tests pin the wire contract with `public.incident_report_batch`
/// (migration 014). If the payload drifts from it the server silently drops or
/// coerces data, and the Incident Center shows nothing: an empty dashboard
/// looks identical to a healthy app.
void main() {
  const allowedKeys = {
    'category',
    'severity',
    'title',
    'message',
    'stack_trace',
    'fingerprint',
    'platform',
    'app_version',
    'build_number',
    'os_version',
    'device_model',
    'locale',
    'session_id',
    'occurred_at',
    'context',
  };
  const serverCategories = {
    'crash',
    'error',
    'network',
    'auth',
    'realtime',
    'call',
    'upload',
    'performance',
    'other',
  };
  const serverSeverities = {'info', 'warning', 'error', 'fatal'};
  const serverPlatforms = {
    'android',
    'ios',
    'web',
    'windows',
    'macos',
    'linux',
    'other',
  };

  late DateTime clock;
  late List<List<Map<String, dynamic>>> sent;
  late List<_Scheduled> scheduled;
  String? uid;
  Object? transportError;

  IncidentReporter makeReporter() => IncidentReporter(
    transport: (reports) async {
      if (transportError != null) throw transportError!;
      sent.add(reports);
      return <String, dynamic>{'ok': true};
    },
    userIdProvider: () => uid,
    screenProvider: () => '/home-view',
    now: () => clock,
    scheduler: (delay, callback) {
      final entry = _Scheduled(delay, callback);
      scheduled.add(entry);
      return () => entry.cancelled = true;
    },
    sessionId: 'test-session',
    platform: 'android',
  );

  Future<void> report(
    IncidentReporter r,
    Object error, {
    ErrorCategory category = ErrorCategory.handledException,
    bool fatal = false,
    StackTrace? stack,
    Iterable<Object> information = const [],
  }) => r.recordError(
    error,
    stack,
    category: category,
    fatal: fatal,
    information: information,
  );

  setUp(() {
    clock = DateTime.utc(2026, 1, 1, 12);
    sent = [];
    scheduled = [];
    uid = 'user-1';
    transportError = null;
    Observability.resetForTest();
    OverflowFilter.resetForTest();
  });

  group('ErrorCategory.layoutOverflow', () {
    test('is non-fatal, reportable, and keyed layout_overflow', () {
      expect(ErrorCategory.layoutOverflow.key, 'layout_overflow');
      expect(ErrorCategory.layoutOverflow.policy, ReportingPolicy.nonFatal);
      expect(ErrorCategory.layoutOverflow.shouldReportToCrashlytics, isTrue);
      expect(ErrorCategory.layoutOverflow.isFatal, isFalse);
    });

    test('existing keys are unchanged', () {
      expect(ErrorCategory.fatalCrash.key, 'fatalCrash');
      expect(ErrorCategory.mediaUpload.key, 'mediaUpload');
    });
  });

  group('deduplication (60 s window, LRU of 100)', () {
    test('identical fingerprints inside 60 s are sent once', () async {
      final r = makeReporter();
      for (var i = 0; i < 3; i++) {
        await report(r, StateError('boom'));
      }
      expect(r.bufferedCount, 1);

      clock = clock.add(const Duration(seconds: 59));
      await report(r, StateError('boom'));
      expect(r.bufferedCount, 1, reason: 'still inside the window');
    });

    test(
      'after 60 s it is reported again and carries the suppressed count',
      () async {
        final r = makeReporter();
        for (var i = 0; i < 3; i++) {
          await report(r, StateError('boom'));
        }
        clock = clock.add(const Duration(seconds: 61));
        await report(r, StateError('boom'));

        expect(r.bufferedCount, 2);
        final context =
            r.bufferedPayloads.last['context'] as Map<String, dynamic>;
        expect(context['suppressed_since_last'], 2);
      },
    );

    test('numbers in the message do not split a fingerprint', () async {
      final r = makeReporter();
      await report(r, StateError('timed out after 5012 ms'));
      await report(r, StateError('timed out after 7340 ms'));
      expect(r.bufferedCount, 1);
    });

    test('different errors are independent', () async {
      final r = makeReporter();
      await report(r, StateError('a'));
      await report(r, StateError('b'));
      await report(r, ArgumentError('a'));
      expect(r.bufferedCount, 3);
    });

    test('LRU is capped at 100 and evicts the oldest fingerprint', () {
      final t = FingerprintThrottle(now: () => clock);
      expect(t.tryAcquire('fp-0'), 0);
      for (var i = 1; i <= 100; i++) {
        t.tryAcquire('fp-$i');
      }
      expect(t.length, 100);
      expect(t.contains('fp-0'), isFalse);
      expect(t.tryAcquire('fp-0'), 0, reason: 'evicted -> accepted again');
      expect(t.tryAcquire('fp-100'), isNull, reason: 'recent -> suppressed');
    });
  });

  group('batching & delivery', () {
    test(
      'first report schedules a 30 s flush; firing it sends the batch',
      () async {
        final r = makeReporter();
        await report(r, StateError('one'));

        expect(scheduled, hasLength(1));
        expect(scheduled.single.delay, const Duration(seconds: 30));
        expect(sent, isEmpty);

        scheduled.single.callback();
        await r.flush();

        expect(sent, hasLength(1));
        expect(sent.single, hasLength(1));
        expect(r.bufferedCount, 0);
      },
    );

    test('reaching 10 buffered reports flushes immediately', () async {
      final r = makeReporter();
      for (var i = 0; i < 10; i++) {
        final code = String.fromCharCode(97 + i); // a, b, c, d...
        await report(r, StateError('error_$code'));
      }
      await r.flush();

      expect(sent, hasLength(1));
      expect(sent.single, hasLength(10));
      expect(r.bufferedCount, 0);
    });

    test('a fatal report is flushed immediately', () async {
      final r = makeReporter();
      await report(
        r,
        StateError('fatal'),
        category: ErrorCategory.fatalCrash,
        fatal: true,
      );
      await r.flush();

      expect(sent.single.single['severity'], 'fatal');
      expect(sent.single.single['category'], 'crash');
    });

    test('batches never exceed the server limit of 20', () async {
      uid = null; // signed out: everything is held
      final r = makeReporter();
      for (var i = 0; i < 60; i++) {
        final c1 = String.fromCharCode(97 + (i ~/ 26));
        final c2 = String.fromCharCode(97 + (i % 26));
        await report(r, StateError('error_$c1$c2'));
      }
      expect(r.bufferedCount, IncidentReporter.maxBuffered);
      expect(sent, isEmpty);

      uid = 'user-1';
      await r.flush();

      expect(sent.map((b) => b.length).toList(), [20, 20, 10]);
      expect(r.bufferedCount, 0);
    });

    test('signed out: nothing is sent, reports wait for sign-in', () async {
      uid = null;
      final r = makeReporter();
      await report(r, StateError('early'));
      await r.flush();

      expect(sent, isEmpty);
      expect(r.bufferedCount, 1);

      uid = 'user-1';
      await r.flush();
      expect(sent, hasLength(1));
    });

    test('offline: failures are swallowed, retried, then dropped', () async {
      transportError = Exception('SocketException: offline');
      final r = makeReporter();
      await report(r, StateError('x'));

      for (var i = 0; i < IncidentReporter.maxAttempts; i++) {
        await r.flush(); // must complete normally every time
      }
      expect(sent, isEmpty);
      expect(r.bufferedCount, 0, reason: 'dropped after maxAttempts');
    });

    test('a transient failure keeps the report and recovers later', () async {
      transportError = Exception('timeout');
      final r = makeReporter();
      await report(r, StateError('x'));
      await r.flush();
      expect(r.bufferedCount, 1);

      transportError = null;
      await r.flush();
      expect(sent, hasLength(1));
      expect(r.bufferedCount, 0);
    });

    test('a server-side rejection (ok:false) is not retried', () async {
      final r = IncidentReporter(
        transport: (reports) async {
          sent.add(reports);
          return <String, dynamic>{'ok': false, 'code': 'VALIDATION'};
        },
        userIdProvider: () => uid,
        scheduler: (d, c) => () {},
      );
      await report(r, StateError('x'));
      await r.flush();
      await r.flush();

      expect(sent, hasLength(1));
      expect(r.bufferedCount, 0);
    });

    test(
      'disabling collection clears the buffer and stops recording',
      () async {
        final r = makeReporter();
        await report(r, StateError('x'));
        await r.setCollectionEnabled(false);
        expect(r.bufferedCount, 0);

        await report(r, StateError('y'));
        expect(r.bufferedCount, 0);
      },
    );

    test('RPC name matches migration 014', () {
      expect(IncidentReporter.rpcName, 'incident_report_batch');
    });
  });

  group('serialization matches incident_report_batch contract', () {
    test('every field is within the server enums and limits', () async {
      final r = makeReporter();
      await r.log('opened feed');
      await r.setCustomKey('network_online', true);
      await report(
        r,
        StateError('x' * 5000),
        category: ErrorCategory.database,
        information: const ['feature: feed', 'operation: fetchPosts'],
        stack: StackTrace.fromString(
          '#0      _FeedState.build (package:social_media_app/f/feed.dart:10:2)\n'
          '#1      State.setState (package:flutter/src/widgets/framework.dart:1:1)',
        ),
      );
      await report(
        r,
        StateError('layout'),
        category: ErrorCategory.layoutOverflow,
      );

      final payloads = r.bufferedPayloads;
      expect(payloads, hasLength(2));
      expect(payloads.length, lessThanOrEqualTo(IncidentReporter.maxBatchSize));

      for (final p in payloads) {
        expect(allowedKeys.containsAll(p.keys), isTrue, reason: '${p.keys}');
        expect(serverCategories, contains(p['category']));
        expect(serverSeverities, contains(p['severity']));
        expect(serverPlatforms, contains(p['platform']));

        final title = p['title'] as String;
        expect(title, isNotEmpty);
        expect(title.length, lessThanOrEqualTo(200));
        expect((p['message'] as String).length, lessThanOrEqualTo(2000));
        expect((p['fingerprint'] as String).length, inInclusiveRange(1, 128));
        expect(
          ((p['stack_trace'] ?? '') as String).length,
          lessThanOrEqualTo(8000),
        );
        expect((p['app_version'] as String).length, lessThanOrEqualTo(64));
        expect((p['build_number'] as String).length, lessThanOrEqualTo(32));
        expect((p['session_id'] as String).length, lessThanOrEqualTo(128));
        expect(p['context'], isA<Map<String, dynamic>>());

        final at = DateTime.parse(p['occurred_at'] as String);
        expect(at.isUtc, isTrue);
        expect(at, clock);
      }

      final first = payloads.first;
      expect(first['category'], 'error');
      expect(first['severity'], 'error');
      expect(
        first['stack_trace'],
        contains('package:social_media_app/f/feed.dart'),
      );
      final ctx = first['context'] as Map<String, dynamic>;
      expect(ctx['feature'], 'feed');
      expect(ctx['operation'], 'fetchPosts');
      expect(ctx['screen'], '/home-view');
      expect(ctx['network_online'], true);
      expect(ctx['breadcrumbs'], ['opened feed']);

      // Layout overflow falls back to `other` (not yet a server category).
      expect(payloads.last['category'], 'other');
      expect(payloads.last['severity'], 'warning');

      // The whole batch survives JSON encoding, under the 256 KiB server cap.
      final encoded = jsonEncode({'p_reports': payloads});
      expect(utf8.encode(encoded).length, lessThan(262144));
    });

    test('maps Flutter categories onto server categories', () async {
      final r = makeReporter();
      const expected = {
        ErrorCategory.fatalCrash: 'crash',
        ErrorCategory.authentication: 'auth',
        ErrorCategory.realtime: 'realtime',
        ErrorCategory.mediaUpload: 'upload',
        ErrorCategory.cache: 'error',
        ErrorCategory.parsing: 'error',
      };
      for (final entry in expected.entries) {
        await report(r, StateError(entry.key.key), category: entry.key);
      }
      expect(
        r.bufferedPayloads.map((p) => p['category']).toList(),
        expected.values.toList(),
      );
    });

    test('personal data is scrubbed from title, message and context', () async {
      final r = makeReporter();
      await report(
        r,
        Exception(
          'failed for jane.doe@example.com id '
          '123e4567-e89b-12d3-a456-426614174000 phone 201012345678 '
          'GET https://x.supabase.co/rest/v1/users?select=*&token=abc123 '
          'Authorization: Bearer eyJhbGciOi.eyJzdWIi.sig',
        ),
        information: const ['feature: auth'],
      );

      final json = jsonEncode(r.bufferedPayloads.single);
      expect(json, isNot(contains('jane.doe')));
      expect(json, isNot(contains('123e4567')));
      expect(json, isNot(contains('201012345678')));
      expect(json, isNot(contains('abc123')));
      expect(json, isNot(contains('eyJhbGciOi')));
      expect(json, isNot(contains('select=*')));
      expect(json, contains('https://x.supabase.co/rest/v1/users'));
    });

    test('no user id is ever placed in the payload', () async {
      final r = makeReporter();
      await r.setUserIdentifier('abc123hash');
      await report(r, StateError('x'));
      expect(jsonEncode(r.bufferedPayloads), isNot(contains('abc123hash')));
      expect(jsonEncode(r.bufferedPayloads), isNot(contains('user-1')));
    });
  });

  group('OverflowFilter', () {
    FlutterErrorDetails overflow({
      String side = 'right',
      String pixels = '14.5',
      String axis = 'horizontal',
      String extra = '',
      String? stackText,
    }) => FlutterErrorDetails(
      exception: FlutterError(
        'A RenderFlex overflowed by $pixels pixels on the $side.\n'
        'The overflowing RenderFlex has an orientation of Axis.$axis.\n'
        '$extra',
      ),
      stack: StackTrace.fromString(
        stackText ??
            '#0      RenderFlex.performLayout (package:flutter/src/rendering/flex.dart:1000:5)\n'
                '#1      RenderObject.layout (package:flutter/src/rendering/object.dart:2000:7)\n'
                '#2      _HomeViewState.build (package:social_media_app/features/home/home_view.dart:123:45)\n'
                '#3      StatelessElement.build (package:flutter/src/widgets/framework.dart:5000:12)\n'
                '#4      Other.build (package:social_media_app/features/x/other.dart:9:1)',
      ),
    );

    String expectedFingerprint(String screen, String direction, String frame) =>
        sha256
            .convert(utf8.encode('layout_overflow$screen$direction$frame'))
            .toString()
            .substring(0, 32);

    const homeFrame =
        '_HomeViewState.build@package:social_media_app/features/home/home_view.dart';

    test('extracts pixels, direction, screen and the topmost USER frame', () {
      final info = OverflowFilter.tryParse(overflow(), screen: '/home-view');

      expect(info, isNotNull);
      expect(info!.pixels, 14.5);
      expect(info.direction, OverflowDirection.horizontal);
      expect(info.screen, '/home-view');
      expect(info.topUserFrame, homeFrame);
      expect(info.topUserFrameLine, 123);
    });

    test('uses ActiveScreenTracker.currentRoute by default', () {
      ActiveScreenTracker.setCurrentRoute('/chat-details-view');
      final info = OverflowFilter.tryParse(overflow());
      expect(info!.screen, '/chat-details-view');
    });

    test('bottom/top mean vertical, left/right mean horizontal', () {
      expect(
        OverflowFilter.tryParse(
          overflow(side: 'bottom'),
          screen: 's',
        )!.direction,
        OverflowDirection.vertical,
      );
      expect(
        OverflowFilter.tryParse(overflow(side: 'top'), screen: 's')!.direction,
        OverflowDirection.vertical,
      );
      expect(
        OverflowFilter.tryParse(overflow(side: 'left'), screen: 's')!.direction,
        OverflowDirection.horizontal,
      );
    });

    test(
      'fingerprint = sha256(layout_overflow+screen+direction+frame)[0:32]',
      () {
        final info = OverflowFilter.tryParse(overflow(), screen: '/home-view')!;
        expect(info.fingerprint, hasLength(32));
        expect(
          info.fingerprint,
          expectedFingerprint('/home-view', 'horizontal', homeFrame),
        );
      },
    );

    test('fingerprint ignores the pixel delta but not the direction', () {
      final a = OverflowFilter.tryParse(overflow(pixels: '14.5'), screen: 's')!;
      final b =
          OverflowFilter.tryParse(overflow(pixels: '200.0'), screen: 's')!;
      final c =
          OverflowFilter.tryParse(
            overflow(side: 'bottom', axis: 'vertical'),
            screen: 's',
          )!;
      expect(a.fingerprint, b.fingerprint);
      expect(a.fingerprint, isNot(c.fingerprint));
    });

    test('skips framework frames; with no user frame the token is unknown', () {
      final info =
          OverflowFilter.tryParse(
            overflow(
              stackText:
                  '#0      RenderFlex.performLayout (package:flutter/src/rendering/flex.dart:1:1)\n'
                  '#1      dart:async/zone.dart',
            ),
            screen: 's',
          )!;
      expect(info.topUserFrame, 'unknown');
    });

    test('falls back to the widget-creator file path in debug text', () {
      final info =
          OverflowFilter.tryParse(
            overflow(
              extra:
                  'The relevant error-causing widget was: Row '
                  'Row:file:///D:/flutt_projcts/social_media_app/lib/features/home/row.dart:55:14',
              stackText:
                  '#0      RenderFlex.performLayout (package:flutter/a.dart:1:1)',
            ),
            screen: 's',
          )!;
      expect(
        info.topUserFrame,
        'package:social_media_app/features/home/row.dart',
      );
      expect(info.topUserFrameLine, 55);
    });

    test('non-overflow errors are not matched', () {
      final details = FlutterErrorDetails(exception: StateError('nope'));
      expect(OverflowFilter.isOverflow(details), isFalse);
      expect(OverflowFilter.tryParse(details), isNull);
    });

    test('ZERO personal data: widget text in the message never leaks', () {
      final details = overflow(
        extra: 'Text("secret@mail.com") ?token=abc https://x.co/p?email=a@b.co',
      );
      final info =
          OverflowFilter.tryParse(details, screen: '/home-view?uid=42')!;

      final everything =
          '${info.summary}|${info.title}|${jsonEncode(info.toContext())}|'
          '${info.fingerprint}|${info.screen}';
      expect(everything, isNot(contains('secret')));
      expect(everything, isNot(contains('mail.com')));
      expect(everything, isNot(contains('token')));
      expect(everything, isNot(contains('uid=42')));
      expect(everything, isNot(contains('?')));
    });

    test(
      'tryRecord reports once, non-fatal, then swallows duplicates',
      () async {
        final recording = RecordingCrashReporter();
        await obs.attachReporter(
          recording,
          environment: 'test',
          appVersion: '1.0.0',
          buildNumber: '1',
        );
        final throttle = FingerprintThrottle(now: () => clock);

        expect(
          OverflowFilter.tryRecord(overflow(), throttle: throttle),
          isTrue,
        );
        expect(
          OverflowFilter.tryRecord(overflow(), throttle: throttle),
          isTrue,
        );
        expect(
          OverflowFilter.tryRecord(overflow(pixels: '99'), throttle: throttle),
          isTrue,
        );
        await pumpEventQueue();

        expect(recording.errors, hasLength(1));
        final e = recording.errors.single;
        expect(e.category, ErrorCategory.layoutOverflow);
        expect(e.fatal, isFalse);
        expect(e.error, isA<LayoutOverflowException>());
      },
    );

    test(
      'tryRecord returns false for other errors and records nothing',
      () async {
        final recording = RecordingCrashReporter();
        await obs.attachReporter(
          recording,
          environment: 'test',
          appVersion: '1.0.0',
          buildNumber: '1',
        );
        final handled = OverflowFilter.tryRecord(
          FlutterErrorDetails(exception: StateError('real crash')),
        );
        await pumpEventQueue();

        expect(handled, isFalse);
        expect(recording.errors, isEmpty);
      },
    );

    test('an overflow becomes a sanitised incident payload', () async {
      final info =
          OverflowFilter.tryParse(
            overflow(extra: 'Text("secret@mail.com")'),
            screen: '/home-view',
          )!;
      final r = makeReporter();
      await r.recordError(
        LayoutOverflowException(info),
        StackTrace.current,
        category: ErrorCategory.layoutOverflow,
      );

      final p = r.bufferedPayloads.single;
      expect(p['fingerprint'], info.fingerprint);
      expect(p['severity'], 'warning');
      expect(p['category'], 'other');
      expect(p.containsKey('stack_trace'), isFalse);
      final ctx = p['context'] as Map<String, dynamic>;
      expect(ctx['kind'], 'layout_overflow');
      expect(ctx['direction'], 'horizontal');
      expect(ctx['pixels'], 14.5);
      expect(jsonEncode(p), isNot(contains('secret')));
    });
  });

  group('CompositeCrashReporter', () {
    test('fans out every call to every delegate', () async {
      final a = RecordingCrashReporter();
      final b = RecordingCrashReporter();
      final composite = CompositeCrashReporter([a, b]);

      await composite.recordError(
        StateError('x'),
        null,
        category: ErrorCategory.database,
        reason: 'why',
        fatal: true,
      );
      await composite.log('hello');
      await composite.setCustomKey('k', 1);
      await composite.setUserIdentifier('u');
      await composite.setCollectionEnabled(false);

      for (final r in [a, b]) {
        expect(r.errors.single.category, ErrorCategory.database);
        expect(r.errors.single.fatal, isTrue);
        expect(r.logs, ['hello']);
        expect(r.customKeys['k'], 1);
        expect(r.userIdentifier, 'u');
        expect(r.collectionEnabled, isFalse);
      }
    });

    test('a throwing delegate does not stop the others', () async {
      final good = RecordingCrashReporter();
      final composite = CompositeCrashReporter([_ThrowingReporter(), good]);

      await composite.recordError(
        StateError('x'),
        null,
        category: ErrorCategory.parsing,
      );
      await composite.log('still delivered');

      expect(good.errors, hasLength(1));
      expect(good.logs, ['still delivered']);
    });
  });
}

class _Scheduled {
  _Scheduled(this.delay, this.callback);

  final Duration delay;
  final void Function() callback;
  bool cancelled = false;
}

class _ThrowingReporter extends NoopCrashReporter {
  const _ThrowingReporter();

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    required ErrorCategory category,
    String? reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  }) => throw StateError('sink down');

  @override
  Future<void> log(String message) async => throw StateError('sink down');
}
