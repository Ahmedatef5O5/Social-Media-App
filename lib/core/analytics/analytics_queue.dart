import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'analytics_event.dart';

/// Minimal async key-value store. The production implementation wraps
/// `SharedPreferences` (see `analytics_client.dart`); tests use
/// [InMemoryAnalyticsStorage].
abstract interface class AnalyticsStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class InMemoryAnalyticsStorage implements AnalyticsStorage {
  InMemoryAnalyticsStorage([Map<String, String>? seed])
    : data = seed ?? <String, String>{};

  final Map<String, String> data;

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async => data[key] = value;

  @override
  Future<void> delete(String key) async => data.remove(key);
}

/// What the server answer means for the batch that was just sent.
enum AnalyticsSendOutcome {
  /// Accepted (the server reports per-event rejects, which are final).
  success,

  /// Transient problem (offline, timeout, 5xx): keep the batch, back off.
  retry,

  /// The batch can never succeed (malformed payload): discard it so one poison
  /// batch cannot block the queue forever.
  drop,
}

/// Sends one batch (already JSON-encoded events) to the backend.
typedef AnalyticsSender =
    Future<AnalyticsSendOutcome> Function(List<Map<String, dynamic>> batch);

/// Cancel handle for a scheduled callback.
abstract interface class AnalyticsTimerHandle {
  void cancel();
}

/// Time source for the periodic flush; injectable so tests need no real waiting.
abstract interface class AnalyticsScheduler {
  AnalyticsTimerHandle periodic(Duration interval, void Function() callback);
}

class SystemAnalyticsScheduler implements AnalyticsScheduler {
  const SystemAnalyticsScheduler();

  @override
  AnalyticsTimerHandle periodic(Duration interval, void Function() callback) {
    final timer = Timer.periodic(interval, (_) => callback());
    return _TimerHandle(timer.cancel);
  }
}

class _TimerHandle implements AnalyticsTimerHandle {
  _TimerHandle(this._cancel);
  final void Function() _cancel;

  @override
  void cancel() => _cancel();
}

enum AnalyticsFlushStatus {
  /// Nothing was waiting.
  empty,

  /// Every queued event was delivered.
  drained,

  /// A batch failed; the remaining events stay queued.
  failed,

  /// Still inside the back-off window after an earlier failure.
  backingOff,
}

/// Persistent, batching, self-healing event queue.
///
///  * Persistent: every mutation is written to [AnalyticsStorage] before the
///    call returns, so events survive an app kill / restart.
///  * Batching: at most [maxBatchSize] (20) events per request; flushed every
///    [flushInterval] (30 s) by [start], and on demand ([flush]) when the app
///    goes to the background.
///  * Circuit breaker: at most [maxQueueSize] (200) events are kept. When the
///    device stays offline the OLDEST events are dropped first.
///  * Retry: exponential back-off with jitter (base, 2x per consecutive failure,
///    capped at [maxBackoff]); success resets it.
///  * De-duplication: an event id already queued is ignored.
class AnalyticsQueue {
  AnalyticsQueue({
    required AnalyticsStorage storage,
    required AnalyticsSender sender,
    AnalyticsScheduler scheduler = const SystemAnalyticsScheduler(),
    DateTime Function()? now,
    Random? random,
    this.maxBatchSize = 20,
    this.maxQueueSize = 200,
    this.flushInterval = const Duration(seconds: 30),
    this.baseBackoff = const Duration(seconds: 2),
    this.maxBackoff = const Duration(minutes: 5),
    this.storageKey = 'analytics.queue.v1',
    this.flushWhenBatchFull = true,
  }) : assert(maxBatchSize > 0),
       assert(maxQueueSize >= maxBatchSize),
       _storage = storage,
       _sender = sender,
       _scheduler = scheduler,
       _now = now ?? DateTime.now,
       _random = random ?? Random();

  final int maxBatchSize;
  final int maxQueueSize;
  final Duration flushInterval;
  final Duration baseBackoff;
  final Duration maxBackoff;
  final String storageKey;
  final bool flushWhenBatchFull;

  final AnalyticsStorage _storage;
  final AnalyticsSender _sender;
  final AnalyticsScheduler _scheduler;
  final DateTime Function() _now;
  final Random _random;

  final List<AnalyticsEvent> _events = <AnalyticsEvent>[];
  final Set<String> _ids = <String>{};
  AnalyticsTimerHandle? _timer;
  Future<AnalyticsFlushStatus>? _inFlight;
  Future<void> _persistChain = Future<void>.value();

  int _consecutiveFailures = 0;
  DateTime? _nextAttemptAt;
  int _droppedOverflow = 0;
  int _droppedPermanent = 0;

  int get length => _events.length;
  bool get isEmpty => _events.isEmpty;
  List<AnalyticsEvent> get snapshot => List.unmodifiable(_events);

  /// Events discarded by the size cap (oldest first) since the queue was created.
  int get droppedOverflow => _droppedOverflow;

