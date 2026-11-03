import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:social_media_app/core/services/feature_flags/feature_flag_service.dart';

const _salt = 'feature-flag-test-salt';

Map<String, Object?> _flag({
  bool enabled = true,
  bool kill = false,
  int pct = 100,
  String salt = _salt,
}) => {
  'managed': true,
  'enabled': enabled,
  'kill_switch': kill,
  'rollout_percentage': pct,
  'target_platforms': ['android', 'ios', 'web'],
  'target_environments': ['production', 'staging'],
  'min_app_version': null,
  'max_app_version': null,
  'starts_at': null,
  'ends_at': null,
  'salt': salt,
  'default_fallback': false,
  'target_user_count': 0,
};

Map<String, Object?> _payload(Map<String, Object?> flags, {List<String> targeted = const [], String? serverTime}) => {
  'ok': true,
  'server_time': serverTime ?? '2026-11-15T12:00:00Z',
  'flags': flags,
  'targeted_keys': targeted,
};

FeatureFlagService _service(
  FeatureFlagsFetcher fetcher, {
  InMemoryFeatureFlagStore? store,
  String? user,
  DateTime Function()? now,
}) => FeatureFlagService(
  fetcher: fetcher,
  store: store ?? InMemoryFeatureFlagStore(installId: 'device-install-0001'),
  userId: () => user,
  platform: () => 'android',
  environment: () => 'production',
  appVersion: () => '1.2.0+5',
  now: now ?? () => DateTime.utc(2026, 11, 15, 12),
);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('before init, and for unknown flags, the caller default applies', () async {
    final s = _service((() async => _payload({'a_flag': _flag()})));
    expect(s.isEnabled('a_flag'), isFalse);
    expect(s.isEnabled('a_flag', defaultValue: true), isTrue);
    await s.init();
    await _settle();
    expect(s.isEnabled('a_flag'), isTrue);
    expect(s.isEnabled('nope'), isFalse);
    expect(s.isEnabled('nope', defaultValue: true), isTrue);
    s.dispose();
  });

  test('fetches, evaluates and persists a cache', () async {
    final store = InMemoryFeatureFlagStore(installId: 'device-install-0001');
    final s = _service((() async => _payload({'a_flag': _flag(pct: 100)})), store: store);
    await s.init();
    await _settle();
    expect(s.isEnabled('a_flag'), isTrue);
    final cached = jsonDecode(store.snapshot!) as Map;
    expect(cached['v'], 1);
    expect((cached['flags'] as Map).containsKey('a_flag'), isTrue);
    expect((cached['evaluated'] as Map)['a_flag'], isTrue);
    s.dispose();
  });

  test('OFFLINE cold start serves the cached rules (fail-open)', () async {
    final store = InMemoryFeatureFlagStore(installId: 'device-install-0001');
    final online = _service((() async => _payload({'a_flag': _flag()})), store: store);
    await online.init();
    await _settle();
    online.dispose();

    final offline = _service((() async => throw TimeoutException('no network')), store: store);
    await offline.init();
    await _settle();
    expect(offline.isEnabled('a_flag'), isTrue, reason: 'cache must be used when the network fails');
    expect(offline.snapshot.fromCache, isTrue);
    offline.dispose();
  });

  test('a failed or malformed refresh keeps the last known flags', () async {
    var mode = 0;
    final s = _service(() async {
      switch (mode) {
        case 0:
          return _payload({'a_flag': _flag()});
        case 1:
          throw StateError('rpc down');
        default:
          return {'ok': false};
      }
    });
    await s.init();
    await _settle();
    expect(s.isEnabled('a_flag'), isTrue);

    mode = 1;
    await s.refresh(force: true);
    expect(s.isEnabled('a_flag'), isTrue);
    mode = 2;
    await s.refresh(force: true);
    expect(s.isEnabled('a_flag'), isTrue);
    s.dispose();
  });

  test('a kill switch published by the server takes effect on the next refresh', () async {
    var killed = false;
    final s = _service(() async => _payload({'a_flag': _flag(kill: killed)}));
    await s.init();
    await _settle();
    expect(s.isEnabled('a_flag'), isTrue);
    killed = true;
    await s.refresh(force: true);
    expect(s.isEnabled('a_flag'), isFalse);
    expect(s.explain('a_flag')!.reason.name, 'killSwitch');
    s.dispose();
  });

  test('corrupt cache is ignored, never thrown', () async {
    final store = InMemoryFeatureFlagStore(installId: 'x', snapshot: '{not json');
    final s = _service((() async => throw StateError('offline')), store: store);
    await s.init();
    await _settle();
    expect(s.isEnabled('a_flag'), isFalse);
    expect(s.isReady, isTrue);
    s.dispose();
  });

  test('a failing store still yields a working (session) install id', () async {
    final store = InMemoryFeatureFlagStore(installId: 'x')..failReads = true;
    final s = _service((() async => _payload({'a_flag': _flag()})), store: store);
    await s.init();
    await _settle();
    expect(s.isEnabled('a_flag'), isTrue);
    s.dispose();
  });

  test('the install id is stable across restarts and drives pre-login bucketing', () async {
    final store = InMemoryFeatureFlagStore();
    final id1 = await store.readOrCreateInstallId();
    final id2 = await store.readOrCreateInstallId();
    expect(id1, id2);
    expect(id1.length, 36);
  });

  test('whitelist hits come from the server and are tied to the user', () async {
    final store = InMemoryFeatureFlagStore(installId: 'device-install-0001');
    final flags = {'beta': _flag(pct: 0)};
    final s = _service((() async => _payload(flags, targeted: ['beta'])), store: store, user: 'u-1');
    await s.init();
    await _settle();
    expect(s.isEnabled('beta'), isTrue, reason: '0% rollout but whitelisted');

    // Cold start for a DIFFERENT user must not inherit u-1's whitelist offline.
    final other = _service((() async => throw StateError('offline')), store: store, user: 'u-2');
    await other.init();
    await _settle();
    expect(other.isEnabled('beta'), isFalse);

    // Same user offline keeps it.
    final same = _service((() async => throw StateError('offline')), store: store, user: 'u-1');
    await same.init();
    await _settle();
    expect(same.isEnabled('beta'), isTrue);
    s.dispose();
    other.dispose();
    same.dispose();
  });

  test('signed-out users never get whitelist hits', () async {
    final s = _service((() async => _payload({'beta': _flag(pct: 0)}, targeted: ['beta'])), user: null);
    await s.init();
    await _settle();
    expect(s.isEnabled('beta'), isFalse);
    s.dispose();
  });

  test('refreshes are single-flight and throttled', () async {
    var calls = 0;
    final gate = Completer<Object?>();
    final s = _service(() {
      calls++;
      return gate.future;
    });
    unawaited(s.init());
    await _settle();
    await _settle();
    final a = s.refresh();
    final b = s.refresh();
    expect(identical(a, b), isTrue);
    expect(calls, 1);
    gate.complete(_payload({'a_flag': _flag()}));
    await a;
    await s.refresh(); // within minInterval and not forced -> skipped
    expect(calls, 1);
    s.dispose();
  });

  test('isStale reflects the age of the last successful fetch', () async {
    var now = DateTime.utc(2026, 11, 15, 12);
    final s = _service((() async => _payload({'a_flag': _flag()})), now: () => now);
    expect(s.isStale, isTrue);
    await s.init();
    await _settle();
    expect(s.isStale, isFalse);
    now = now.add(const Duration(hours: 25));
    expect(s.isStale, isTrue);
    s.dispose();
  });

  test('FeatureFlagsPayload skips bad entries and rejects non-ok payloads', () {
    expect(FeatureFlagsPayload.tryParse({'ok': false}), isNull);
    expect(FeatureFlagsPayload.tryParse('x'), isNull);
    final p = FeatureFlagsPayload.tryParse({
      'ok': true,
      'flags': {'good': _flag(), 'bad': {'enabled': true}},
      'targeted_keys': ['good', 7],
    })!;
    expect(p.rules.keys, ['good']);
    expect(p.targetedKeys, {'good'});
  });
}
