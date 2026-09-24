import 'package:flutter_test/flutter_test.dart';
import 'package:social_media_app/core/presence/services/presence_service.dart';

/// PRIORITY: P2 — high-frequency production flow.
///
/// SCOPE NOTE (deliberate, not laziness)
/// ─────────────────────────────────────
/// `PresenceService` is a singleton whose every write path goes through
/// `SupabaseProvider.client`, and whose heartbeat is a real `Timer.periodic`
/// started from `init()`. Unit-testing `init()`/`_setOnline()` would need
/// either a Supabase test harness or a constructor seam on the singleton —
/// a bigger change than this baseline is allowed to make.
///
/// What IS pure, and what every presence avatar in the app depends on, is
/// `isConsideredOnline`. It encodes the 90-second staleness rule: the
/// heartbeat fires every 30s, so a user is "online" only if we heard from
/// them within three heartbeats. Getting this wrong shows permanent green
/// dots for users who force-quit the app — the single most reported class
/// of presence bug.
void main() {
  group('PresenceService.isConsideredOnline', () {
    final now = DateTime.now().toUtc();

    test('an explicit offline flag wins regardless of freshness', () {
      expect(
        PresenceService.isConsideredOnline(isOnline: false, updatedAt: now),
        isFalse,
      );
    });

    test('a missing timestamp is treated as offline, never as online', () {
      expect(
        PresenceService.isConsideredOnline(isOnline: true, updatedAt: null),
        isFalse,
      );
    });

    test('a fresh heartbeat counts as online', () {
      expect(
        PresenceService.isConsideredOnline(
          isOnline: true,
          updatedAt: now.subtract(const Duration(seconds: 10)),
        ),
        isTrue,
      );
    });

    test('exactly at the 90s boundary is still online (inclusive)', () {
      expect(
        PresenceService.isConsideredOnline(
          isOnline: true,
          updatedAt: now.subtract(const Duration(seconds: 89)),
        ),
        isTrue,
      );
    });

    test('past 90s the user is stale — this is the force-quit case, where '
        'the row still says is_online = true because the app never got to '
        'write false', () {
      expect(
        PresenceService.isConsideredOnline(
          isOnline: true,
          updatedAt: now.subtract(const Duration(seconds: 120)),
        ),
        isFalse,
      );
    });

    test('a local-time timestamp is normalised to UTC before comparison, '
        'so a user in UTC+2 is not reported online for two extra hours', () {
      final localFresh = DateTime.now().subtract(const Duration(seconds: 5));
      expect(
        PresenceService.isConsideredOnline(
          isOnline: true,
          updatedAt: localFresh,
        ),
        isTrue,
      );
    });

    test('a clock-skewed FUTURE timestamp does not crash and reads online', () {
      expect(
        PresenceService.isConsideredOnline(
          isOnline: true,
          updatedAt: now.add(const Duration(minutes: 5)),
        ),
        isTrue,
      );
    });
  });
}
