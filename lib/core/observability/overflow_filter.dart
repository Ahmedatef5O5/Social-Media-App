import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../services/active_screen_tracker.dart';
import 'error_category.dart';
import 'fingerprint_throttle.dart';
import 'observability.dart';
import 'telemetry_scrubber.dart';

enum OverflowDirection { horizontal, vertical, unknown }

/// Everything we are willing to keep about one RenderFlex overflow.
///
/// Built ONLY from derived values (pixel delta, direction, route name, a code
/// location). The raw exception text is never stored, because Flutter's
/// overflow message can embed widget descriptions such as `Text("...")` that
/// contain user content.
@immutable
class OverflowInfo {
  const OverflowInfo({
    required this.pixels,
    required this.direction,
    required this.screen,
    required this.topUserFrame,
    required this.topUserFrameLine,
    required this.fingerprint,
  });

  /// Overflow delta in logical pixels, or `null` if it could not be parsed.
  final double? pixels;
  final OverflowDirection direction;

  /// Route name from `ActiveScreenTracker.currentRoute` (scrubbed), or
  /// `unknown`.
  final String screen;

  /// `Member@package:social_media_app/path.dart` (no line number, so the
  /// fingerprint survives unrelated edits), or `unknown`.
  final String topUserFrame;
  final int? topUserFrameLine;

  /// 32 hex chars, see [OverflowFilter.computeFingerprint].
  final String fingerprint;

  String get pixelsLabel => pixels == null ? 'unknown' : pixels!.toString();

  /// Safe, human-readable one-liner (used as message / Crashlytics reason).
  String get summary =>
      'RenderFlex overflowed by $pixelsLabel px (${direction.name}) '
      'on $screen at $topUserFrame';

  /// Stable title: excludes the pixel delta, which varies per device.
  String get title => 'RenderFlex overflow (${direction.name}) on $screen';

  /// Flat, JSON-safe context for the incident payload.
  Map<String, Object> toContext() => {
    'kind': 'layout_overflow',
    'direction': direction.name,
    'screen': screen,
    'top_frame': topUserFrame,
    if (pixels != null) 'pixels': pixels!,
    if (topUserFrameLine != null) 'top_frame_line': topUserFrameLine!,
  };
}

/// Carrier passed through `Observability.recordError` so every downstream
/// reporter receives the already-sanitised [OverflowInfo] instead of the raw
/// Flutter error.
class LayoutOverflowException implements Exception {
  const LayoutOverflowException(this.info);

  final OverflowInfo info;

  @override
  String toString() => 'LayoutOverflowException: ${info.summary}';
}

/// Recognises `A RenderFlex overflowed ...` errors coming through
/// `FlutterError.onError`, so they are reported as non-fatal
/// [ErrorCategory.layoutOverflow] instead of fatal crashes.
class OverflowFilter {
  OverflowFilter._();

  static const String marker = 'A RenderFlex overflowed';

  static const String _unknown = 'unknown';

  // "A RenderFlex overflowed by 14.5 pixels on the right."
  static final RegExp _pixelsAndSide = RegExp(
    r'overflowed by ([0-9]+(?:\.[0-9]+)?) pixels? on the (left|right|top|bottom)',
    caseSensitive: false,
  );

  // "The overflowing RenderFlex has an orientation of Axis.horizontal."
  static final RegExp _orientation = RegExp(
    r'orientation of Axis\.(horizontal|vertical)',
  );

  // "#3      _HomeViewState.build (package:social_media_app/a/b.dart:12:34)"
  static final RegExp _userFrame = RegExp(
    r'^\s*#\d+\s+(.+?)\s+\((package:'
    '${TelemetryScrubber.appPackage}'
    r'/[^:)\s]+):(\d+)(?::\d+)?\)',
  );

  // Debug builds: "Row Row:file:///D:/.../lib/features/x.dart:55:14"
  static final RegExp _creatorLocation = RegExp(
    r'file:///[^\s)]*?/lib/([^\s:)]+\.dart):(\d+)',
  );

  static final FingerprintThrottle _throttle = FingerprintThrottle();

  /// True when [details] is a RenderFlex overflow.
  static bool isOverflow(FlutterErrorDetails details) {
    try {
      return details.exceptionAsString().contains(marker);
    } catch (_) {
      return false;
    }
  }

