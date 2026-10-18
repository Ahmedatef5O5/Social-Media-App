import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_media_app/features/two_factor/services/two_factor_lockout_store.dart';

void main() {
  const uid = 'user-1';
  late DateTime clock;
  late TwoFactorLockoutStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    clock = DateTime(2026, 10, 17, 12);
    store = TwoFactorLockoutStore(now: () => clock);
  });

  Future<Duration?> failTimes(int n) async {
    Duration? last;
    for (var i = 0; i < n; i++) {
      last = await store.recordFailure(uid);
    }
    return last;
  }

  test('no pause before the 5th failure', () async {
    expect(await failTimes(4), isNull);
    expect(await store.remaining(uid), isNull);
  });

  test('5th failure pauses for 30s and the pause expires', () async {
    expect(await failTimes(5), const Duration(seconds: 30));
    expect(await store.remaining(uid), const Duration(seconds: 30));
    clock = clock.add(const Duration(seconds: 31));
    expect(await store.remaining(uid), isNull);
  });

  test('pause doubles each round and is capped at 15 minutes', () async {
    final pauses = <Duration>[];
    for (var round = 0; round < 8; round++) {
      pauses.add((await failTimes(5))!);
    }
    expect(pauses.first, const Duration(seconds: 30));
    expect(pauses[1], const Duration(seconds: 60));
    expect(pauses[2], const Duration(seconds: 120));
    expect(pauses.last, const Duration(minutes: 15));
  });

  test('state survives a new store instance (app restart)', () async {
    await failTimes(5);
    final reopened = TwoFactorLockoutStore(now: () => clock);
    expect(await reopened.remaining(uid), isNotNull);
  });

  test('reset clears the pause and the escalation', () async {
    await failTimes(5);
    await store.reset(uid);
    expect(await store.remaining(uid), isNull);
    expect(await failTimes(5), const Duration(seconds: 30));
  });

  test('users are isolated from each other', () async {
    await failTimes(5);
    expect(await store.remaining('someone-else'), isNull);
  });
}
