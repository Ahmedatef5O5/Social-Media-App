import 'package:flutter_test/flutter_test.dart';
import 'package:social_media_app/core/analytics/analytics_client.dart';
import 'package:social_media_app/core/analytics/analytics_event.dart';
import 'package:social_media_app/core/analytics/analytics_queue.dart';

import 'analytics_test_helpers.dart';

class Rig {
  Rig({InMemoryAnalyticsStorage? storage, String? Function()? userIdProvider})
    : storage = storage ?? InMemoryAnalyticsStorage(),
      clock = FakeClock(),
      scheduler = FakeScheduler(),
      sender = FakeSender() {
    client = DefaultAnalyticsClient(
      storage: this.storage,
      sender: sender.call,
      userIdProvider: userIdProvider,
      scheduler: scheduler,
      now: clock.call,
      platform: 'android',
      observeLifecycle: false,
    );
  }

  final InMemoryAnalyticsStorage storage;
  final FakeClock clock;
  final FakeScheduler scheduler;
  final FakeSender sender;
  late final DefaultAnalyticsClient client;

  List<String> get queuedNames =>
      client.queue.snapshot.map((e) => e.eventName).toList();
}

void main() {
  group('start-up', () {
    test('emits app_session_started once and is ready to send', () async {
      final rig = Rig();
      await rig.client.start();
      expect(rig.queuedNames, <String>[AnalyticsEvents.appSessionStarted]);
      final e = rig.client.queue.snapshot.single;
      expect(e.anonymousId.length, 64);
      expect(e.platform, 'android');
      expect(e.appVersion, '0.0.0-dev+0');
      expect(rig.client.queue.isStarted, true);
      await rig.client.start(); // idempotent
      expect(rig.queuedNames.length, 1);
    });

    test('events queued before a restart are delivered after it', () async {
      final storage = InMemoryAnalyticsStorage();
      final first = Rig(storage: storage);
      first.sender.fallback = AnalyticsSendOutcome.retry;
      await first.client.start();
      await first.client.track(AnalyticsEvents.featureUsed,
          properties: <String, Object?>{'feature_name': 'feed'});
      await first.client.flush();
      expect(first.client.queue.length, 2);

      final second = Rig(storage: storage);
      await second.client.start();
      await second.client.flush();
      final ids = second.sender.sentIds;
      expect(ids.length, 3, reason: '2 restored + the new session event');
      expect(second.client.queue.length, 0);
    });

    test('the anonymous id survives restarts', () async {
      final storage = InMemoryAnalyticsStorage();
      final a = Rig(storage: storage);
      await a.client.start();
      final b = Rig(storage: storage);
      await b.client.start();
      expect(b.client.sessions.anonymousId, a.client.sessions.anonymousId);
    });
  });

  group('track', () {
    test('sanitizes properties and never throws on bad input', () async {
      final rig = Rig();
      await rig.client.start();
      await rig.client.track(AnalyticsEvents.featureUsed, properties: <String, Object?>{
        'feature_name': 'stories',
        'email': 'a@b.co',
      });
      await rig.client.track('definitely_not_an_event');
      final last = rig.client.queue.snapshot.last;
      expect(last.properties, <String, Object>{'feature_name': 'stories'});
      expect(rig.queuedNames.contains('definitely_not_an_event'), false);
    });

    test('setUserId stamps later events and null clears it', () async {
      final rig = Rig();
      await rig.client.start();
      rig.client.setUserId('user-1');
      await rig.client.track(AnalyticsEvents.featureUsed,
          properties: <String, Object?>{'feature_name': 'feed'});
      rig.client.setUserId(null);
      await rig.client.track(AnalyticsEvents.featureUsed,
          properties: <String, Object?>{'feature_name': 'reels'});
      final events = rig.client.queue.snapshot;
      expect(events[0].userId, isNull, reason: 'session event was pre-auth');
      expect(events[1].userId, 'user-1');
      expect(events[2].userId, isNull);
    });

    test('falls back to the auth provider for the user id', () async {
      final rig = Rig(userIdProvider: () => 'from-provider');
      await rig.client.start();
      expect(rig.client.queue.snapshot.single.userId, 'from-provider');
    });
  });

  group('trackOnce', () {
    test('records an event at most once per key', () async {
      final rig = Rig();
      await rig.client.start();
      for (var i = 0; i < 3; i++) {
        await rig.client.trackOnce(AnalyticsEvents.firstMessageSent,
            onceKey: 'user-1', properties: <String, Object?>{'chat_type': 'single'});
      }
      expect(rig.queuedNames.where((n) => n == 'first_message_sent').length, 1);
    });

    test('is remembered across restarts', () async {
      final storage = InMemoryAnalyticsStorage();
      final a = Rig(storage: storage);
      await a.client.start();
      await a.client.trackOnce(AnalyticsEvents.userRegistered, onceKey: 'user-1');
      await Future<void>.delayed(Duration.zero);

      final b = Rig(storage: storage);
      await b.client.start();
      await b.client.trackOnce(AnalyticsEvents.userRegistered, onceKey: 'user-1');
      expect(b.queuedNames.where((n) => n == 'user_registered').length, 1,
          reason: 'only the copy restored from disk, no second event');
    });

    test('different keys are independent', () async {
      final rig = Rig();
      await rig.client.start();
      await rig.client.trackOnce(AnalyticsEvents.userRegistered, onceKey: 'user-1');
      await rig.client.trackOnce(AnalyticsEvents.userRegistered, onceKey: 'user-2');
      expect(rig.queuedNames.where((n) => n == 'user_registered').length, 2);
    });

    test('uses a deterministic id so two devices collapse server-side', () async {
      final a = Rig();
      final b = Rig();
      await a.client.start();
      await b.client.start();
      await a.client.trackOnce(AnalyticsEvents.firstPostCreated, onceKey: 'user-1');
      await b.client.trackOnce(AnalyticsEvents.firstPostCreated, onceKey: 'user-1');
      String idOf(Rig r) => r.client.queue.snapshot
          .firstWhere((e) => e.eventName == 'first_post_created')
          .eventId;
      expect(idOf(a), idOf(b));
      expect(idOf(a), AnalyticsEvent.deterministicId('first_post_created:user-1'));
    });

    test('ignores an empty key', () async {
      final rig = Rig();
      await rig.client.start();
      await rig.client.trackOnce(AnalyticsEvents.userRegistered, onceKey: '');
      expect(rig.queuedNames.contains('user_registered'), false);
    });
  });

  group('trackFeatureUsed', () {
    List<String> featureEvents(Rig r) => r.client.queue.snapshot
        .where((e) => e.eventName == 'feature_used')
        .map((e) => e.properties['feature_name']! as String)
        .toList();

    test('fires once per feature per session', () async {
      final rig = Rig();
      await rig.client.start();
      for (var i = 0; i < 5; i++) {
        await rig.client.trackFeatureUsed(AnalyticsFeatures.stories);
      }
      await rig.client.trackFeatureUsed(AnalyticsFeatures.reels);
      await rig.client.trackFeatureUsed(AnalyticsFeatures.stories);
      expect(featureEvents(rig), <String>['stories', 'reels']);
    });

    test('fires again in a new session', () async {
      final rig = Rig();
      await rig.client.start();
      await rig.client.trackFeatureUsed(AnalyticsFeatures.feed);
      await rig.client.handleBackground();
      rig.clock.advance(const Duration(minutes: 5));
      await rig.client.handleForeground();
      await rig.client.trackFeatureUsed(AnalyticsFeatures.feed);
      expect(featureEvents(rig), <String>['feed']);
      // the first one was flushed at background time; both reached the sender
      final sent = rig.sender.batches
          .expand((b) => b)
          .where((e) => e['event_name'] == 'feature_used')
          .length;
      expect(sent + featureEvents(rig).length, 2);
    });

    test('ignores unknown features and does nothing when disabled', () async {
      final rig = Rig();
      await rig.client.start();
      await rig.client.trackFeatureUsed('secret_menu');
      expect(featureEvents(rig), isEmpty);
      await rig.client.setEnabled(false);
      await rig.client.trackFeatureUsed(AnalyticsFeatures.feed);
      expect(rig.client.queue.length, 0);
    });
  });

  group('lifecycle', () {
    test('going to the background flushes immediately (ignores back-off)', () async {
      final rig = Rig();
      rig.sender.script.add(AnalyticsSendOutcome.retry);
      await rig.client.start();
      await rig.client.flush(); // fails -> back-off
      expect(rig.client.queue.length, 1);
      await rig.client.handleBackground();
      expect(rig.client.queue.length, 0);
    });

    test('a quick return keeps the session; a late return starts a new one', () async {
      final rig = Rig();
      await rig.client.start();
      final session = rig.client.sessions.sessionId;

      await rig.client.handleBackground();
      rig.clock.advance(const Duration(seconds: 10));
      await rig.client.handleForeground();
      expect(rig.client.sessions.sessionId, session);

      await rig.client.handleBackground();
      rig.clock.advance(const Duration(minutes: 2));
      await rig.client.handleForeground();
      expect(rig.client.sessions.sessionId == session, false);
      await rig.client.flush();
      final starts = rig.sender.batches
          .expand((b) => b)
          .where((e) => e['event_name'] == 'app_session_started')
          .length;
      expect(starts, 2);
    });
  });

  group('privacy switch', () {
    test('disabling clears the queue and stops collection', () async {
      final rig = Rig();
      await rig.client.start();
      final before = rig.client.sessions.anonymousId;
      await rig.client.setEnabled(false);
      expect(rig.client.isEnabled, false);
      expect(rig.client.queue.length, 0);
      expect(rig.client.queue.isStarted, false);
      await rig.client.track(AnalyticsEvents.featureUsed,
          properties: <String, Object?>{'feature_name': 'feed'});
      expect(rig.client.queue.length, 0);
      expect(rig.client.sessions.anonymousId == before, false,
          reason: 'identity is rotated');
    });

    test('the choice persists across restarts', () async {
      final storage = InMemoryAnalyticsStorage();
      final a = Rig(storage: storage);
      await a.client.start();
      await a.client.setEnabled(false);

      final b = Rig(storage: storage);
      await b.client.start();
      expect(b.client.isEnabled, false);
      expect(b.client.queue.length, 0, reason: 'no session event when disabled');
    });

    test('re-enabling resumes with a fresh session event', () async {
      final rig = Rig();
      await rig.client.start();
      await rig.client.setEnabled(false);
      await rig.client.setEnabled(true);
      expect(rig.queuedNames, <String>[AnalyticsEvents.appSessionStarted]);
    });
  });

  group('SupabaseAnalyticsSender.prepareBatch', () {
    final batch = <Map<String, dynamic>>[
      <String, dynamic>{'event_id': '1', 'user_id': 'a'},
      <String, dynamic>{'event_id': '2', 'user_id': 'b'},
      <String, dynamic>{'event_id': '3', 'user_id': null},
    ];

    test('keeps the signed-in user and strips everyone else', () {
      final out = SupabaseAnalyticsSender.prepareBatch(batch, 'a');
      expect(out.map((e) => e['user_id']).toList(), <String?>['a', null, null]);
    });

    test('signed out: every event becomes anonymous', () {
      final out = SupabaseAnalyticsSender.prepareBatch(batch, null);
      expect(out.map((e) => e['user_id']).toList(), <String?>[null, null, null]);
    });

    test('does not mutate the queued payloads', () {
      SupabaseAnalyticsSender.prepareBatch(batch, null);
      expect(batch[0]['user_id'], 'a');
    });
  });
}