  /// Parses an overflow, or returns `null` if [details] is something else.
  ///
  /// [screen] overrides `ActiveScreenTracker.currentRoute` (tests).
  static OverflowInfo? tryParse(FlutterErrorDetails details, {String? screen}) {
    final String text;
    try {
      text = details.exceptionAsString();
    } catch (_) {
      return null;
    }
    if (!text.contains(marker)) return null;

    double? pixels;
    var direction = OverflowDirection.unknown;

    final sided = _pixelsAndSide.firstMatch(text);
    if (sided != null) {
      pixels = double.tryParse(sided.group(1)!);
      final side = sided.group(2)!.toLowerCase();
      direction =
          (side == 'left' || side == 'right')
              ? OverflowDirection.horizontal
              : OverflowDirection.vertical;
    } else {
      final axis = _orientation.firstMatch(text)?.group(1);
      if (axis == 'horizontal') direction = OverflowDirection.horizontal;
      if (axis == 'vertical') direction = OverflowDirection.vertical;
    }

    final rawScreen = screen ?? ActiveScreenTracker.currentRoute;
    final sanitizedRoute = rawScreen?.split('?').first.split('#').first;
    final resolvedScreen = TelemetryScrubber.scrubLine(sanitizedRoute);
    final screenName = resolvedScreen.isEmpty ? _unknown : resolvedScreen;

    final frame =
        topUserFrame(details.stack) ?? _frameFromWidgetCreator(details, text);
    final frameToken = frame?.token ?? _unknown;

    return OverflowInfo(
      pixels: pixels,
      direction: direction,
      screen: screenName,
      topUserFrame: frameToken,
      topUserFrameLine: frame?.line,
      fingerprint: computeFingerprint(
        screen: screenName,
        direction: direction,
        topUserFrame: frameToken,
      ),
    );
  }

  /// `sha256('layout_overflow' + screen + direction + topUserFrame)`,
  /// truncated to 32 hex characters. The pixel delta is deliberately NOT part
  /// of it: it differs per device and would split one bug into many issues.
  static String computeFingerprint({
    required String screen,
    required OverflowDirection direction,
    required String topUserFrame,
  }) {
    final input = 'layout_overflow$screen${direction.name}$topUserFrame';
    return sha256.convert(utf8.encode(input)).toString().substring(0, 32);
  }

  /// Topmost frame inside this app's own code, skipping every framework,
  /// `dart:` and third-party frame (the layout/paint pipeline).
  static UserFrame? topUserFrame(StackTrace? stack) {
    if (stack == null) return null;
    for (final line in const LineSplitter().convert(stack.toString())) {
      final m = _userFrame.firstMatch(line);
      if (m == null) continue;
      return UserFrame(
        member: m.group(1)!,
        file: m.group(2)!,
        line: int.tryParse(m.group(3)!),
      );
    }
    return null;
  }

  /// Fallback for the common case where an overflow stack contains only
  /// framework frames: debug builds name the offending widget's source file
  /// in the error text / information collector.
  static UserFrame? _frameFromWidgetCreator(
    FlutterErrorDetails details,
    String text,
  ) {
    var haystack = text;
    try {
      final extra = details.informationCollector?.call();
      if (extra != null) {
        haystack = '$haystack\n${extra.map((n) => n.toString()).join('\n')}';
      }
    } catch (_) {
      // Best effort only.
    }
    final m = _creatorLocation.firstMatch(haystack);
    if (m == null) return null;
    return UserFrame(
      member: null,
      file: 'package:${TelemetryScrubber.appPackage}/${m.group(1)}',
      line: int.tryParse(m.group(2)!),
    );
  }

  /// Entry point for `FlutterError.onError`.
  ///
  /// Returns `true` when [details] was a RenderFlex overflow and has been
  /// fully handled here (reported non-fatally, or swallowed as a duplicate
  /// seen within the last 60 s). The caller must then NOT forward it to the
  /// fatal-crash path. Returns `false` for every other error.
  ///
  /// Never throws and never blocks: reporting is fire-and-forget.
  static bool tryRecord(
    FlutterErrorDetails details, {
    Observability? observability,
    FingerprintThrottle? throttle,
  }) {
    try {
      final info = tryParse(details);
      if (info == null) return false;

      final accepted = (throttle ?? _throttle).tryAcquire(info.fingerprint);
      if (accepted == null) return true; // duplicate within the window

      unawaited(
        (observability ?? obs)
            .recordError(
              LayoutOverflowException(info),
              details.stack,
              category: ErrorCategory.layoutOverflow,
              reason: info.summary,
              feature: 'layout',
              operation: 'render_flex_overflow',
              fatal: false,
            )
            .catchError((Object _) {}),
      );
      return true;
    } catch (_) {
      // Classification must never be the thing that throws inside
      // FlutterError.onError. Let the caller fall back to the old path.
      return false;
    }
  }

  @visibleForTesting
  static void resetForTest() => _throttle.clear();
}

/// A code location inside this app.
@immutable
class UserFrame {
  const UserFrame({
    required this.member,
    required this.file,
    required this.line,
  });

  final String? member;
  final String file;
  final int? line;

  /// Line-free identity used in fingerprints.
  String get token => member == null ? file : '$member@$file';
}
