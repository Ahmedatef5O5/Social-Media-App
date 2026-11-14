import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:social_media_app/core/infrastructure/service_health_batcher.dart';
import 'package:social_media_app/core/infrastructure/service_health_coordinator.dart';
import 'package:social_media_app/core/infrastructure/service_health_sample.dart';
import 'package:social_media_app/core/observability/realtime_diagnostics.dart';

ServiceHealthSample _sample(
  HealthServiceKey key, {
  DateTime? at,
  int count = 1,
  int errors = 0,
}) => ServiceHealthSample(
  service: key,
  sampleCount: count,
  errorCount: errors,
  observedAt: at ?? DateTime.now(),
);

/// Coordinator wired to an in-memory sender; `sent` collects every JSON sample.
class _Rig {
  _Rig({DateTime Function()? clock}) {
    coordinator = ServiceHealthCoordinator(
      sender: (samples) async => sent.addAll(samples),
      clock: clock,
    );
  }

  final List<Map<String, dynamic>> sent = <Map<String, dynamic>>[];
  late final ServiceHealthCoordinator coordinator;

  ServiceHealthSample? pendingFor(HealthServiceKey key) {
    for (final s in coordinator.batcher.pending) {
      if (s.service == key) return s;
    }
    return null;
  }
}

void main() {
  group('ServiceHealthSample', () {
    test('uses the database wire names and omits null fields', () {
      final json = _sample(HealthServiceKey.aiGateway, count: 4, errors: 1).toJson();
      expect(json['service_key'], equals('ai_gateway'));
      expect(json['sample_count'], equals(4));
      expect(json['error_count'], equals(1));
      expect(json.containsKey('latency_p95_ms'), isFalse);
      expect(json.containsKey('degraded'), isFalse);
      expect(json.containsKey('last_error'), isFalse);
      expect(HealthServiceKey.supabaseRealtime.wireName, equals('supabase_realtime'));
      expect(HealthServiceKey.hiveCache.wireName, equals('hive_cache'));
    });

    test('reduces reason_code / provider to [a-z0-9_.:-]', () {
      final json = ServiceHealthSample(
        service: HealthServiceKey.cloudinary,
        sampleCount: 1,
        errorCount: 1,
        observedAt: DateTime.utc(2026),
        reasonCode: 'Upload FAILED!!',
        provider: 'Group Q/1',
      ).toJson();
      expect(json['reason_code'], equals('uploadfailed'));
      expect(json['provider'], equals('groupq1'));
    });

    test('scrubs e-mails, uuids, JWTs and long numbers from last_error', () {
      final json = ServiceHealthSample(
        service: HealthServiceKey.cloudinary,
        sampleCount: 1,
        errorCount: 1,
        observedAt: DateTime.utc(2026),
        lastError:
            'failed for leak@example.com id 123e4567-e89b-12d3-a456-426614174000 '
            'token=abc.def order 987654321 jwt eyJhbGciOi.eyJzdWIiOi.sig',
      ).toJson();
      final text = json['last_error'] as String;
      expect(text.contains('leak@example.com'), isFalse);
      expect(text.contains('123e4567'), isFalse);
      expect(text.contains('987654321'), isFalse);
      expect(text.contains('eyJhbGciOi'), isFalse);
      expect(text.length, lessThanOrEqualTo(160));
    });

    test('serialises observed_at as UTC ISO-8601', () {
      final json = ServiceHealthSample(
        service: HealthServiceKey.livekit,
        sampleCount: 1,
        errorCount: 0,
        observedAt: DateTime.utc(2026, 11, 14, 12, 30),
      ).toJson();
      expect(json['observed_at'], equals('2026-11-14T12:30:00.000Z'));
    });
  });

  group('ServiceHealthBatcher', () {
    test('evicts the OLDEST samples when the queue is full', () {
      final b = ServiceHealthBatcher(sender: (_) async {}, maxQueueSize: 3);
      for (var i = 0; i < 5; i++) {
        b.add(_sample(HealthServiceKey.cloudinary, count: i + 1));
      }
      expect(b.length, equals(3));
      expect(b.droppedCount, equals(2));
      expect(b.pending.first.sampleCount, equals(3)); // 1 and 2 were evicted
      expect(b.pending.last.sampleCount, equals(5));
    });

    test('ships in batches of at most maxBatchSize and empties the queue', () async {
      final calls = <int>[];
      final b = ServiceHealthBatcher(
        sender: (s) async => calls.add(s.length),
        maxQueueSize: 500,
        maxBatchSize: 50,
      );
      for (var i = 0; i < 125; i++) {
        b.add(_sample(HealthServiceKey.hiveCache));
      }
      await b.flush();
      expect(calls.length, equals(3));
      expect(calls[0], equals(50));
      expect(calls[1], equals(50));
      expect(calls[2], equals(25));
      expect(b.length, equals(0));
      expect(b.sentCount, equals(125));
    });

    test('a failed send keeps the samples, never throws, and is retried', () async {
      var fail = true;
      final received = <int>[];
      final b = ServiceHealthBatcher(
        sender: (s) async {
          if (fail) throw Exception('network down');
          received.add(s.length);
        },
      );
      b.add(_sample(HealthServiceKey.livekit));
      b.add(_sample(HealthServiceKey.livekit));
      await b.flush(); // must not throw
      expect(b.length, equals(2));
      expect(b.failedFlushCount, equals(1));
      fail = false;
      await b.flush();
      expect(b.length, equals(0));
      expect(received.length, equals(1));
      expect(received.first, equals(2));
    });

    test('offline: the whole queue is dropped and the sender is not called', () async {
      var called = false;
      final b = ServiceHealthBatcher(
        sender: (_) async => called = true,
        isOnline: () => false,
      );
      for (var i = 0; i < 4; i++) {
        b.add(_sample(HealthServiceKey.cloudinary));
      }
      await b.flush();
      expect(called, isFalse);
      expect(b.length, equals(0));
      expect(b.droppedCount, equals(4));
    });

    test('samples older than maxSampleAge are evicted before sending', () async {
      var now = DateTime.utc(2026, 11, 14, 12);
      final sentCounts = <int>[];
      final b = ServiceHealthBatcher(
        sender: (s) async => sentCounts.add(s.length),
        maxSampleAge: const Duration(minutes: 10),
        clock: () => now,
      );
      b.add(_sample(HealthServiceKey.cloudinary, at: now.subtract(const Duration(minutes: 11))));
      b.add(_sample(HealthServiceKey.cloudinary, at: now.subtract(const Duration(minutes: 2))));
      await b.flush();
      expect(sentCounts.length, equals(1));
      expect(sentCounts.first, equals(1));
      expect(b.droppedCount, equals(1));
    });

    test('a flush that is already running is not started twice', () async {
      final gate = Completer<void>();
      var calls = 0;
      final b = ServiceHealthBatcher(
        sender: (_) async {
          calls++;
          await gate.future;
        },
      );
      b.add(_sample(HealthServiceKey.cloudinary));
      final first = b.flush();
      final second = b.flush(); // returns immediately
      await second;
      gate.complete();
      await first;
      expect(calls, equals(1));
    });

    test('a failing beforeFlush hook does not block queued samples', () async {
      var sent = 0;
      final b = ServiceHealthBatcher(
        sender: (s) async => sent += s.length,
        beforeFlush: () => throw StateError('aggregator bug'),
      );
      b.add(_sample(HealthServiceKey.cloudinary));
      await b.flush();
      expect(sent, equals(1));
    });

    test('the periodic timer flushes by itself', () async {
      var sent = 0;
      final b = ServiceHealthBatcher(
        sender: (s) async => sent += s.length,
        flushInterval: const Duration(milliseconds: 20),
      );
      b.add(_sample(HealthServiceKey.cloudinary));
      b.start();
      expect(b.isRunning, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      b.stop();
      expect(b.isRunning, isFalse);
      expect(sent, equals(1));
    });
  });

  group('ServiceHealthCoordinator - aggregation', () {
    test('folds calls into one sample with counts and nearest-rank P95', () {
      final rig = _Rig();
      for (var ms = 1; ms <= 100; ms++) {
        rig.coordinator.reportCall(
          HealthServiceKey.cloudinary,
          success: ms != 50, // exactly one failure
          latency: Duration(milliseconds: ms),
          error: ms == 50 ? 'timeout' : null,
        );
      }
      rig.coordinator.drain();
      final s = rig.pendingFor(HealthServiceKey.cloudinary)!;
      expect(s.sampleCount, equals(100));
      expect(s.errorCount, equals(1));
      expect(s.latencyP95Ms, equals(95));
      expect(rig.coordinator.openWindowCount, equals(0)); // window was reset
      rig.coordinator.drain();
      expect(rig.coordinator.batcher.length, equals(1)); // nothing new
    });

    test('Cloudinary uploads map to success / failure samples', () {
      final rig = _Rig();
      rig.coordinator
        ..reportCloudinaryUpload(success: true, duration: const Duration(seconds: 2))
        ..reportCloudinaryUpload(
          success: false,
          duration: const Duration(seconds: 9),
          error: 'Upload failed for leak@example.com',
        );
      rig.coordinator.drain();
      final s = rig.pendingFor(HealthServiceKey.cloudinary)!;
      expect(s.sampleCount, equals(2));
      expect(s.errorCount, equals(1));
      expect(s.latencyP95Ms, equals(9000));
      expect(s.toJson()['reason_code'], equals('upload_failed'));
      expect((s.toJson()['last_error'] as String).contains('leak@example.com'), isFalse);
    });

    test('failures while offline are ignored, successes still count', () {
      final rig = _Rig();
      var online = false;
      rig.coordinator.isOnline = () => online;
      rig.coordinator.reportCall(HealthServiceKey.cloudinary, success: false, error: 'x');
      expect(rig.coordinator.openWindowCount, equals(0));
      online = true;
      rig.coordinator.reportCall(HealthServiceKey.cloudinary, success: false, error: 'x');
      rig.coordinator.reportCall(HealthServiceKey.cloudinary, success: true);
      rig.coordinator.drain();
      final s = rig.pendingFor(HealthServiceKey.cloudinary)!;
      expect(s.sampleCount, equals(2));
      expect(s.errorCount, equals(1));
    });

    test('setOnline(false) mutes failures until setOnline(true)', () {
      final rig = _Rig();
      rig.coordinator.setOnline(false);
      rig.coordinator.reportCall(HealthServiceKey.cloudinary, success: false, error: 'x');
      expect(rig.coordinator.openWindowCount, equals(0));
      rig.coordinator.setOnline(true);
      rig.coordinator.reportCall(HealthServiceKey.cloudinary, success: false, error: 'x');
      expect(rig.coordinator.openWindowCount, equals(1));
    });

    test('sampleRate 0 keeps a session out of the sample; 1 keeps it in', () {
      final out = _Rig();
      out.coordinator.start(sampleRate: 0);
      expect(out.coordinator.enabled, isFalse);
      expect(out.coordinator.batcher.isRunning, isFalse);
      out.coordinator.reportCall(HealthServiceKey.livekit, success: true);
      out.coordinator.drain();
      expect(out.coordinator.batcher.length, equals(0));

      final inn = _Rig();
      inn.coordinator.start(sampleRate: 1);
      expect(inn.coordinator.enabled, isTrue);
      expect(inn.coordinator.batcher.isRunning, isTrue);
      inn.coordinator.stop();
    });

    test('the kill switch stops all recording', () {
      final rig = _Rig();
      rig.coordinator.enabled = false;
      rig.coordinator.reportCall(HealthServiceKey.livekit, success: true);
      rig.coordinator.drain();
      expect(rig.coordinator.batcher.length, equals(0));
    });

    test('report* never throws, even with hostile input', () {
      final rig = _Rig();
      rig.coordinator.reportCall(
        HealthServiceKey.livekit,
        success: false,
        latency: const Duration(milliseconds: -5),
        error: Object(),
      );
      rig.coordinator.drain();
      expect(rig.pendingFor(HealthServiceKey.livekit)!.latencyP95Ms, isNull);
    });
  });

  group('ServiceHealthCoordinator - Realtime (passive via RealtimeDiagnostics)', () {
    late _Rig rig;

    setUp(() {
      RealtimeDiagnostics.resetForTest();
      rig = _Rig();
      rig.coordinator.attachRealtimeDiagnostics();
    });

    test('subscribe, error and reconnect transitions become samples', () {
      final d = RealtimeDiagnostics.instance;
      d.onChannelCreated('chat:secret-conversation-42', ownerUserId: 'user-1');
      d.onChannelSubscribed('chat:secret-conversation-42'); // subscribed
      d.onChannelError('chat:secret-conversation-42', Exception('boom'), null); // errored
      d.onChannelSubscribed('chat:secret-conversation-42'); // reconnected

      rig.coordinator.drain();
      final s = rig.pendingFor(HealthServiceKey.supabaseRealtime)!;
      expect(s.sampleCount, equals(3));
      expect(s.errorCount, equals(1));
      // 1 reconnect over the 30 s minimum window = 2 / min
      expect(s.reconnectsPerMin, closeTo(2.0, 0.001));
      expect(s.toJson()['reason_code'], equals('channel_error'));
    });

    test('topics and owners never reach the payload', () {
      final d = RealtimeDiagnostics.instance;
      d.onChannelCreated('chat:secret-conversation-42', ownerUserId: 'user-1');
      d.onChannelSubscribed('chat:secret-conversation-42');
      d.onChannelError('chat:secret-conversation-42', Exception('boom for user-1'), null);
      rig.coordinator.drain();
      final json = rig.pendingFor(HealthServiceKey.supabaseRealtime)!.toJson().toString();
      expect(json.contains('secret-conversation-42'), isFalse);
      expect(json.contains('user-1'), isFalse);
    });

    test('a throwing listener cannot break channel handling', () {
      RealtimeDiagnostics.instance.healthListener = (_) => throw StateError('bad');
      RealtimeDiagnostics.instance.onChannelCreated('t', ownerUserId: 'u');
      RealtimeDiagnostics.instance.onChannelSubscribed('t'); // must not throw
      expect(RealtimeDiagnostics.instance.activeCount, equals(1));
    });

    test('detaching removes the hook; sign-out reset keeps it attached', () {
      RealtimeDiagnostics.instance.reset();
      expect(RealtimeDiagnostics.instance.healthListener, isNotNull);
      rig.coordinator.detachRealtimeDiagnostics();
      expect(RealtimeDiagnostics.instance.healthListener, isNull);
    });

    test('idle but subscribed channels produce a healthy liveness sample', () {
      final d = RealtimeDiagnostics.instance;
      d.onChannelCreated('t', ownerUserId: 'u');
      d.onChannelSubscribed('t');
      rig.coordinator.drain(); // drains the 'subscribed' event
      final before = rig.coordinator.batcher.length;
      rig.coordinator.registerLivenessCheck(
        HealthServiceKey.supabaseRealtime,
        () => RealtimeDiagnostics.instance.active.any((c) => c.phase == ChannelPhase.subscribed),
      );
      rig.coordinator.drain(); // quiet window -> liveness fills it
      expect(rig.coordinator.batcher.length, equals(before + 1));
      expect(rig.coordinator.batcher.pending.last.errorCount, equals(0));
    });
  });

  group('ServiceHealthCoordinator - AI Gateway / LiveKit', () {
    test('degraded=true (provider fallback) is carried to the sample', () {
      final rig = _Rig();
      rig.coordinator.reportAiGateway(
        success: true,
        duration: const Duration(milliseconds: 900),
        degraded: true,
        provider: 'groq',
      );
      rig.coordinator.drain();
      final s = rig.pendingFor(HealthServiceKey.aiGateway)!;
      expect(s.degraded, isTrue);
      expect(s.errorCount, equals(0));
      expect(s.provider, equals('groq'));
    });

    test('the latest degraded value wins inside a window', () {
      final rig = _Rig();
      rig.coordinator
        ..reportAiGateway(success: true, duration: const Duration(milliseconds: 100), degraded: true)
        ..reportAiGateway(success: true, duration: const Duration(milliseconds: 100), degraded: false);
      rig.coordinator.drain();
      expect(rig.pendingFor(HealthServiceKey.aiGateway)!.degraded, isFalse);
    });

    test('quota / 4xx answers are healthy; transport failures are errors', () {
      final rig = _Rig();
      rig.coordinator
        ..reportAiGateway(success: false, duration: const Duration(milliseconds: 50), reason: 'user_quota_exceeded')
        ..reportAiGateway(success: false, duration: const Duration(milliseconds: 50), reason: 'global_quota_exceeded')
        ..reportAiGateway(success: false, duration: const Duration(milliseconds: 50), expectedFailure: true, error: 'HTTP 429')
        ..reportAiGateway(success: false, duration: const Duration(milliseconds: 3000), error: 'SocketException');
      rig.coordinator.drain();
      final s = rig.pendingFor(HealthServiceKey.aiGateway)!;
      expect(s.sampleCount, equals(4));
      expect(s.errorCount, equals(1));
    });

    test('LiveKit: token failures and connection drops count, user hang-ups do not', () {
      final rig = _Rig();
      rig.coordinator
        ..reportLiveKitToken(success: true, duration: const Duration(milliseconds: 300))
        ..reportLiveKitToken(success: false, duration: const Duration(seconds: 5), error: 'timeout')
        ..reportLiveKitConnectionEnded('connectionTimeout')
        ..reportLiveKitConnectionEnded('clientInitiated')
        ..reportLiveKitConnectionEnded('ParticipantRemoved')
        ..reportLiveKitConnectionEnded(null);
      rig.coordinator.drain();
      final s = rig.pendingFor(HealthServiceKey.livekit)!;
      expect(s.sampleCount, equals(4)); // ok token, failed token, drop, drop(null)
      expect(s.errorCount, equals(3));
    });
  });

  group('ServiceHealthCoordinator - Hive (passive via HiveCacheManager hooks)', () {
    test('box reset marks the cache degraded with a stable reason', () {
      final rig = _Rig();
      rig.coordinator
        ..reportHiveInit(success: true, duration: const Duration(milliseconds: 40))
        ..reportHiveBoxReset('media_cache');
      rig.coordinator.drain();
      final s = rig.pendingFor(HealthServiceKey.hiveCache)!;
      final json = s.toJson();
      expect(s.degraded, isTrue);
      expect(s.errorCount, equals(0)); // recovered, not failed
      expect(json['reason_code'], equals('box_reset'));
      expect(json['last_error'], equals('box recreated: media_cache'));
    });

    test('a failed init is an error sample', () {
      final rig = _Rig();
      rig.coordinator.reportHiveInit(
        success: false,
        duration: const Duration(milliseconds: 10),
        error: 'FileSystemException',
      );
      rig.coordinator.drain();
      final s = rig.pendingFor(HealthServiceKey.hiveCache)!;
      expect(s.errorCount, equals(1));
      expect(s.toJson()['reason_code'], equals('init_failed'));
    });

    test('a later clean window clears the degraded flag', () {
      final rig = _Rig();
      rig.coordinator.reportHiveBoxReset('media_cache');
      rig.coordinator.drain();
      rig.coordinator.registerLivenessCheck(HealthServiceKey.hiveCache, () => true);
      rig.coordinator.drain();
      expect(rig.coordinator.batcher.pending.last.degraded, isNull);
    });

    test('liveness: true = healthy sample, false = error sample, null = nothing', () {
      final rig = _Rig();
      bool? answer = true;
      rig.coordinator.registerLivenessCheck(HealthServiceKey.hiveCache, () => answer);
      rig.coordinator.drain();
      expect(rig.pendingFor(HealthServiceKey.hiveCache)!.errorCount, equals(0));

      answer = false;
      rig.coordinator.drain();
      expect(rig.coordinator.batcher.pending.last.errorCount, equals(1));

      answer = null;
      final before = rig.coordinator.batcher.length;
      rig.coordinator.drain();
      expect(rig.coordinator.batcher.length, equals(before));

      rig.coordinator.unregisterLivenessCheck(HealthServiceKey.hiveCache);
      answer = true;
      rig.coordinator.drain();
      expect(rig.coordinator.batcher.length, equals(before));
    });

    test('a liveness check that throws is ignored', () {
      final rig = _Rig();
      rig.coordinator.registerLivenessCheck(HealthServiceKey.hiveCache, () => throw StateError('x'));
      rig.coordinator.drain(); // must not throw
      expect(rig.coordinator.batcher.length, equals(0));
    });
  });

  group('ServiceHealthCoordinator - end to end', () {
    test('flushNow drains windows and ships only whitelisted keys', () async {
      final rig = _Rig();
      rig.coordinator
        ..reportCloudinaryUpload(success: true, duration: const Duration(seconds: 1))
        ..reportAiGateway(success: true, duration: const Duration(milliseconds: 400), degraded: true, provider: 'gemini');
      await rig.coordinator.flushNow();

      expect(rig.sent.length, equals(2));
      const allowed = <String>{
        'service_key', 'sample_count', 'error_count', 'observed_at',
        'latency_p95_ms', 'reconnects_per_min', 'degraded', 'reason_code',
        'provider', 'last_error',
      };
      for (final json in rig.sent) {
        for (final key in json.keys) {
          expect(allowed.contains(key), isTrue);
        }
      }
      expect(rig.coordinator.batcher.length, equals(0));
    });

    test('offline flush drops everything instead of queueing it forever', () async {
      RealtimeDiagnostics.resetForTest(); // singleton: isolate from earlier tests
      final rig = _Rig();
      rig.coordinator.start(isOnline: () => false);
      expect(rig.coordinator.isStarted, isTrue);
      rig.coordinator.stop();
      expect(rig.coordinator.isStarted, isFalse);
      rig.coordinator.reportCall(HealthServiceKey.livekit, success: true);
      rig.coordinator.batcher.isOnline = () => false;
      await rig.coordinator.flushNow();
      expect(rig.sent.length, equals(0));
      expect(rig.coordinator.batcher.length, equals(0));
      expect(rig.coordinator.batcher.droppedCount, equals(1));
    });
  });
}
