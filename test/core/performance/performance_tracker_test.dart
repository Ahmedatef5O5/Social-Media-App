import 'dart:async';
import 'dart:io' show SocketException;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:social_media_app/core/performance/interceptors/network_performance_interceptor.dart';
import 'package:social_media_app/core/performance/interceptors/startup_tracker.dart';
import 'package:social_media_app/core/performance/performance_metric.dart';
import 'package:social_media_app/core/performance/performance_queue.dart';
import 'package:social_media_app/core/performance/performance_tracker.dart';

/// Test double for the whole delivery side: controllable clock, scheduler,
/// transport and sign-in state. No timers, no network, no Supabase.
class Harness {
  Harness({int queueSize = 100, this.signedIn = true}) {
    tracker = PerformanceTracker(
      transport: (batch) async {
        calls.add(List<Map<String, dynamic>>.from(batch));
        if (failNext > 0) {
          failNext--;
          throw StateError('offline');
        }
        return nextResult ?? {'ok': true, 'accepted': batch.length};
      },
      sessionIdProvider: () => sessionId,
      appVersionProvider: () => '1.2.3',
      isSignedIn: () => this.signedIn,
      now: () => clock,
      scheduler: (delay, cb) {
        scheduled.add(delay);
        pending = cb;
        return () => pending = null;
      },
      onBreadcrumb: breadcrumbs.add,
      queue: PerformanceQueue(maxEntries: queueSize),
      enabled: true,
    );
  }

  late final PerformanceTracker tracker;
  DateTime clock = DateTime.utc(2026, 11, 14, 12);
  bool signedIn;
  String sessionId = 'b0180000-0000-4000-8000-0000000c0001';
  int failNext = 0;
  Object? nextResult;
  void Function()? pending;
  final List<Duration> scheduled = [];
  final List<String> breadcrumbs = [];
  final List<List<Map<String, dynamic>>> calls = [];

  void advance(Duration d) => clock = clock.add(d);

  void add(int n, {bool success = true, MetricCategory c = MetricCategory.apiRpc}) {
    for (var i = 0; i < n; i++) {
      tracker.record(
        category: c,
        operation: 'rpc:get_feed',
        duration: const Duration(milliseconds: 100),
        success: success,
        errorCode: success ? null : 'timeout',
      );
    }
  }

  Future<void> idle() => Future<void>.delayed(Duration.zero);
}

class FakeInner extends http.BaseClient {
  FakeInner({this.status = 200, this.error, this.latency});
  int status;
  Object? error;
  final Duration? latency;
  final List<Uri> requested = [];
  DateTime Function()? clockAdvance;
  void Function(Duration)? onSend;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requested.add(request.url);
    if (latency != null) onSend?.call(latency!);
    if (error != null) throw error!;
    return http.StreamedResponse(const Stream<List<int>>.empty(), status);
  }
}

