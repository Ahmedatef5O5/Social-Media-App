import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:social_media_app/core/analytics/analytics_queue.dart';
import 'package:social_media_app/core/analytics/analytics_session_manager.dart';

import 'analytics_test_helpers.dart';

final RegExp _hex64 = RegExp(r'^[0-9a-f]{64}$');

void main() {
  group('anonymous id', () {
    test('is the SHA-256 hex of a locally stored random token', () async {
      final storage = InMemoryAnalyticsStorage();
      final m = AnalyticsSessionManager(storage: storage);
      await m.init();
      expect(m.anonymousId, matches(_hex64));
      final token = storage.data['analytics.install_token.v1']!;
      expect(token.length, 64);
      expect(m.anonymousId, AnalyticsSessionManager.hashToken(token));
      expect(m.anonymousId == token, false, reason: 'raw token is never the id');
    });

    test('hash matches the SHA-256 known-answer vector', () {
      expect(
        AnalyticsSessionManager.hashToken('abc'),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });

    test('is stable across restarts of the same install', () async {
      final storage = InMemoryAnalyticsStorage();
      final a = AnalyticsSessionManager(storage: storage);
      await a.init();
      final b = AnalyticsSessionManager(storage: storage);
      await b.init();
      expect(b.anonymousId, a.anonymousId);
    });

    test('differs between installs', () async {
      final a = AnalyticsSessionManager(storage: InMemoryAnalyticsStorage());
      final b = AnalyticsSessionManager(storage: InMemoryAnalyticsStorage());
      await a.init();
      await b.init();
      expect(a.anonymousId == b.anonymousId, false);
    });

    test('a corrupt/short stored token is replaced', () async {
      final storage = InMemoryAnalyticsStorage(<String, String>{
        'analytics.install_token.v1': 'abc',
      });
      final m = AnalyticsSessionManager(storage: storage, random: Random(7));
      await m.init();
      expect(storage.data['analytics.install_token.v1']!.length, 64);
    });

    test('resetIdentity produces a new, unrelated id', () async {
      final m = AnalyticsSessionManager(storage: InMemoryAnalyticsStorage());
      await m.init();
      final old = m.anonymousId;
      await m.resetIdentity();
      expect(m.anonymousId == old, false);
      expect(m.sessionId, isNull);
    });

    test('reading the id before init() fails fast', () {
      final m = AnalyticsSessionManager(storage: InMemoryAnalyticsStorage());
      expect(() => m.anonymousId, throwsStateError);
      expect(m.isInitialized, false);
    });
  });

  group('session rotation', () {
    late FakeClock clock;
    late AnalyticsSessionManager m;

    setUp(() async {
      clock = FakeClock();
      m = AnalyticsSessionManager(
        storage: InMemoryAnalyticsStorage(),
        now: clock.call,
      );
      await m.init();
    });

    test('the first foreground starts a session', () {
      expect(m.sessionId, isNull);
      expect(m.onForeground(), true);
      expect(m.sessionId, isNotNull);
    });

    test('a duplicate resumed signal does not start another session', () {
      m.onForeground();
      final id = m.sessionId;
      expect(m.onForeground(), false);
      expect(m.sessionId, id);
    });

    test('returning within 30 s keeps the session', () {
      m.onForeground();
      final id = m.sessionId;
      m.onBackground();
      clock.advance(const Duration(seconds: 29));
      expect(m.onForeground(), false);
      expect(m.sessionId, id);
    });

    test('returning after 30 s rotates the session id', () {
      m.onForeground();
      final id = m.sessionId;
      m.onBackground();
      clock.advance(const Duration(seconds: 30));
      expect(m.onForeground(), true);
      expect(m.sessionId == id, false);
    });

    test('repeated background signals keep the earliest timestamp', () {
      m.onForeground();
      final id = m.sessionId;
      m.onBackground();
      clock.advance(const Duration(seconds: 20));
      m.onBackground(); // e.g. paused then hidden
      clock.advance(const Duration(seconds: 15));
      expect(m.onForeground(), true, reason: '35 s since the FIRST background');
      expect(m.sessionId == id, false);
    });
  });
}