  /// Events discarded because the server said the batch can never succeed.
  int get droppedPermanent => _droppedPermanent;
  int get consecutiveFailures => _consecutiveFailures;
  DateTime? get nextAttemptAt => _nextAttemptAt;
  bool get isStarted => _timer != null;

  /// Loads persisted events. Corrupt or partially invalid storage is repaired,
  /// never thrown.
  Future<void> restore() async {
    _events.clear();
    _ids.clear();
    String? raw;
    try {
      raw = await _storage.read(storageKey);
    } catch (_) {
      return;
    }
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      final list = decoded is Map ? decoded['events'] : null;
      if (list is List) {
        for (final item in list) {
          final event = AnalyticsEvent.fromJson(item);
          if (event != null && _ids.add(event.eventId)) _events.add(event);
        }
      }
    } catch (_) {
      _events.clear();
      _ids.clear();
    }
    final overflow = _trimToCap();
    if (overflow > 0) await _persist();
  }

  /// Adds an event (ignored if its id is already queued) and persists.
  Future<void> enqueue(AnalyticsEvent event) async {
    if (!_ids.add(event.eventId)) return;
    _events.add(event);
    _trimToCap();
    await _persist();
    if (flushWhenBatchFull && _events.length >= maxBatchSize) {
      unawaited(flush());
    }
  }

  /// Starts the periodic flush. Safe to call repeatedly.
  void start() {
    _timer ??= _scheduler.periodic(flushInterval, () {
      if (_events.isNotEmpty) unawaited(flush());
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Drops everything (used when the user opts out).
  Future<void> clear() async {
    _events.clear();
    _ids.clear();
    _consecutiveFailures = 0;
    _nextAttemptAt = null;
    await _persist();
  }

  /// Sends queued events in batches until the queue is empty or a batch fails.
  /// Concurrent calls share one run. [force] ignores the back-off window (use it
  /// for the app-going-to-background flush).
  Future<AnalyticsFlushStatus> flush({bool force = false}) {
    final running = _inFlight;
    if (running != null) return running;
    final run = _flushLoop(force: force);
    _inFlight = run;
    return run.whenComplete(() => _inFlight = null);
  }

  /// Resolves when every pending write reached storage (tests, shutdown).
  Future<void> settle() => _persistChain;

  Future<AnalyticsFlushStatus> _flushLoop({required bool force}) async {
    if (_events.isEmpty) return AnalyticsFlushStatus.empty;
    final next = _nextAttemptAt;
    if (!force && next != null && _now().isBefore(next)) {
      return AnalyticsFlushStatus.backingOff;
    }

    while (_events.isNotEmpty) {
      final count = min(maxBatchSize, _events.length);
      final batch = _events.sublist(0, count);
      AnalyticsSendOutcome outcome;
      try {
        outcome = await _sender(
          batch.map((e) => e.toJson()).toList(growable: false),
        );
      } catch (_) {
        outcome = AnalyticsSendOutcome.retry;
      }

      switch (outcome) {
        case AnalyticsSendOutcome.success:
          _removeBatch(batch);
          _consecutiveFailures = 0;
          _nextAttemptAt = null;
          await _persist();
        case AnalyticsSendOutcome.drop:
          _removeBatch(batch);
          _droppedPermanent += batch.length;
          await _persist();
        case AnalyticsSendOutcome.retry:
          _consecutiveFailures += 1;
          _nextAttemptAt = _now().add(_backoffFor(_consecutiveFailures));
          return AnalyticsFlushStatus.failed;
      }
    }
    return AnalyticsFlushStatus.drained;
  }

  /// `base * 2^(failures-1)`, capped at [maxBackoff], plus up to 20 % jitter
  /// (the jittered value is also capped).
  Duration backoffFor(int failures) => _backoffFor(failures);

  Duration _backoffFor(int failures) {
    final exponent = min(max(failures - 1, 0), 20);
    final rawMs = baseBackoff.inMilliseconds * (1 << exponent);
    final cappedMs = min(rawMs, maxBackoff.inMilliseconds);
    final jittered = cappedMs * (1 + _random.nextDouble() * 0.2);
    return Duration(milliseconds: min(jittered.round(), maxBackoff.inMilliseconds));
  }

  void _removeBatch(List<AnalyticsEvent> batch) {
    final sentIds = batch.map((e) => e.eventId).toSet();
    _events.removeWhere((e) => sentIds.contains(e.eventId));
    _ids.removeAll(sentIds);
  }

  /// Oldest-first drop. Returns how many events were discarded.
  int _trimToCap() {
    final overflow = _events.length - maxQueueSize;
    if (overflow <= 0) return 0;
    for (final dropped in _events.sublist(0, overflow)) {
      _ids.remove(dropped.eventId);
    }
    _events.removeRange(0, overflow);
    _droppedOverflow += overflow;
    return overflow;
  }

  Future<void> _persist() {
    final payload = jsonEncode(<String, Object>{
      'v': 1,
      'events': _events.map((e) => e.toJson()).toList(),
    });
    _persistChain = _persistChain
        .then((_) => _storage.write(storageKey, payload))
        .catchError((Object _) {});
    return _persistChain;
  }
}
