import 'dart:collection';

/// Bounded in-memory LRU that answers "was this fingerprint already reported
/// in the last [window]?".
///
/// Shared by `IncidentReporter` (network batches) and `OverflowFilter` (which
/// must stop a per-frame layout overflow from reaching ANY reporter 60 times a
/// second). Purely in-memory: nothing persists across launches.
class FingerprintThrottle {
  FingerprintThrottle({
    this.maxEntries = 100,
    this.window = const Duration(seconds: 60),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final int maxEntries;
  final Duration window;
  final DateTime Function() _now;

  // Insertion order == recency order (oldest first).
  final LinkedHashMap<String, _Entry> _entries = LinkedHashMap();

  int get length => _entries.length;

  bool contains(String fingerprint) => _entries.containsKey(fingerprint);

  /// Returns `null` when [fingerprint] was accepted less than [window] ago
  /// (the caller must DROP this occurrence). Otherwise the occurrence is
  /// accepted and the number of occurrences suppressed since the previous
  /// accepted one is returned (0 for a first sighting).
  ///
  /// A suppressed hit refreshes the entry's LRU position but NOT its
  /// timestamp, so a steady stream is still reported once per window.
  int? tryAcquire(String fingerprint) {
    final now = _now();
    final existing = _entries.remove(fingerprint);

    if (existing != null && now.difference(existing.acceptedAt) < window) {
      existing.suppressed++;
      _entries[fingerprint] = existing;
      return null;
    }

    final carried = existing?.suppressed ?? 0;
    _entries[fingerprint] = _Entry(now);
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
    return carried;
  }

  void clear() => _entries.clear();
}

class _Entry {
  _Entry(this.acceptedAt);

  final DateTime acceptedAt;
  int suppressed = 0;
}
