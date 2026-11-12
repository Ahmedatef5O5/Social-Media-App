import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Canonical event names. Mirrors the server allow-list in
/// `log_analytics_events` (migration 017): a name that is not listed here is
/// rejected on both sides.
abstract final class AnalyticsEvents {
  static const String appSessionStarted = 'app_session_started';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String userRegistered = 'user_registered';
  static const String profileCompleted = 'profile_completed';
  static const String firstMessageSent = 'first_message_sent';
  static const String firstGroupJoined = 'first_group_joined';
  static const String firstPostCreated = 'first_post_created';
  static const String meaningfulActivationAchieved =
      'meaningful_activation_achieved';
  static const String featureUsed = 'feature_used';

  static const Set<String> all = {
    appSessionStarted,
    onboardingCompleted,
    userRegistered,
    profileCompleted,
    firstMessageSent,
    firstGroupJoined,
    firstPostCreated,
    meaningfulActivationAchieved,
    featureUsed,
  };
}

/// Values accepted for the `feature_name` property of `feature_used`.
abstract final class AnalyticsFeatures {
  static const String stories = 'stories';
  static const String reels = 'reels';
  static const String aiChat = 'ai_chat';
  static const String singleChat = 'single_chat';
  static const String groupChat = 'group_chat';
  static const String feed = 'feed';

  static const List<String> all = [
    stories,
    reels,
    aiChat,
    singleChat,
    groupChat,
    feed,
  ];
}

/// Platform label sent with every event. Uses only `foundation.dart`
/// (no `dart:io`, no plugin), so it is Shorebird-patch safe and web-safe.
abstract final class AnalyticsPlatform {
  static String detect() {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }
}

enum _PropKind { flag, integer, choice }

/// One allow-listed property of one event.
final class _PropSpec {
  const _PropSpec.flag(this.key)
    : kind = _PropKind.flag,
      allowed = const <String>[],
      maxInt = 0;

  const _PropSpec.integer(this.key, {required int max})
    : kind = _PropKind.integer,
      allowed = const <String>[],
      maxInt = max;

  const _PropSpec.choice(this.key, this.allowed)
    : kind = _PropKind.choice,
      maxInt = 0;

  final String key;
  final _PropKind kind;
  final List<String> allowed;
  final int maxInt;
}

/// Immutable analytics event.
///
/// PRIVACY: [properties] can only ever contain keys that are allow-listed for
/// the event name, as booleans, bounded integers or enum-like strings (see
/// [sanitizeProperties]). There is intentionally no way to attach free text,
/// names, emails, message or post content.
@immutable
final class AnalyticsEvent {
  const AnalyticsEvent._({
    required this.eventId,
    required this.eventName,
    required this.anonymousId,
    required this.sessionId,
    required this.clientTimestamp,
    required this.properties,
    required this.platform,
    this.userId,
    this.appVersion,
  });

  /// Hard limit mirrored by a CHECK constraint on `analytics_events.properties`.
  static const int maxPropertiesBytes = 500;

  static const Uuid _uuid = Uuid();

  /// Client-generated id: the idempotency key (`analytics_events.id`).
  final String eventId;
  final String eventName;

  /// Supabase user id; `null` before authentication.
  final String? userId;

  /// SHA-256 hex digest of the device install token.
  final String anonymousId;

  /// Rotates per app foreground session.
  final String sessionId;

  /// Always UTC.
  final DateTime clientTimestamp;
  final Map<String, Object> properties;
  final String? appVersion;
  final String platform;

  /// Builds a validated event. Throws [ArgumentError] for an unknown name so
  /// typos surface in development; [AnalyticsClient] swallows it in release.
  ///
  /// Pass [eventId] (for example [deterministicId]) for lifecycle events that
  /// must be recorded at most once per user: the server's primary key then
  /// de-duplicates them even across devices and retries.
  factory AnalyticsEvent.create({
    required String name,
    required String anonymousId,
    required String sessionId,
    String? userId,
    Map<String, Object?>? properties,
    DateTime? timestamp,
    String? appVersion,
    String? platform,
    String? eventId,
  }) {
    if (!AnalyticsEvents.all.contains(name)) {
      throw ArgumentError.value(name, 'name', 'Unknown analytics event');
    }
    return AnalyticsEvent._(
      eventId: eventId ?? _uuid.v4(),
      eventName: name,
      userId: (userId == null || userId.isEmpty) ? null : userId,
      anonymousId: anonymousId,
      sessionId: sessionId,
      clientTimestamp: (timestamp ?? DateTime.now()).toUtc(),
      properties: Map<String, Object>.unmodifiable(
        sanitizeProperties(name, properties),
      ),
      appVersion: appVersion,
      platform: platform ?? AnalyticsPlatform.detect(),
    );
  }

