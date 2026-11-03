import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Pure Dart (no Flutter, no Supabase, no I/O): everything in this file is
/// deterministic and unit-testable on the plain Dart VM.
///
/// The rule model mirrors `public.get_app_feature_flags().flags.<key>` exactly.

// -----------------------------------------------------------------------------
// Deterministic bucketing
// -----------------------------------------------------------------------------

/// Returns a stable bucket in `1..100` for (salt, flag, identifier).
///
///   `sha256(utf8("<salt>:<flagKey>:<identifier>"))` -> first 4 bytes read as an
///   UNSIGNED big-endian integer -> `% 100 + 1`
///
/// Why plain arithmetic instead of `(b0 << 24) | (b1 << 16) | ...`:
/// on dart2js (Flutter Web) bitwise operators are 32-bit SIGNED, so any hash
/// whose first byte is >= 0x80 would turn negative and land in a different
/// bucket than on Android/iOS (measured: 46% of identifiers diverge). The
/// multiplication form yields the same non-negative value on every platform and
/// matches `public.feature_flag_bucket(salt, key, identifier)` in SQL.
///
/// Because the identifier is hashed with the flag's own salt, a user's bucket
/// for flag A is independent of their bucket for flag B (no "always first in
/// line" users), and rotating the salt reshuffles one flag's cohort only.
int calculateBucket(String salt, String flagKey, String identifier) {
  final digest = sha256.convert(utf8.encode('$salt:$flagKey:$identifier'));
  final b = digest.bytes;
  final value = b[0] * 16777216 + b[1] * 65536 + b[2] * 256 + b[3];
  return (value % 100) + 1;
}

// -----------------------------------------------------------------------------
// App version
// -----------------------------------------------------------------------------

/// `1`, `1.2`, `1.2.3` or `1.2.3+45` (same grammar as the SQL CHECK constraint).
class AppVersion {
  const AppVersion(this.major, this.minor, this.patch, this.build);

  final int major;
  final int minor;
  final int patch;

  /// null when the string carried no `+build` part.
  final int? build;

  static final RegExp _re = RegExp(r'^([0-9]+)(?:\.([0-9]+))?(?:\.([0-9]+))?(?:\+([0-9]+))?$');

  static AppVersion? tryParse(String? raw) {
    if (raw == null) return null;
    final m = _re.firstMatch(raw.trim());
    if (m == null) return null;
    return AppVersion(
      int.parse(m.group(1)!),
      int.parse(m.group(2) ?? '0'),
      int.parse(m.group(3) ?? '0'),
      m.group(4) == null ? null : int.parse(m.group(4)!),
    );
  }

  /// Compares this (the running app) against a flag [bound].
  ///
  /// A bound WITHOUT a build number compares major.minor.patch only, so
  /// `max_app_version = 1.2.0` still includes `1.2.0+7` (otherwise the build
  /// number would silently push every build of 1.2.0 over the limit). A bound
  /// WITH a build number compares the build too.
  int compareToBound(AppVersion bound) {
    if (major != bound.major) return major < bound.major ? -1 : 1;
    if (minor != bound.minor) return minor < bound.minor ? -1 : 1;
    if (patch != bound.patch) return patch < bound.patch ? -1 : 1;
    final boundBuild = bound.build;
    if (boundBuild == null) return 0;
    final mine = build ?? 0;
    if (mine != boundBuild) return mine < boundBuild ? -1 : 1;
    return 0;
  }
}

// -----------------------------------------------------------------------------
// Rule model
// -----------------------------------------------------------------------------

class FeatureFlagRule {
  const FeatureFlagRule({
    required this.key,
    required this.salt,
    this.enabled = false,
    this.killSwitch = false,
    this.rolloutPercentage = 0,
    this.targetPlatforms = const ['android', 'ios', 'web'],
    this.targetEnvironments = const ['production', 'staging'],
    this.minAppVersion,
    this.maxAppVersion,
    this.startsAt,
    this.endsAt,
    this.defaultFallback = false,
    this.targetUserCount = 0,
  });