void main() {
  group('sanitisers (privacy contract)', () {
    test('operation names lose ids, e-mails, queries and illegal characters', () {
      expect(sanitizeOperationName('RPC:Get_Feed'), 'rpc:get_feed');
      expect(
        sanitizeOperationName('rest:posts/6f1c2b1e-9d3a-4b8e-8f6a-1c2d3e4f5a6b'),
        'rest:posts/id',
      );
      expect(sanitizeOperationName('user@example.com'), 'user_example.com');
      expect(sanitizeOperationName('rest:posts?select=*&id=eq.12345'), 'rest:posts');
      expect(sanitizeOperationName('chat:send 1234567'), 'chat:send_n');
      expect(sanitizeOperationName('   '), 'unknown');
      expect(sanitizeOperationName('x' * 200).length, 80);
    });

    test('operation names always satisfy the server regexp', () {
      final re = RegExp(r'^[a-z0-9_.:/-]{1,80}$');
      for (final raw in ['Ünï/çödé', '../../etc/passwd', 'a b\nc', '😀', 'ok-1_2.3:4/5']) {
        expect(re.hasMatch(sanitizeOperationName(raw)), isTrue);
      }
    });

    test('error codes are short machine codes, never free text', () {
      expect(sanitizeErrorCode(null), isNull);
      expect(sanitizeErrorCode('  '), isNull);
      expect(sanitizeErrorCode('http_503'), 'http_503');
      expect(sanitizeErrorCode('connection refused by 10.0.0.1!'), 'connection_refused_by_10.0.0.1_');
      expect(sanitizeErrorCode('x' * 100)!.length, 64);
    });

    test('toJson carries no user id and bounds the duration', () {
      final m = PerformanceMetric(
        category: MetricCategory.upload,
        operationName: 'cloudinary:image',
        durationMs: 9999999,
        isSuccess: false,
        errorCode: 'timeout',
        recordedAt: DateTime.utc(2026, 1, 1),
        sessionId: 's',
        appVersion: '1.0.0',
      );
      final j = m.toJson();
      expect(j['duration_ms'], 600000);
      expect(j['metric_category'], 'upload');
      expect(j.containsKey('user_id'), isFalse);
      expect(j['recorded_at'], '2026-01-01T00:00:00.000Z');
    });
  });

  group('span timing', () {
    test('a trace records the elapsed time measured by the injected clock', () {
      final h = Harness();
      final trace = h.tracker.startTrace('cloudinary:image', MetricCategory.upload);
      h.advance(const Duration(milliseconds: 250));
      trace.stop();
      final m = h.tracker.queue.snapshot.single;
      expect(m.durationMs, 250);
      expect(m.isSuccess, isTrue);
      expect(m.category, MetricCategory.upload);
      expect(m.appVersion, '1.2.3');
      expect(m.sessionId, 'b0180000-0000-4000-8000-0000000c0001');
    });

    test('stop() is idempotent: only the first call counts', () {
      final h = Harness();
      final trace = h.tracker.startTrace('x', MetricCategory.apiRpc);
      h.advance(const Duration(milliseconds: 10));
      trace.stop();
      h.advance(const Duration(seconds: 5));
      trace.stop(success: false, errorCode: 'timeout');
      expect(h.tracker.queue.length, 1);
      expect(h.tracker.queue.snapshot.single.durationMs, 10);
      expect(h.tracker.queue.snapshot.single.isSuccess, isTrue);
    });

    test('cancel() records nothing', () {
      final h = Harness();
      final trace = h.tracker.startTrace('x', MetricCategory.apiRpc);
      trace.cancel();
      trace.stop();
      expect(h.tracker.queue.isEmpty, isTrue);
    });

    test('a failed stop() without a code is recorded as "unknown"', () {
      final h = Harness();
      h.tracker.startTrace('x', MetricCategory.apiRpc).stop(success: false);
      expect(h.tracker.queue.snapshot.single.errorCode, 'unknown');
      expect(h.tracker.queue.snapshot.single.isFailure, isTrue);
    });

    test('user-cancelled operations are NEVER recorded', () {
      final h = Harness();
      h.tracker
          .startTrace('cloudinary:image', MetricCategory.upload)
          .stop(success: false, errorCode: MetricErrorCodes.userCancelled);
      expect(h.tracker.queue.isEmpty, isTrue);
    });

    test('traceAsync records success, and failure + rethrow without leaking the message', () async {
      final h = Harness();
      final v = await h.tracker.traceAsync('rpc:a', MetricCategory.apiRpc, () async {
        h.advance(const Duration(milliseconds: 40));
        return 7;
      });
      expect(v, 7);
      await expectLater(
        h.tracker.traceAsync<void>('rpc:b', MetricCategory.apiRpc, () async {
          h.advance(const Duration(milliseconds: 60));
          throw TimeoutException('secret token abc');
        }),
        throwsA(isA<TimeoutException>()),
      );
      final items = h.tracker.queue.snapshot;
      expect(items[0].durationMs, 40);
      expect(items[1].durationMs, 60);
      expect(items[1].errorCode, 'timeout');
      expect(items[1].toJson().toString().contains('secret'), isFalse);
    });

    test('the telemetry RPCs themselves are never measured', () {
      final h = Harness();
      for (final op in ['rpc:log_performance_batch', 'log_performance_batch', 'rpc:session_heartbeat', 'rpc:incident_report_batch']) {
        h.tracker.record(category: MetricCategory.apiRpc, operation: op, duration: const Duration(milliseconds: 5), success: true);
      }
      expect(h.tracker.queue.isEmpty, isTrue);
    });

    test('a disabled tracker records and schedules nothing', () {
      final h = Harness();
      h.tracker.setEnabled(false);
      h.add(3);
      expect(h.tracker.queue.isEmpty, isTrue);
      expect(h.scheduled, isEmpty);
    });

    test('failures and slow calls leave a PII-free breadcrumb; fast successes do not', () {
      final h = Harness();
      h.add(1); // fast success
      expect(h.breadcrumbs, isEmpty);
      h.add(1, success: false);
      h.tracker.record(category: MetricCategory.apiRpc, operation: 'rpc:slow', duration: const Duration(seconds: 4), success: true);
      expect(h.breadcrumbs.length, 2);
      expect(h.breadcrumbs[0], contains('failed timeout'));
      expect(h.breadcrumbs[1], contains('slow 4000ms'));
    });
  });

  group('batch buffering and flushing', () {
    test('first sample schedules a 30 s flush; below the threshold nothing is sent', () async {
      final h = Harness();
      h.add(3);
      await h.idle();
      expect(h.scheduled, [PerformanceTracker.flushInterval]);
      expect(h.calls, isEmpty);
      expect(h.tracker.queue.length, 3);
    });

    test('the scheduled callback flushes the buffer', () async {
      final h = Harness();
      h.add(3);
      h.pending!();
      await h.idle();
      expect(h.calls.length, 1);
      expect(h.calls.single.length, 3);
      expect(h.tracker.queue.isEmpty, isTrue);
    });

    test('reaching the threshold (20) flushes immediately', () async {
      final h = Harness();
      h.add(PerformanceTracker.flushThreshold);
      await h.idle();
      expect(h.calls.length, 1);
      expect(h.calls.single.length, 20);
    });

    test('large buffers are sent in batches of at most 50', () async {
      final h = Harness();
      h.signedIn = false;
      h.add(70);
      h.signedIn = true;
      await h.tracker.flush();
      expect(h.calls.map((c) => c.length).toList(), [50, 20]);
      expect(h.tracker.queue.isEmpty, isTrue);
    });

    test('a flush() right after a finished (signed-out) flush starts a fresh run', () async {
      final h = Harness(signedIn: false);
      h.add(3);
      await h.tracker.flush();          // nothing sent: signed out
      h.signedIn = true;
      final f = h.tracker.flush();      // same microtask turn: must NOT join the old run
      await f;
      expect(h.calls.length, 1);
      expect(h.calls.single.length, 3);
    });

    test('samples recorded before the session existed get the id at flush time', () async {
      final h = Harness();
      h.sessionId = '';
      h.add(2);
      expect(h.tracker.queue.snapshot.first.sessionId, '');
      h.sessionId = 'b0180000-0000-4000-8000-0000000c0009';
      await h.tracker.flush();
      expect(h.calls.single.map((m) => m['session_id']).toSet(), {'b0180000-0000-4000-8000-0000000c0009'});
    });

    test('samples that still have no session id at flush time are dropped, not sent', () async {
      final h = Harness();
      h.sessionId = '';
      h.add(3);
      await h.tracker.flush();
      expect(h.calls, isEmpty);
      expect(h.tracker.queue.isEmpty, isTrue);
    });

    test('flush() with no pending work does not call the server', () async {
      final h = Harness();
      await h.tracker.flush();
      expect(h.calls, isEmpty);
    });

    test('concurrent flush() calls share one run', () async {
      final h = Harness();
      h.add(5);
      await Future.wait([h.tracker.flush(), h.tracker.flush(), h.tracker.flush()]);
      expect(h.calls.length, 1);
    });

    test('while signed out nothing is sent and samples are kept', () async {
      final h = Harness(signedIn: false);
      h.add(5);
      await h.tracker.flush();
      expect(h.calls, isEmpty);
      expect(h.tracker.queue.length, 5);
      expect(h.scheduled.length, greaterThan(0));
      h.signedIn = true;
      await h.tracker.flush();
      expect(h.calls.single.length, 5);
    });

    test('wire format matches the server contract', () async {
      final h = Harness();
      h.add(1);
      await h.tracker.flush();
      final item = h.calls.single.single;
      expect(item.keys.toSet(), {
        'session_id', 'metric_category', 'operation_name', 'duration_ms',
        'is_success', 'app_version', 'recorded_at',
      });
      expect(item['metric_category'], 'api_rpc');
      expect(item['is_success'], isTrue);
    });
  });

  group('offline behaviour', () {
    test('a failed delivery re-queues the batch in order and backs off', () async {
      final h = Harness();
      for (var i = 0; i < 5; i++) {
        h.tracker.record(category: MetricCategory.apiRpc, operation: 'rpc:op$i', duration: Duration(milliseconds: i + 1), success: true);
      }
      h.failNext = 1;
      await h.tracker.flush();
      expect(h.tracker.queue.length, 5);
      expect(h.tracker.queue.snapshot.map((m) => m.operationName).toList(),
          ['rpc:op0', 'rpc:op1', 'rpc:op2', 'rpc:op3', 'rpc:op4']);
      expect(h.scheduled.last, const Duration(minutes: 1)); // 30 s * 2

      await h.tracker.flush(); // back online
      expect(h.tracker.queue.isEmpty, isTrue);
      expect(h.calls.last.map((m) => m['operation_name']).toList(),
          ['rpc:op0', 'rpc:op1', 'rpc:op2', 'rpc:op3', 'rpc:op4']);
      expect(h.tracker.currentBackoff, PerformanceTracker.flushInterval);
    });

    test('back-off doubles and is capped at 5 minutes', () async {
      final h = Harness();
      h.add(1);
      h.failNext = 99;
      final delays = <Duration>[];
      for (var i = 0; i < 6; i++) {
        await h.tracker.flush();
        delays.add(h.scheduled.last);
        h.pending = null; // let the next failure schedule again
      }
      expect(delays.first, const Duration(minutes: 1));
      expect(delays[1], const Duration(minutes: 2));
      expect(delays[2], const Duration(minutes: 4));
      expect(delays.last, PerformanceTracker.maxBackoff);
    });

    test('a batch rejected by the server (ok:false) is dropped, not retried forever', () async {
      final h = Harness();
      h.nextResult = {'ok': false, 'code': 'VALIDATION'};
      h.add(4);
      await h.tracker.flush();
      expect(h.tracker.queue.isEmpty, isTrue);
      expect(h.calls.length, 1);
    });

    test('a long outage keeps memory bounded and keeps the failures', () async {
      final h = Harness(signedIn: false);
      h.add(100); // fills the queue with successes
      expect(h.tracker.queue.length, 100);
      h.add(40);  // more successes: suppressed
      expect(h.tracker.queue.length, 100);
      expect(h.tracker.queue.droppedCount, 40);
      h.add(5, success: false);  // failures evict the oldest successes
      expect(h.tracker.queue.length, 100);
      expect(h.tracker.queue.snapshot.where((m) => m.isFailure).length, 5);
    });
  });

  group('PerformanceQueue suppression policy', () {
    PerformanceMetric m(bool ok, [int i = 0]) => PerformanceMetric(
      category: MetricCategory.apiRpc, operationName: 'op$i', durationMs: 1, isSuccess: ok,
      errorCode: ok ? null : 'timeout', recordedAt: DateTime.utc(2026), sessionId: 's', appVersion: 'v');

    test('below capacity everything is accepted', () {
      final q = PerformanceQueue(maxEntries: 3);
      expect(q.add(m(true)), EnqueueResult.accepted);
      expect(q.add(m(false)), EnqueueResult.accepted);
      expect(q.length, 2);
    });

    test('at capacity: success suppressed, failure evicts the OLDEST success', () {
      final q = PerformanceQueue(maxEntries: 3)
        ..add(m(true, 1))..add(m(true, 2))..add(m(true, 3));
      expect(q.add(m(true, 4)), EnqueueResult.suppressed);
      expect(q.add(m(false, 5)), EnqueueResult.acceptedEvictingSuccess);
      expect(q.snapshot.map((x) => x.operationName).toList(), ['op2', 'op3', 'op5']);
      expect(q.droppedCount, 2);
    });

    test('at capacity with only failures: even a failure is suppressed', () {
      final q = PerformanceQueue(maxEntries: 2)..add(m(false, 1))..add(m(false, 2));
      expect(q.add(m(false, 3)), EnqueueResult.suppressed);
      expect(q.snapshot.map((x) => x.operationName).toList(), ['op1', 'op2']);
    });

    test('requeueFront keeps order and, when full, keeps the NEWEST of the batch', () {
      final q = PerformanceQueue(maxEntries: 4)..add(m(true, 9));
      q.requeueFront([m(true, 1), m(true, 2), m(true, 3), m(true, 4), m(true, 5)]);
      expect(q.snapshot.map((x) => x.operationName).toList(), ['op3', 'op4', 'op5', 'op9']);
      expect(q.droppedCount, 2);
    });

    test('takeBatch removes from the front', () {
      final q = PerformanceQueue()..add(m(true, 1))..add(m(true, 2))..add(m(true, 3));
      expect(q.takeBatch(2).map((x) => x.operationName).toList(), ['op1', 'op2']);
      expect(q.length, 1);
    });
  });

  group('PerformanceHttpClient (Supabase interceptor)', () {
    test('operation names are low-cardinality and never contain query strings', () {
      String n(String u) => operationNameForSupabaseUrl(Uri.parse(u));
      expect(n('https://x.supabase.co/rest/v1/rpc/get_feed?limit=20'), 'rpc:get_feed');
      expect(n('https://x.supabase.co/rest/v1/posts?select=*&id=eq.7'), 'rest:posts');
      expect(n('https://x.supabase.co/auth/v1/token?grant_type=password'), 'auth:token');
      expect(n('https://x.supabase.co/storage/v1/object/avatars/me.png'), 'storage:object');
      expect(n('https://x.supabase.co/functions/v1/send-push'), 'fn:send-push');
      expect(n('https://x.supabase.co/'), 'http:other');
    });

    Future<Harness> call(FakeInner inner, String url) async {
      final h = Harness();
      final client = PerformanceHttpClient(inner, tracker: h.tracker, now: () => h.clock);
      inner.onSend = h.advance;
      try {
        await client.send(http.Request('GET', Uri.parse(url)));
      } catch (_) {}
      return h;
    }

    test('200 -> success with the measured latency', () async {
      final h = await call(FakeInner(latency: const Duration(milliseconds: 180)), 'https://x.supabase.co/rest/v1/rpc/get_feed');
      final m = h.tracker.queue.snapshot.single;
      expect(m.operationName, 'rpc:get_feed');
      expect(m.durationMs, 180);
      expect(m.isSuccess, isTrue);
      expect(m.errorCode, isNull);
    });

    test('404 is a SUCCESS for reliability but keeps its code', () async {
      final h = await call(FakeInner(status: 404), 'https://x.supabase.co/rest/v1/posts');
      final m = h.tracker.queue.snapshot.single;
      expect(m.isSuccess, isTrue);
      expect(m.errorCode, 'http_404');
    });

    test('503 is a failure', () async {
      final h = await call(FakeInner(status: 503), 'https://x.supabase.co/rest/v1/rpc/get_chats');
      final m = h.tracker.queue.snapshot.single;
      expect(m.isFailure, isTrue);
      expect(m.errorCode, 'http_503');
    });

    test('timeouts and connection errors are failures and are rethrown', () async {
      final inner = FakeInner(error: TimeoutException('t'));
      final h = Harness();
      final client = PerformanceHttpClient(inner, tracker: h.tracker, now: () => h.clock);
      await expectLater(client.send(http.Request('GET', Uri.parse('https://x.supabase.co/rest/v1/posts'))), throwsA(isA<TimeoutException>()));
      expect(h.tracker.queue.snapshot.single.errorCode, 'timeout');

      inner.error = const SocketException('down');
      await expectLater(client.send(http.Request('GET', Uri.parse('https://x.supabase.co/rest/v1/posts'))), throwsA(isA<SocketException>()));
      expect(h.tracker.queue.snapshot.last.errorCode, 'network');
      expect(h.tracker.queue.snapshot.last.isFailure, isTrue);
    });

    test('the telemetry RPCs are passed through but never recorded (no feedback loop)', () async {
      for (final rpc in ['log_performance_batch', 'session_heartbeat', 'incident_report_batch']) {
        final inner = FakeInner();
        final h = await call(inner, 'https://x.supabase.co/rest/v1/rpc/$rpc');
        expect(inner.requested.length, 1);
        expect(h.tracker.queue.isEmpty, isTrue);
      }
    });

    test('the request URL (with query) never reaches the recorded metric', () async {
      final h = await call(FakeInner(), 'https://x.supabase.co/rest/v1/profiles?email=eq.victim@example.com');
      expect(h.tracker.queue.snapshot.single.toJson().toString().contains('victim'), isFalse);
    });
  });

  group('StartupTracker', () {
    test('records main() -> first frame once, via the post-frame hook', () {
      final scheduled = <void Function()>[];
      final watches = <_FakeStopwatch>[];
      final t = StartupTracker(
        scheduler: scheduled.add,
        stopwatch: () { final w = _FakeStopwatch(); watches.add(w); return w; },
      );
      final samples = <StartupSample>[];
      t.onMeasured = samples.add;

      t.begin();
      t.begin(); // idempotent
      watches.single.elapsedValue = const Duration(milliseconds: 1840);
      t.attachFirstFrame();
      t.attachFirstFrame(); // second attach schedules a second callback...
      for (final cb in scheduled) { cb(); }
      expect(samples.length, 1); // ...but only one sample is emitted
      expect(samples.single.kind, StartupKind.cold);
      expect(samples.single.milliseconds, 1840);
      expect(t.lastCold!.milliseconds, 1840);
    });

    test('attachFirstFrame without begin() does nothing', () {
      var called = false;
      final t = StartupTracker(scheduler: (cb) => called = true);
      t.attachFirstFrame();
      expect(called, isFalse);
    });

    test('measureNextFrame emits a warm sample', () {
      final scheduled = <void Function()>[];
      final t = StartupTracker(scheduler: scheduled.add, stopwatch: () => _FakeStopwatch()..elapsedValue = const Duration(milliseconds: 420));
      final samples = <StartupSample>[];
      t.onMeasured = samples.add;
      t.measureNextFrame(StartupKind.warm);
      scheduled.single();
      expect(samples.single.kind, StartupKind.warm);
      expect(samples.single.milliseconds, 420);
    });

    test('a throwing listener never breaks startup', () {
      final scheduled = <void Function()>[];
      final t = StartupTracker(scheduler: scheduled.add);
      t.onMeasured = (_) => throw StateError('boom');
      t.begin();
      t.attachFirstFrame();
      scheduled.single(); // must not throw
    });
  });
}

class _FakeStopwatch implements Stopwatch {
  Duration elapsedValue = Duration.zero;
  bool _running = false;
  @override void start() => _running = true;
  @override void stop() => _running = false;
  @override void reset() => elapsedValue = Duration.zero;
  @override Duration get elapsed => elapsedValue;
  @override int get elapsedMicroseconds => elapsedValue.inMicroseconds;
  @override int get elapsedMilliseconds => elapsedValue.inMilliseconds;
  @override int get elapsedTicks => elapsedValue.inMicroseconds;
  @override int get frequency => 1000000;
  @override bool get isRunning => _running;
}
