import 'dart:collection';

import 'performance_metric.dart';

/// What happened to a sample offered to the queue.
enum EnqueueResult {
  /// Stored.
  accepted,

  /// Queue was full; a failure replaced the oldest SUCCESS sample.
  acceptedEvictingSuccess,

  /// Queue was full; the sample was discarded.
  suppressed,
}

/// Bounded in-memory buffer (default 100 samples) for samples that could not
/// be delivered yet (offline, signed out, backoff).
///
/// SUPPRESSION POLICY — failures are the signal, successes are the bulk:
///  * below capacity: everything is kept;
///  * at capacity, incoming SUCCESS  -> suppressed;
///  * at capacity, incoming FAILURE  -> replaces the oldest SUCCESS, or is
///    suppressed when the queue holds only failures.
/// Memory is therefore hard-bounded and a long outage can never evict the
/// evidence of the outage itself.
class PerformanceQueue {
  PerformanceQueue({this.maxEntries = 100}) : assert(maxEntries > 0);

  final int maxEntries;
  final ListQueue<PerformanceMetric> _items = ListQueue<PerformanceMetric>();
  int _dropped = 0;

  int get length => _items.length;
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  /// Samples discarded since creation / last [clear] (suppressed or evicted).
  int get droppedCount => _dropped;

  List<PerformanceMetric> get snapshot => List.unmodifiable(_items);

  EnqueueResult add(PerformanceMetric metric) {
    if (_items.length < maxEntries) {
      _items.addLast(metric);
      return EnqueueResult.accepted;
    }
    if (metric.isFailure) {
      final victim = _items.cast<PerformanceMetric?>().firstWhere(
        (m) => m!.isSuccess,
        orElse: () => null,
      );
      if (victim != null) {
        _items.remove(victim);
        _items.addLast(metric);
        _dropped++;
        return EnqueueResult.acceptedEvictingSuccess;
      }
    }
    _dropped++;
    return EnqueueResult.suppressed;
  }

  /// Removes and returns up to [max] oldest samples.
  List<PerformanceMetric> takeBatch(int max) {
    final out = <PerformanceMetric>[];
    while (out.length < max && _items.isNotEmpty) {
      out.add(_items.removeFirst());
    }
    return out;
  }

  /// Puts a failed batch back at the FRONT, preserving order. Whatever no
  /// longer fits is dropped (and counted): newer samples win.
  void requeueFront(List<PerformanceMetric> batch) {
    for (final metric in batch.reversed) {
      if (_items.length < maxEntries) {
        _items.addFirst(metric);
      } else {
        _dropped++;
      }
    }
  }

  void clear() {
    _items.clear();
    _dropped = 0;
  }
}
