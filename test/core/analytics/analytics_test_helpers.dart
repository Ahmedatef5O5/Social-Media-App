import 'dart:async';
import 'dart:math';

import 'package:social_media_app/core/analytics/analytics_event.dart';
import 'package:social_media_app/core/analytics/analytics_queue.dart';

/// Test double for the 30 s flush timer: time only moves when the test says so.
class FakeScheduler implements AnalyticsScheduler {
  final List<_Periodic> _timers = <_Periodic>[];
  int get activeTimers => _timers.where((t) => !t.cancelled).length;

  @override
  AnalyticsTimerHandle periodic(Duration interval, void Function() callback) {
    final t = _Periodic(interval, callback);
    _timers.add(t);
    return t;
  }

  /// Fires every periodic callback whose interval elapsed within [by].
  void advance(Duration by) {
    for (final t in List<_Periodic>.of(_timers)) {
      if (t.cancelled) continue;
      t.elapsed += by;
      while (t.elapsed >= t.interval && !t.cancelled) {
        t.elapsed -= t.interval;
        t.callback();
      }
    }
  }
}

class _Periodic implements AnalyticsTimerHandle {
  _Periodic(this.interval, this.callback);
  final Duration interval;
  final void Function() callback;
  Duration elapsed = Duration.zero;
  bool cancelled = false;

  @override
  void cancel() => cancelled = true;
}

/// Mutable clock.
class FakeClock {
  FakeClock([DateTime? start]) : current = start ?? DateTime.utc(2026, 1, 1);
  DateTime current;
  DateTime call() => current;
  void advance(Duration d) => current = current.add(d);
}

/// Sender that records batches and answers from a script.
class FakeSender {
  final List<List<Map<String, dynamic>>> batches = <List<Map<String, dynamic>>>[];
  final List<AnalyticsSendOutcome> script = <AnalyticsSendOutcome>[];
  AnalyticsSendOutcome fallback = AnalyticsSendOutcome.success;
  bool throwOnSend = false;
  Completer<void>? gate;

  int get calls => batches.length;
  List<String> get sentIds => <String>[
    for (final b in batches) for (final e in b) e['event_id'] as String,
  ];

  Future<AnalyticsSendOutcome> call(List<Map<String, dynamic>> batch) async {
    batches.add(batch);
    final g = gate;
    if (g != null) await g.future;
    if (throwOnSend) throw StateError('network down');
    return script.isNotEmpty ? script.removeAt(0) : fallback;
  }
}

/// Random that always returns 0 -> no jitter, deterministic back-off.
class ZeroRandom implements Random {
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
  @override
  int nextInt(int max) => 0;
}

const String anon64 =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

AnalyticsEvent makeEvent(int i, {String name = AnalyticsEvents.featureUsed}) =>
    AnalyticsEvent.create(
      name: name,
      anonymousId: anon64,
      sessionId: '11111111-1111-4111-8111-111111111111',
      eventId: 'evt-${i.toString().padLeft(4, '0')}',
      timestamp: DateTime.utc(2026, 1, 1, 12, 0, i % 60),
      properties: const <String, Object?>{'feature_name': 'feed'},
      appVersion: '1.0.0+2',
      platform: 'android',
    );