  final String key;
  final String salt;
  final bool enabled;
  final bool killSwitch;

  /// 0..100
  final int rolloutPercentage;
  final List<String> targetPlatforms;
  final List<String> targetEnvironments;
  final String? minAppVersion;
  final String? maxAppVersion;
  final DateTime? startsAt;
  final DateTime? endsAt;

  /// Returned when the user is outside the rollout, and when evaluation fails.
  final bool defaultFallback;

  /// Size of the server-side whitelist. The ids themselves never reach clients.
  final int targetUserCount;

  /// Tolerant parser: a malformed entry returns null and is skipped, it never
  /// throws (a bad row must not take the other flags down with it).
  static FeatureFlagRule? tryParse(String key, Object? raw) {
    if (raw is! Map) return null;
    final salt = raw['salt'];
    if (salt is! String || salt.isEmpty) return null;

    List<String> strings(Object? v, List<String> fallback) {
      if (v is! List) return fallback;
      return v.whereType<String>().toList(growable: false);
    }

    DateTime? time(Object? v) {
      if (v is! String) return null;
      return DateTime.tryParse(v)?.toUtc();
    }

    final pct = raw['rollout_percentage'];
    final count = raw['target_user_count'];
    return FeatureFlagRule(
      key: key,
      salt: salt,
      enabled: raw['enabled'] == true,
      killSwitch: raw['kill_switch'] == true,
      rolloutPercentage: pct is num ? pct.round().clamp(0, 100) : 0,
      targetPlatforms: strings(raw['target_platforms'], const ['android', 'ios', 'web']),
      targetEnvironments: strings(raw['target_environments'], const ['production', 'staging']),
      minAppVersion: raw['min_app_version'] is String ? raw['min_app_version'] as String : null,
      maxAppVersion: raw['max_app_version'] is String ? raw['max_app_version'] as String : null,
      startsAt: time(raw['starts_at']),
      endsAt: time(raw['ends_at']),
      defaultFallback: raw['default_fallback'] == true,
      targetUserCount: count is num ? count.round() : 0,
    );
  }

  Map<String, Object?> toJson() => {
    'enabled': enabled,
    'kill_switch': killSwitch,
    'rollout_percentage': rolloutPercentage,
    'target_platforms': targetPlatforms,
    'target_environments': targetEnvironments,
    'min_app_version': minAppVersion,
    'max_app_version': maxAppVersion,
    'starts_at': startsAt?.toIso8601String(),
    'ends_at': endsAt?.toIso8601String(),
    'salt': salt,
    'default_fallback': defaultFallback,
    'target_user_count': targetUserCount,
  };
}

/// Everything about the running app and user that a rule can depend on.
class FeatureFlagContext {
  const FeatureFlagContext({
    required this.platform,
    required this.environment,
    required this.appVersion,
    required this.identifier,
    required this.now,
  });

  /// `android` | `ios` | `web` | `windows` | `macos` | `linux`
  final String platform;

  /// `dev` | `staging` | `production` (BuildInfo.environment)
  final String environment;

  /// `1.2.3+45` as composed by SystemControlService.currentAppVersion(), or
  /// null for local `0.0.0-dev` builds.
  final String? appVersion;

  /// user.id when signed in, else the persisted device install id.
  final String identifier;

  /// Server-corrected "now" (UTC) used for the schedule window.
  final DateTime now;
}

enum FeatureFlagReason {
  killSwitch,
  disabled,
  notStarted,
  ended,
  platformExcluded,
  environmentExcluded,
  versionOutOfRange,
  whitelisted,
  inRollout,
  fallback,
  error,
}

class FeatureFlagDecision {
  const FeatureFlagDecision(this.enabled, this.reason, {this.bucket});

  final bool enabled;
  final FeatureFlagReason reason;