  /// Stable UUID (v5) derived from [key], e.g. `user_registered:<userId>`.
  static String deterministicId(String key) =>
      _uuid.v5(Namespace.url.value, 'social-mate-analytics:$key');

  static const Map<String, List<_PropSpec>> _schemas = {
    AnalyticsEvents.onboardingCompleted: [
      _PropSpec.flag('completed'),
      _PropSpec.flag('skipped'),
      _PropSpec.integer('duration_seconds', max: 86400),
    ],
    AnalyticsEvents.userRegistered: [
      _PropSpec.choice('auth_provider', [
        'email',
        'google',
        'facebook',
        'microsoft',
        'other',
      ]),
    ],
    AnalyticsEvents.profileCompleted: [
      _PropSpec.flag('has_avatar'),
      _PropSpec.flag('has_bio'),
      _PropSpec.flag('has_tagline'),
    ],
    AnalyticsEvents.firstMessageSent: [
      _PropSpec.choice('chat_type', ['single', 'group']),
    ],
    AnalyticsEvents.firstGroupJoined: [_PropSpec.flag('is_public')],
    AnalyticsEvents.firstPostCreated: [
      _PropSpec.flag('has_media'),
      _PropSpec.flag('in_group'),
    ],
    AnalyticsEvents.meaningfulActivationAchieved: [
      _PropSpec.choice('activation_type', ['dialogue', 'group', 'feedback']),
    ],
    AnalyticsEvents.featureUsed: [
      _PropSpec.choice('feature_name', [
        'stories',
        'reels',
        'ai_chat',
        'single_chat',
        'group_chat',
        'feed',
      ]),
    ],
  };

  /// Keeps only allow-listed, correctly typed properties (see class docs).
  /// Anything else is silently dropped. Never throws.
  static Map<String, Object> sanitizeProperties(
    String eventName,
    Map<String, Object?>? raw,
  ) {
    final specs = _schemas[eventName];
    if (raw == null || raw.isEmpty || specs == null) {
      return const <String, Object>{};
    }
    final out = <String, Object>{};
    for (final spec in specs) {
      final value = raw[spec.key];
      switch (spec.kind) {
        case _PropKind.flag:
          if (value is bool) out[spec.key] = value;
        case _PropKind.integer:
          if (value is num && value.isFinite) {
            out[spec.key] = value.floor().clamp(0, spec.maxInt).toInt();
          }
        case _PropKind.choice:
          if (value is String && spec.allowed.contains(value)) {
            out[spec.key] = value;
          }
      }
    }
    if (utf8.encode(jsonEncode(out)).length > maxPropertiesBytes) {
      return const <String, Object>{};
    }
    return out;
  }

  AnalyticsEvent withUserId(String? newUserId) => AnalyticsEvent._(
    eventId: eventId,
    eventName: eventName,
    userId: (newUserId == null || newUserId.isEmpty) ? null : newUserId,
    anonymousId: anonymousId,
    sessionId: sessionId,
    clientTimestamp: clientTimestamp,
    properties: properties,
    appVersion: appVersion,
    platform: platform,
  );

  /// Payload shape expected by `log_analytics_events`.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'event_id': eventId,
    'event_name': eventName,
    'user_id': userId,
    'anonymous_id': anonymousId,
    'session_id': sessionId,
    'client_timestamp': clientTimestamp.toIso8601String(),
    'properties': properties,
    'app_version': appVersion,
    'platform': platform,
  };

  /// Returns `null` for anything malformed (corrupt storage must never crash
  /// the app or poison the queue).
  static AnalyticsEvent? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['event_id'];
    final name = json['event_name'];
    final anon = json['anonymous_id'];
    final session = json['session_id'];
    final ts = json['client_timestamp'];
    if (id is! String ||
        name is! String ||
        anon is! String ||
        session is! String ||
        ts is! String ||
        !AnalyticsEvents.all.contains(name)) {
      return null;
    }
    final parsed = DateTime.tryParse(ts);
    if (parsed == null) return null;
    final userId = json['user_id'];
    final rawProps = json['properties'];
    final appVersion = json['app_version'];
    final platform = json['platform'];
    return AnalyticsEvent._(
      eventId: id,
      eventName: name,
      userId: userId is String && userId.isNotEmpty ? userId : null,
      anonymousId: anon,
      sessionId: session,
      clientTimestamp: parsed.toUtc(),
      properties: Map<String, Object>.unmodifiable(
        sanitizeProperties(
          name,
          rawProps is Map ? rawProps.cast<String, Object?>() : null,
        ),
      ),
      appVersion: appVersion is String ? appVersion : null,
      platform: platform is String ? platform : 'unknown',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AnalyticsEvent && other.eventId == eventId;

  @override
  int get hashCode => eventId.hashCode;

  @override
  String toString() => 'AnalyticsEvent($eventName, $eventId)';
}
