import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:social_media_app/core/analytics/analytics_event.dart';

import 'analytics_test_helpers.dart';

final RegExp _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);
final RegExp _uuidV5 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

AnalyticsEvent create(
  String name, {
  Map<String, Object?>? props,
  String? userId,
  DateTime? at,
  String? id,
}) => AnalyticsEvent.create(
  name: name,
  anonymousId: anon64,
  sessionId: '11111111-1111-4111-8111-111111111111',
  userId: userId,
  properties: props,
  timestamp: at,
  appVersion: '1.0.0+2',
  platform: 'android',
  eventId: id,
);

void main() {
  group('identity and timestamps', () {
    test('generates a UUID v4 event id (client-side idempotency key)', () {
      final a = create(AnalyticsEvents.appSessionStarted);
      final b = create(AnalyticsEvents.appSessionStarted);
      expect(a.eventId, matches(_uuidV4));
      expect(a.eventId == b.eventId, false);
    });

    test('timestamps are always UTC, even for local input', () {
      final e = create(
        AnalyticsEvents.appSessionStarted,
        at: DateTime(2026, 3, 4, 5, 6, 7),
      );
      expect(e.clientTimestamp.isUtc, true);
      expect(e.toJson()['client_timestamp'] as String, matches(RegExp(r'Z$')));
    });

    test('an explicit event id is respected', () {
      expect(create(AnalyticsEvents.appSessionStarted, id: 'fixed').eventId, 'fixed');
    });

    test('empty user id is stored as null (pre-auth)', () {
      expect(create(AnalyticsEvents.appSessionStarted, userId: '').userId, isNull);
      expect(create(AnalyticsEvents.appSessionStarted, userId: 'u1').userId, 'u1');
    });

    test('platform detection returns a server-accepted label', () {
      const accepted = <String>{
        'android', 'ios', 'web', 'windows', 'macos', 'linux', 'fuchsia',
      };
      expect(accepted.contains(AnalyticsPlatform.detect()), true);
    });

    test('unknown event names are rejected loudly', () {
      expect(
        () => AnalyticsEvent.create(
          name: 'user_clicked_secret_button',
          anonymousId: anon64,
          sessionId: 's',
        ),
        throwsArgumentError,
      );
    });
  });

  group('deterministic ids (once-per-user events)', () {
    test('same key -> same UUID v5; different key -> different id', () {
      final a = AnalyticsEvent.deterministicId('user_registered:user-1');
      expect(a, AnalyticsEvent.deterministicId('user_registered:user-1'));
      expect(a, matches(_uuidV5));
      expect(a == AnalyticsEvent.deterministicId('user_registered:user-2'), false);
    });
  });

  group('privacy: property allow-list', () {
    test('drops PII-looking and unknown keys', () {
      final e = create(
        AnalyticsEvents.featureUsed,
        props: <String, Object?>{
          'feature_name': 'stories',
          'email': 'ahmed@example.com',
          'text': 'my private message',
          'name': 'Ahmed',
          'phone': '+201000000000',
        },
      );
      expect(e.properties, <String, Object>{'feature_name': 'stories'});
    });

    test('rejects values outside the enum', () {
      expect(
        create(AnalyticsEvents.featureUsed, props: <String, Object?>{'feature_name': 'hello world'}).properties,
        isEmpty,
      );
      expect(
        create(AnalyticsEvents.userRegistered, props: <String, Object?>{'auth_provider': 'pigeon'}).properties,
        isEmpty,
      );
    });

    test('accepts each documented property of each event', () {
      expect(
        create(AnalyticsEvents.onboardingCompleted, props: <String, Object?>{
          'completed': true, 'skipped': false, 'duration_seconds': 42,
        }).properties,
        <String, Object>{'completed': true, 'skipped': false, 'duration_seconds': 42},
      );
      expect(
        create(AnalyticsEvents.userRegistered, props: <String, Object?>{'auth_provider': 'google'}).properties,
        <String, Object>{'auth_provider': 'google'},
      );
      expect(
        create(AnalyticsEvents.profileCompleted, props: <String, Object?>{
          'has_avatar': true, 'has_bio': true, 'has_tagline': false,
        }).properties,
        <String, Object>{'has_avatar': true, 'has_bio': true, 'has_tagline': false},
      );
      expect(
        create(AnalyticsEvents.firstMessageSent, props: <String, Object?>{'chat_type': 'group'}).properties,
        <String, Object>{'chat_type': 'group'},
      );
      expect(
        create(AnalyticsEvents.firstGroupJoined, props: <String, Object?>{'is_public': true}).properties,
        <String, Object>{'is_public': true},
      );
      expect(
        create(AnalyticsEvents.firstPostCreated, props: <String, Object?>{
          'has_media': true, 'in_group': false,
        }).properties,
        <String, Object>{'has_media': true, 'in_group': false},
      );
      expect(
        create(AnalyticsEvents.meaningfulActivationAchieved, props: <String, Object?>{
          'activation_type': 'feedback',
        }).properties,
        <String, Object>{'activation_type': 'feedback'},
      );
      for (final f in AnalyticsFeatures.all) {
        expect(
          create(AnalyticsEvents.featureUsed, props: <String, Object?>{'feature_name': f}).properties,
          <String, Object>{'feature_name': f},
        );
      }
    });

    test('wrong types are dropped, integers are clamped', () {
      final e = create(
        AnalyticsEvents.onboardingCompleted,
        props: <String, Object?>{
          'completed': 'yes',
          'skipped': 1,
          'duration_seconds': 9999999,
        },
      );
      expect(e.properties, <String, Object>{'duration_seconds': 86400});
      expect(
        create(AnalyticsEvents.onboardingCompleted, props: <String, Object?>{'duration_seconds': -5})
            .properties['duration_seconds'],
        0,
      );
      expect(
        create(AnalyticsEvents.onboardingCompleted, props: <String, Object?>{'duration_seconds': 12.9})
            .properties['duration_seconds'],
        12,
      );
      expect(
        create(AnalyticsEvents.onboardingCompleted, props: <String, Object?>{'duration_seconds': double.nan})
            .properties,
        isEmpty,
      );
    });

    test('events without a schema keep no properties at all', () {
      expect(
        create(AnalyticsEvents.appSessionStarted, props: <String, Object?>{'anything': 'x'}).properties,
        isEmpty,
      );
    });

    test('serialized properties never exceed 500 bytes', () {
      for (final name in AnalyticsEvents.all) {
        final e = create(name, props: <String, Object?>{
          for (var i = 0; i < 200; i++) 'k$i': 'v' * 40,
          'feature_name': 'feed',
        });
        expect(utf8.encode(jsonEncode(e.properties)).length,
            lessThanOrEqualTo(AnalyticsEvent.maxPropertiesBytes));
      }
    });

    test('properties are immutable', () {
      final e = create(AnalyticsEvents.featureUsed, props: <String, Object?>{'feature_name': 'feed'});
      expect(() => e.properties['email'] = 'x', throwsA(isA<UnsupportedError>()));
    });
  });

  group('JSON serialization', () {
    test('toJson uses the server contract keys', () {
      final e = create(
        AnalyticsEvents.firstPostCreated,
        userId: 'user-1',
        props: <String, Object?>{'has_media': true, 'in_group': false},
        at: DateTime.utc(2026, 1, 2, 3, 4, 5),
        id: 'evt-1',
      );
      expect(e.toJson(), <String, dynamic>{
        'event_id': 'evt-1',
        'event_name': 'first_post_created',
        'user_id': 'user-1',
        'anonymous_id': anon64,
        'session_id': '11111111-1111-4111-8111-111111111111',
        'client_timestamp': '2026-01-02T03:04:05.000Z',
        'properties': <String, Object>{'has_media': true, 'in_group': false},
        'app_version': '1.0.0+2',
        'platform': 'android',
      });
    });

    test('round-trips through JSON text', () {
      final e = create(
        AnalyticsEvents.userRegistered,
        userId: 'user-9',
        props: <String, Object?>{'auth_provider': 'email'},
        at: DateTime.utc(2026, 5, 6, 7, 8, 9, 123),
      );
      final back = AnalyticsEvent.fromJson(jsonDecode(jsonEncode(e.toJson())));
      expect(back, isNotNull);
      expect(back!.eventId, e.eventId);
      expect(back.userId, 'user-9');
      expect(back.clientTimestamp, e.clientTimestamp);
      expect(back.properties, e.properties);
      expect(back.platform, 'android');
    });

    test('fromJson returns null for malformed input instead of throwing', () {
      expect(AnalyticsEvent.fromJson(null), isNull);
      expect(AnalyticsEvent.fromJson('x'), isNull);
      expect(AnalyticsEvent.fromJson(<String, dynamic>{}), isNull);
      final good = create(AnalyticsEvents.appSessionStarted).toJson();
      expect(AnalyticsEvent.fromJson(<String, dynamic>{...good, 'event_name': 'hacked'}), isNull);
      expect(AnalyticsEvent.fromJson(<String, dynamic>{...good, 'client_timestamp': 'yesterday'}), isNull);
      expect(AnalyticsEvent.fromJson(<String, dynamic>{...good, 'event_id': 5}), isNull);
    });

    test('fromJson re-sanitizes properties read from disk', () {
      final json = create(AnalyticsEvents.featureUsed,
              props: <String, Object?>{'feature_name': 'feed'})
          .toJson();
      json['properties'] = <String, dynamic>{'feature_name': 'feed', 'email': 'a@b.c'};
      expect(AnalyticsEvent.fromJson(json)!.properties, <String, Object>{'feature_name': 'feed'});
    });

    test('withUserId re-attributes without changing identity of the event', () {
      final e = create(AnalyticsEvents.appSessionStarted, userId: 'u1', id: 'same');
      final anonymous = e.withUserId(null);
      expect(anonymous.userId, isNull);
      expect(anonymous.eventId, 'same');
      expect(anonymous == e, true, reason: 'equality is by event id');
    });
  });
}
