import 'package:flutter_test/flutter_test.dart';
import 'package:social_media_app/core/observability/crash_reporter.dart';
import 'package:social_media_app/core/observability/error_category.dart';
import 'package:social_media_app/core/observability/observability.dart';
import 'package:social_media_app/core/observability/realtime_diagnostics.dart';

/// PRIORITY: P0 — account isolation (V6 C-02, H-02/H-03).
///
/// The app opens Realtime channels from 12 different files. Several of
/// them defensively loop over `getChannels()` and remove a same-named
/// channel before subscribing — which is itself proof that duplicate and
/// orphaned channels were a real production problem.
///
/// Nothing in the app knows how many channels are open or which account
/// they belong to. [RealtimeDiagnostics] answers exactly that, and these
/// tests pin the three failure modes it exists to surface: duplicates,
/// zombies after an account switch, and unbounded growth.
void main() {
  late RecordingCrashReporter reporter;
  late RealtimeDiagnostics diagnostics;

  setUp(() async {
    Observability.resetForTest();
    RealtimeDiagnostics.resetForTest();
    reporter = RecordingCrashReporter();
    await obs.attachReporter(
      reporter,
      environment: 'test',
      appVersion: '1.0.0',
      buildNumber: '2',
    );
    diagnostics = RealtimeDiagnostics.instance;
  });

  group('normal lifecycle', () {
    test('create → subscribe → close leaves nothing active and raises no '
        'issue', () {
      diagnostics.onChannelCreated('realtime:chat_1', ownerUserId: 'u1');
      diagnostics.onChannelSubscribed('realtime:chat_1');
      expect(diagnostics.activeCount, 1);

      diagnostics.onChannelClosed('realtime:chat_1');

      expect(diagnostics.activeCount, 0);
      expect(reporter.errors, isEmpty);
    });

    test('active channel count is exported as a Crashlytics custom key, so '
        'any crash report carries "how many channels were open"', () {
      diagnostics.onChannelCreated('a', ownerUserId: 'u1');
      diagnostics.onChannelSubscribed('a');
      expect(reporter.customKeys['realtime_active_channels'], 1);
    });

    test('closing an unknown topic is a no-op, never a throw', () {
      expect(
        () => diagnostics.onChannelClosed('never-existed'),
        returnsNormally,
      );
    });
  });

  group('duplicate subscriptions', () {
    test('subscribing twice to the same live topic raises a realtime issue '
        '— this is the doubled-unread-count / message-appears-twice bug', () {
      diagnostics.onChannelCreated('realtime:group_42', ownerUserId: 'u1');
      diagnostics.onChannelSubscribed('realtime:group_42');

      diagnostics.onChannelCreated('realtime:group_42', ownerUserId: 'u1');

      expect(reporter.errors, hasLength(1));
      expect(reporter.errors.single.category, ErrorCategory.realtime);
      expect(
        reporter.errors.single.error,
        isA<DuplicateRealtimeSubscription>(),
      );
    });

    test('re-subscribing AFTER a proper close is legitimate and silent', () {
      diagnostics.onChannelCreated('t', ownerUserId: 'u1');
      diagnostics.onChannelSubscribed('t');
      diagnostics.onChannelClosed('t');
      diagnostics.onChannelCreated('t', ownerUserId: 'u1');

      expect(reporter.errors, isEmpty);
    });
  });

  group('errors and reconnection', () {
    test('a channel error is reported with its topic and error count', () {
      diagnostics.onChannelCreated('t', ownerUserId: 'u1');
      diagnostics.onChannelError(
        't',
        Exception('timed out'),
        StackTrace.current,
      );

      expect(reporter.errors.single.category, ErrorCategory.realtime);
      expect(reporter.errors.single.reason, contains('topic=t'));
      expect(reporter.errors.single.reason, contains('errors=1'));
    });

    test('recovering after an error is counted as a reconnect breadcrumb, '
        'which is how "the subscription keeps dropping" becomes visible', () {
      diagnostics.onChannelCreated('t', ownerUserId: 'u1');
      diagnostics.onChannelSubscribed('t');
      diagnostics.onChannelError('t', Exception('drop'), null);
      diagnostics.onChannelSubscribed('t');

      expect(diagnostics.recordFor('t')!.reconnectCount, 1);
      expect(reporter.logs.any((l) => l.contains('recovered')), isTrue);
    });
  });

  group('account switching — V6 C-02', () {
    test('a channel owned by the previous account is flagged as a zombie', () {
      diagnostics.onChannelCreated('realtime:presence_u1', ownerUserId: 'u1');
      diagnostics.onChannelSubscribed('realtime:presence_u1');
      diagnostics.onChannelCreated('realtime:feed', ownerUserId: 'u2');
      diagnostics.onChannelSubscribed('realtime:feed');

      final zombies = diagnostics.detectZombies('u2');

      expect(zombies.map((z) => z.topic), ['realtime:presence_u1']);
      expect(reporter.errors.single.error, isA<ZombieRealtimeChannels>());
      expect(
        reporter.errors.single.reason,
        contains('survived an account switch'),
      );
    });

    test('a clean switch (everything closed first) reports nothing — the '
        'test that proves the detector is not just always firing', () {
      diagnostics.onChannelCreated('realtime:presence_u1', ownerUserId: 'u1');
      diagnostics.onChannelSubscribed('realtime:presence_u1');
      diagnostics.onChannelClosed('realtime:presence_u1');

      diagnostics.onChannelCreated('realtime:presence_u2', ownerUserId: 'u2');
      diagnostics.onChannelSubscribed('realtime:presence_u2');

      expect(diagnostics.detectZombies('u2'), isEmpty);
      expect(reporter.errors, isEmpty);
    });

    test('closed channels from the old account are not counted as zombies', () {
      diagnostics.onChannelCreated('t', ownerUserId: 'u1');
      diagnostics.onChannelClosed('t');
      expect(diagnostics.detectZombies('u2'), isEmpty);
    });
  });

  group('pressure', () {
    test('crossing the channel ceiling raises exactly one issue at the '
        'crossing, not one per subsequent channel', () {
      for (var i = 0; i <= RealtimeDiagnostics.suspiciousChannelCount; i++) {
        diagnostics.onChannelCreated('topic_$i', ownerUserId: 'u1');
        diagnostics.onChannelSubscribed('topic_$i');
      }

      final pressure =
          reporter.errors
              .where((e) => e.error is RealtimeChannelPressure)
              .toList();

      expect(pressure, hasLength(1));
      expect(
        diagnostics.activeCount,
        RealtimeDiagnostics.suspiciousChannelCount + 1,
      );
    });

    test('a normal session stays well under the ceiling', () {
      for (final topic in [
        'feed',
        'conversations',
        'presence',
        'mute',
        'block',
        'chat_open',
        'group_open',
        'comments',
      ]) {
        diagnostics.onChannelCreated(topic, ownerUserId: 'u1');
        diagnostics.onChannelSubscribed(topic);
      }
      expect(reporter.errors, isEmpty);
    });
  });
}
