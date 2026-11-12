import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:social_media_app/core/analytics/analytics_queue.dart';

import 'analytics_test_helpers.dart';

AnalyticsQueue buildQueue({
  required InMemoryAnalyticsStorage storage,
  required FakeSender sender,
  FakeScheduler? scheduler,
  FakeClock? clock,
  int maxBatch = 20,
  int maxQueue = 200,
  bool flushWhenFull = false,
}) => AnalyticsQueue(
  storage: storage,
  sender: sender.call,
  scheduler: scheduler ?? FakeScheduler(),
  now: (clock ?? FakeClock()).call,
  random: ZeroRandom(),
  maxBatchSize: maxBatch,
  maxQueueSize: maxQueue,
  flushWhenBatchFull: flushWhenFull,
);

void main() {
  group('batching and flush intervals', () {
    test('sends at most 20 events per request', () async {
      final sender = FakeSender();
      final q = buildQueue(storage: InMemoryAnalyticsStorage(), sender: sender);
      for (var i = 0; i < 45; i++) {
        await q.enqueue(makeEvent(i));
      }
      final status = await q.flush();
      expect(status, AnalyticsFlushStatus.drained);
      expect(sender.batches.map((b) => b.length).toList(), <int>[20, 20, 5]);
      expect(q.length, 0);
      expect(sender.sentIds.first, 'evt-0000');
      expect(sender.sentIds.last, 'evt-0044');
    });

    test('flush on an empty queue does not call the network', () async {
      final sender = FakeSender();
      final q = buildQueue(storage: InMemoryAnalyticsStorage(), sender: sender);
      expect(await q.flush(), AnalyticsFlushStatus.empty);
      expect(sender.calls, 0);
    });

    test('periodic timer flushes every 30 seconds, not before', () async {
      final sender = FakeSender();
      final scheduler = FakeScheduler();
      final q = buildQueue(
        storage: InMemoryAnalyticsStorage(),
        sender: sender,
        scheduler: scheduler,
      )..start();
      await q.enqueue(makeEvent(1));

      scheduler.advance(const Duration(seconds: 29));
      await Future<void>.delayed(Duration.zero);
      expect(sender.calls, 0, reason: 'nothing before the interval');

      scheduler.advance(const Duration(seconds: 1));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(sender.calls, 1);
      expect(q.length, 0);
    });

    test('the timer stays quiet while the queue is empty', () async {
      final sender = FakeSender();
      final scheduler = FakeScheduler();
      buildQueue(
        storage: InMemoryAnalyticsStorage(),
        sender: sender,
        scheduler: scheduler,
      ).start();
      scheduler.advance(const Duration(minutes: 5));
      await Future<void>.delayed(Duration.zero);
      expect(sender.calls, 0);
    });

    test('start() is idempotent and stop() cancels the timer', () async {
      final scheduler = FakeScheduler();
      final q = buildQueue(
        storage: InMemoryAnalyticsStorage(),
        sender: FakeSender(),
        scheduler: scheduler,
      );
      q
        ..start()
        ..start();
      expect(scheduler.activeTimers, 1);
      q.stop();
      expect(scheduler.activeTimers, 0);
      expect(q.isStarted, false);
    });

    test('a full batch triggers an immediate flush when enabled', () async {
      final sender = FakeSender();
      final q = buildQueue(
        storage: InMemoryAnalyticsStorage(),
        sender: sender,
        flushWhenFull: true,
      );
      for (var i = 0; i < 20; i++) {
        await q.enqueue(makeEvent(i));
      }
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(sender.calls, 1);
      expect(q.length, 0);
    });

    test('concurrent flushes share one run (no duplicate sends)', () async {
      final sender = FakeSender()..gate = Completer<void>();
      final q = buildQueue(storage: InMemoryAnalyticsStorage(), sender: sender);
      await q.enqueue(makeEvent(1));
      final a = q.flush();
      final b = q.flush();
      sender.gate!.complete();
      await Future.wait(<Future<AnalyticsFlushStatus>>[a, b]);
      expect(sender.calls, 1);
    });

    test('events enqueued while a batch is in flight are delivered once', () async {
      final sender = FakeSender()..gate = Completer<void>();
      final q = buildQueue(storage: InMemoryAnalyticsStorage(), sender: sender);
      await q.enqueue(makeEvent(1));
      final run = q.flush();
      await Future<void>.delayed(Duration.zero);
      await q.enqueue(makeEvent(2));
      sender.gate!.complete();
      await run;
      // Delivered exactly once, in order, by the same flush run.
      expect(sender.sentIds, <String>['evt-0001', 'evt-0002']);
      expect(q.length, 0);
    });
  });

  group('offline persistence and recovery after restart', () {
    test('events are persisted before enqueue returns', () async {
      final storage = InMemoryAnalyticsStorage();
      final q = buildQueue(storage: storage, sender: FakeSender());
      await q.enqueue(makeEvent(1));
      expect(storage.data['analytics.queue.v1'], isNotNull);
      expect(storage.data['analytics.queue.v1'], contains('evt-0001'));
    });

    test('a new queue on the same storage restores pending events in order', () async {
      final storage = InMemoryAnalyticsStorage();
      final offline = FakeSender()..fallback = AnalyticsSendOutcome.retry;
      final first = buildQueue(storage: storage, sender: offline);
      for (var i = 0; i < 5; i++) {
        await first.enqueue(makeEvent(i));
      }
      expect(await first.flush(), AnalyticsFlushStatus.failed);
      expect(first.length, 5, reason: 'nothing may be lost while offline');

      // --- simulated app restart: brand-new objects, same disk ---
      final online = FakeSender();
      final second = buildQueue(storage: storage, sender: online);
      await second.restore();
      expect(second.length, 5);
      expect(await second.flush(), AnalyticsFlushStatus.drained);
      expect(online.sentIds, <String>[
        'evt-0000', 'evt-0001', 'evt-0002', 'evt-0003', 'evt-0004',
      ]);
      await second.settle();

      final third = buildQueue(storage: storage, sender: FakeSender());
      await third.restore();
      expect(third.length, 0, reason: 'delivered events must not come back');
    });

    test('restore repairs corrupt storage instead of throwing', () async {
      final storage = InMemoryAnalyticsStorage(<String, String>{
        'analytics.queue.v1': '{not json',
      });
      final q = buildQueue(storage: storage, sender: FakeSender());
      await q.restore();
      expect(q.length, 0);
      await q.enqueue(makeEvent(1));
      expect(q.length, 1);
    });

    test('restore skips malformed entries but keeps the valid ones', () async {
      final good = makeEvent(7).toJson();
      final storage = InMemoryAnalyticsStorage(<String, String>{
        'analytics.queue.v1':
            '{"v":1,"events":[${_json(good)},{"event_name":"nope"},42,null]}',
      });
      final q = buildQueue(storage: storage, sender: FakeSender());
      await q.restore();
      expect(q.snapshot.map((e) => e.eventId).toList(), <String>['evt-0007']);
    });
  });

  group('de-duplication and size limit', () {
    test('the same event id is queued once', () async {
      final q = buildQueue(
        storage: InMemoryAnalyticsStorage(),
        sender: FakeSender(),
      );
      await q.enqueue(makeEvent(1));
      await q.enqueue(makeEvent(1));
      await q.enqueue(makeEvent(1));
      expect(q.length, 1);
    });

    test('an id can be queued again after it was delivered', () async {
      final q = buildQueue(
        storage: InMemoryAnalyticsStorage(),
        sender: FakeSender(),
      );
      await q.enqueue(makeEvent(1));
      await q.flush();
      await q.enqueue(makeEvent(1));
      expect(q.length, 1);
    });

    test('never holds more than 200 events; the OLDEST are dropped first', () async {
      final q = buildQueue(
        storage: InMemoryAnalyticsStorage(),
        sender: FakeSender(),
      );
      for (var i = 0; i < 230; i++) {
        await q.enqueue(makeEvent(i));
      }
      expect(q.length, 200);
      expect(q.droppedOverflow, 30);
      expect(q.snapshot.first.eventId, 'evt-0030');
      expect(q.snapshot.last.eventId, 'evt-0229');
    });

    test('the cap holds exactly at the boundary', () async {
      final q = buildQueue(
        storage: InMemoryAnalyticsStorage(),
        sender: FakeSender(),
      );
      for (var i = 0; i < 200; i++) {
        await q.enqueue(makeEvent(i));
      }
      expect(q.length, 200);
      expect(q.droppedOverflow, 0);
      await q.enqueue(makeEvent(200));
      expect(q.length, 200);
      expect(q.droppedOverflow, 1);
      expect(q.snapshot.first.eventId, 'evt-0001');
    });

    test('an oversized persisted queue is trimmed on restore', () async {
      final storage = InMemoryAnalyticsStorage();
      final big = buildQueue(storage: storage, sender: FakeSender(), maxQueue: 300);
      for (var i = 0; i < 260; i++) {
        await big.enqueue(makeEvent(i));
      }
      final small = buildQueue(storage: storage, sender: FakeSender());
      await small.restore();
      expect(small.length, 200);
      expect(small.snapshot.first.eventId, 'evt-0060');
    });

    test('a dropped (overflow) id may be re-queued later', () async {
      final q = buildQueue(
        storage: InMemoryAnalyticsStorage(),
        sender: FakeSender(),
        maxQueue: 20,
      );
      for (var i = 0; i < 21; i++) {
        await q.enqueue(makeEvent(i));
      }
      expect(q.snapshot.any((e) => e.eventId == 'evt-0000'), false);
      await q.enqueue(makeEvent(0));
      expect(q.snapshot.last.eventId, 'evt-0000');
    });
  });

  group('retry with exponential back-off', () {
    test('back-off doubles per failure and is capped at 5 minutes', () {
      final q = buildQueue(
        storage: InMemoryAnalyticsStorage(),
        sender: FakeSender(),
      );
      expect(q.backoffFor(1), const Duration(seconds: 2));
      expect(q.backoffFor(2), const Duration(seconds: 4));
      expect(q.backoffFor(3), const Duration(seconds: 8));
      expect(q.backoffFor(4), const Duration(seconds: 16));
      expect(q.backoffFor(8), const Duration(seconds: 256));
      expect(q.backoffFor(9), const Duration(minutes: 5));
      expect(q.backoffFor(50), const Duration(minutes: 5));
    });

    test('jitter stays within +20% and never exceeds the cap', () {
      final q = AnalyticsQueue(
        storage: InMemoryAnalyticsStorage(),
        sender: FakeSender().call,
      );
      for (var failures = 1; failures < 30; failures++) {
        final d = q.backoffFor(failures);
        final base = const Duration(seconds: 2).inMilliseconds * (1 << (failures - 1 > 20 ? 20 : failures - 1));
        final capped = base > 300000 ? 300000 : base;
        expect(d.inMilliseconds, greaterThanOrEqualTo(capped));
        expect(d.inMilliseconds, lessThanOrEqualTo(300000));
        expect(d.inMilliseconds, lessThanOrEqualTo((capped * 1.2).round() > 300000 ? 300000 : (capped * 1.2).round()));
      }
    });

    test('a failed flush keeps events and schedules the next attempt', () async {
      final clock = FakeClock();
      final sender = FakeSender()..fallback = AnalyticsSendOutcome.retry;
      final q = buildQueue(
        storage: InMemoryAnalyticsStorage(),
        sender: sender,
        clock: clock,
      );
      await q.enqueue(makeEvent(1));
      expect(await q.flush(), AnalyticsFlushStatus.failed);
      expect(q.length, 1);
      expect(q.consecutiveFailures, 1);
      expect(q.nextAttemptAt, clock.current.add(const Duration(seconds: 2)));
    });

    test('flush is refused inside the back-off window and works after it', () async {
      final clock = FakeClock();
      final sender = FakeSender()..script.add(AnalyticsSendOutcome.retry);
      final q = buildQueue(
        storage: InMemoryAnalyticsStorage(),
        sender: sender,
        clock: clock,
      );
      await q.enqueue(makeEvent(1));
      await q.flush(); // fails, next attempt in 2 s
      expect(sender.calls, 1);

      clock.advance(const Duration(seconds: 1));
      expect(await q.flush(), AnalyticsFlushStatus.backingOff);
      expect(sender.calls, 1, reason: 'no request while backing off');

      clock.advance(const Duration(seconds: 1));
      expect(await q.flush(), AnalyticsFlushStatus.drained);
      expect(sender.calls, 2);
      expect(q.consecutiveFailures, 0, reason: 'success resets the counter');
      expect(q.nextAttemptAt, isNull);
    });

    test('consecutive failures lengthen the delay', () async {
      final clock = FakeClock();
      final sender = FakeSender()..fallback = AnalyticsSendOutcome.retry;
      final q = buildQueue(
        storage: InMemoryAnalyticsStorage(),
        sender: sender,
        clock: clock,
      );
      await q.enqueue(makeEvent(1));
      final waits = <Duration>[];
      for (var i = 0; i < 4; i++) {
        final before = clock.current;
        await q.flush(force: true);
        waits.add(q.nextAttemptAt!.difference(before));
      }
      expect(waits, <Duration>[
        const Duration(seconds: 2),
        const Duration(seconds: 4),
        const Duration(seconds: 8),
        const Duration(seconds: 16),
      ]);
    });

    test('force bypasses the window (app going to background)', () async {
      final clock = FakeClock();
      final sender = FakeSender()..script.add(AnalyticsSendOutcome.retry);
      final q = buildQueue(
        storage: InMemoryAnalyticsStorage(),
        sender: sender,
        clock: clock,
      );
      await q.enqueue(makeEvent(1));
      await q.flush();
      expect(await q.flush(force: true), AnalyticsFlushStatus.drained);
    });

    test('a sender that throws is treated as a retryable failure', () async {
      final sender = FakeSender()..throwOnSend = true;
      final q = buildQueue(storage: InMemoryAnalyticsStorage(), sender: sender);
      await q.enqueue(makeEvent(1));
      expect(await q.flush(), AnalyticsFlushStatus.failed);
      expect(q.length, 1);
    });

    test('a failure on the 2nd batch keeps only the undelivered events', () async {
      final sender = FakeSender()
        ..script.addAll(<AnalyticsSendOutcome>[
          AnalyticsSendOutcome.success,
          AnalyticsSendOutcome.retry,
        ]);
      final q = buildQueue(storage: InMemoryAnalyticsStorage(), sender: sender);
      for (var i = 0; i < 30; i++) {
        await q.enqueue(makeEvent(i));
      }
      expect(await q.flush(), AnalyticsFlushStatus.failed);
      expect(q.length, 10);
      expect(q.snapshot.first.eventId, 'evt-0020');
    });

    test('a permanent rejection drops the poison batch and continues', () async {
      final sender = FakeSender()
        ..script.add(AnalyticsSendOutcome.drop); // first batch is poison
      final q = buildQueue(storage: InMemoryAnalyticsStorage(), sender: sender);
      for (var i = 0; i < 25; i++) {
        await q.enqueue(makeEvent(i));
      }
      expect(await q.flush(), AnalyticsFlushStatus.drained);
      expect(q.droppedPermanent, 20);
      expect(sender.sentIds.length, 25);
      expect(q.length, 0);
      expect(q.consecutiveFailures, 0);
    });
  });

  group('clear', () {
    test('clear empties memory and storage', () async {
      final storage = InMemoryAnalyticsStorage();
      final q = buildQueue(storage: storage, sender: FakeSender());
      await q.enqueue(makeEvent(1));
      await q.clear();
      expect(q.length, 0);
      final again = buildQueue(storage: storage, sender: FakeSender());
      await again.restore();
      expect(again.length, 0);
    });
  });
}

String _json(Map<String, dynamic> m) => jsonEncode(m);