  /// Set when the decision reached the percentage step.
  final int? bucket;

  @override
  String toString() => 'FeatureFlagDecision($enabled, $reason, bucket: $bucket)';
}

// -----------------------------------------------------------------------------
// Evaluator
// -----------------------------------------------------------------------------

class FeatureFlagEvaluator {
  const FeatureFlagEvaluator();

  bool evaluate(
    FeatureFlagRule rule,
    FeatureFlagContext context, {
    bool whitelisted = false,
  }) => evaluateDetailed(rule, context, whitelisted: whitelisted).enabled;

  /// Pipeline (first match wins). Never throws: any unexpected error returns
  /// [FeatureFlagRule.defaultFallback].
  ///
  ///   1. kill_switch                       -> false
  ///   2. !enabled                          -> false
  ///   3. schedule (starts_at / ends_at)    -> false when outside the window
  ///   4. platform not targeted             -> false
  ///   4b. environment not targeted         -> false   (target_environments)
  ///   5. app version outside [min, max]    -> false
  ///   6. user is whitelisted               -> true
  ///   7. bucket <= rollout_percentage      -> true
  ///   8. otherwise                         -> default_fallback
  FeatureFlagDecision evaluateDetailed(
    FeatureFlagRule rule,
    FeatureFlagContext context, {
    bool whitelisted = false,
  }) {
    try {
      if (rule.killSwitch) {
        return const FeatureFlagDecision(false, FeatureFlagReason.killSwitch);
      }
      if (!rule.enabled) {
        return const FeatureFlagDecision(false, FeatureFlagReason.disabled);
      }

      final starts = rule.startsAt;
      if (starts != null && context.now.isBefore(starts)) {
        return const FeatureFlagDecision(false, FeatureFlagReason.notStarted);
      }
      final ends = rule.endsAt;
      if (ends != null && !context.now.isBefore(ends)) {
        return const FeatureFlagDecision(false, FeatureFlagReason.ended);
      }

      if (!rule.targetPlatforms.contains(context.platform)) {
        return const FeatureFlagDecision(false, FeatureFlagReason.platformExcluded);
      }
      if (!rule.targetEnvironments.contains(context.environment)) {
        return const FeatureFlagDecision(false, FeatureFlagReason.environmentExcluded);
      }

      if (!_versionAllowed(rule, context.appVersion)) {
        return const FeatureFlagDecision(false, FeatureFlagReason.versionOutOfRange);
      }

      if (whitelisted) {
        return const FeatureFlagDecision(true, FeatureFlagReason.whitelisted);
      }

      final bucket = calculateBucket(rule.salt, rule.key, context.identifier);
      if (bucket <= rule.rolloutPercentage) {
        return FeatureFlagDecision(true, FeatureFlagReason.inRollout, bucket: bucket);
      }

      return FeatureFlagDecision(rule.defaultFallback, FeatureFlagReason.fallback, bucket: bucket);
    } catch (_) {
      return FeatureFlagDecision(rule.defaultFallback, FeatureFlagReason.error);
    }
  }

  /// A flag with a version bound never activates on a build whose version is
  /// unknown (local `0.0.0-dev`): a version-gated feature must not leak onto
  /// builds we cannot place. Flags without bounds are unaffected.
  bool _versionAllowed(FeatureFlagRule rule, String? appVersion) {
    final minRaw = rule.minAppVersion;
    final maxRaw = rule.maxAppVersion;
    if (minRaw == null && maxRaw == null) return true;

    final app = AppVersion.tryParse(appVersion);
    if (app == null) return false;

    if (minRaw != null) {
      final min = AppVersion.tryParse(minRaw);
      if (min == null || app.compareToBound(min) < 0) return false;
    }
    if (maxRaw != null) {
      final max = AppVersion.tryParse(maxRaw);
      if (max == null || app.compareToBound(max) > 0) return false;
    }
    return true;
  }
}
