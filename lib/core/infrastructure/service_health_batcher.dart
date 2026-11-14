import 'dart:async';

import 'service_health_sample.dart';

/// Delivers one batch (already JSON-encoded) to the backend. Throws on failure.
typedef ServiceHealthSender = Future<void> Function(
  List<Map<String, dynamic>> samples,
);

/// Bounded in-memory buffer that ships health samples to the backend every
/// [flushInterval] (60 s) and whenever [flush] is called (app pause).
///
/// DROP POLICY (telemetry must never become a memory or battery problem):
///  * the queue holds at most [maxQueueSize] samples; on overflow the OLDEST
///    sample is evicted,
///  * a sample older than [maxSampleAge] is dropped (the server ignores client
///    timestamps older than 15 minutes anyway),
///  * when [isOnline] reports `false` the whole queue is dropped instead of
///    being kept: a stale outage report is worse than a missing one,
///  * a failed send keeps the remaining samples for the next tick (bounded by
///    the two rules above) and never throws to the caller.
///
/// Nothing is persisted to disk.
class ServiceHealthBatcher {
  ServiceHealthBatcher({
    required this.sender,
    this.flushInterval = const Duration(seconds: 60),
    this.maxQueueSize = 200,
    this.maxBatchSize = 50,
    this.maxSampleAge = const Duration(minutes: 10),
    this.isOnline,
    this.beforeFlush,
    DateTime Function()? clock,
  })  : assert(maxQueueSize > 0),
        assert(maxBatchSize > 0),
        _clock = clock ?? DateTime.now;

  final ServiceHealthSender sender;
  final Duration flushInterval;
  final int maxQueueSize;

  /// Mirrors the server limit (50 samples per RPC call).
  final int maxBatchSize;
  final Duration maxSampleAge;
  final DateTime Function() _clock;

  /// `null` = assume online.
  bool Function()? isOnline;

  /// Called at the start of every flush; the coordinator uses it to move its
  /// aggregation windows into the queue.
  FutureOr<void> Function()? beforeFlush;

  final List<ServiceHealthSample> _queue = <ServiceHealthSample>[];
  Timer? _timer;
  bool _flushing = false;

  int _dropped = 0;
  int _sent = 0;
  int _failedFlushes = 0;

  int get length => _queue.length;
  int get droppedCount => _dropped;
  int get sentCount => _sent;
  int get failedFlushCount => _failedFlushes;
  bool get isRunning => _timer != null;

  /// Samples currently buffered (read-only copy, for tests and diagnostics).
  List<ServiceHealthSample> get pending =>
      List<ServiceHealthSample>.unmodifiable(_queue);

  void add(ServiceHealthSample sample) {
    _queue.add(sample);
    while (_queue.length > maxQueueSize) {
      _queue.removeAt(0);
      _dropped++;
    }
  }

  void start() {
    _timer ??= Timer.periodic(flushInterval, (_) => unawaited(flush()));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Sends everything that is queued. Safe to call concurrently (a second call
  /// while one is running returns immediately) and never throws.
  Future<void> flush() async {
    if (_flushing) return;
    _flushing = true;
    try {
      try {
        await beforeFlush?.call();
      } catch (_) {
        // A broken aggregator must not stop already-queued samples from shipping.
      }

      _evictStale();
      if (_queue.isEmpty) return;

      final online = isOnline;
      if (online != null && !online()) {
        _dropped += _queue.length;
        _queue.clear();
        return;
      }

      while (_queue.isNotEmpty) {
        final batch = _queue.take(maxBatchSize).toList(growable: false);
        try {
          await sender(
            batch.map((s) => s.toJson()).toList(growable: false),
          );
        } catch (_) {
          _failedFlushes++;
          return; // keep the rest; retried on the next tick
        }
        final sent = Set<ServiceHealthSample>.identity()..addAll(batch);
        _queue.removeWhere(sent.contains);
        _sent += batch.length;
      }
    } finally {
      _flushing = false;
    }
  }

  void _evictStale() {
    final cutoff = _clock().subtract(maxSampleAge);
    final before = _queue.length;
    _queue.removeWhere((s) => s.observedAt.isBefore(cutoff));
    _dropped += before - _queue.length;
  }
}
