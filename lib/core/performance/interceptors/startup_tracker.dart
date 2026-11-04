import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Which kind of start a sample describes.
enum StartupKind {
  /// `main()` entry -> first frame rendered (a fresh process / isolate).
  cold('cold'),

  /// App resumed after a long stay in background -> next frame rendered.
  warm('warm');

  const StartupKind(this.wire);
  final String wire;
}

class StartupSample {
  const StartupSample(this.kind, this.duration);
  final StartupKind kind;
  final Duration duration;
  int get milliseconds => duration.inMilliseconds;
}

/// Schedules [callback] for after the next rendered frame. Injectable for tests.
typedef PostFrameScheduler = void Function(void Function() callback);

/// Measures startup latency in pure Dart.
///
/// ```dart
/// void main() {
///   StartupTracker.instance.begin();          // 1st line of main()
///   ...
///   runApp(buildApp(...));
///   StartupTracker.instance.attachFirstFrame(); // right after runApp
/// }
/// ```
///
/// HONEST LIMITS (documented in METRICS_MATHEMATICAL_SPEC.md)
///  * The cold clock starts when Dart `main()` runs, not when the OS created the
///    process, so it is a LOWER BOUND of what the user waited. The native
///    "time to initial display" shown in Play Console stays the reference.
///  * The warm clock is `resumed -> next frame` inside a live isolate; an
///    activity re-created by Android with a new isolate is seen as cold.
///
/// Pure Dart: Shorebird Type A.
class StartupTracker {
  StartupTracker({PostFrameScheduler? scheduler, Stopwatch Function()? stopwatch})
    : _scheduler = scheduler ?? _binding,
      _newStopwatch = stopwatch ?? Stopwatch.new;

  static final StartupTracker instance = StartupTracker();

  final PostFrameScheduler _scheduler;
  final Stopwatch Function() _newStopwatch;

  Stopwatch? _cold;
  bool _coldReported = false;

  /// Receives every sample (wired to `SessionManager.reportStartup`).
  void Function(StartupSample sample)? onMeasured;

  /// Last cold sample, for diagnostics / tests.
  StartupSample? lastCold;

  /// Marks "main() entered". Idempotent: the first call wins.
  void begin() {
    _cold ??= _newStopwatch()..start();
  }

  /// Schedules the cold measurement for after the first rendered frame.
  void attachFirstFrame() {
    final sw = _cold;
    if (sw == null || _coldReported) return;
    _scheduler(() {
      if (_coldReported) return;
      _coldReported = true;
      sw.stop();
      final sample = StartupSample(StartupKind.cold, sw.elapsed);
      lastCold = sample;
      _emit(sample);
    });
  }

  /// Measures resume -> next frame. Called by `SessionManager` after a resume
  /// that started a new session.
  void measureNextFrame(StartupKind kind) {
    final sw = _newStopwatch()..start();
    _scheduler(() {
      sw.stop();
      _emit(StartupSample(kind, sw.elapsed));
    });
  }

  void _emit(StartupSample sample) {
    try {
      onMeasured?.call(sample);
    } catch (e) {
      if (kDebugMode) debugPrint('⏱️ StartupTracker listener failed: $e');
    }
  }

  static void _binding(void Function() callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) => callback());
  }

  @visibleForTesting
  void resetForTest() {
    _cold = null;
    _coldReported = false;
    lastCold = null;
    onMeasured = null;
  }
}
