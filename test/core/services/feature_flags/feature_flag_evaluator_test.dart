import 'package:flutter_test/flutter_test.dart';
import 'package:social_media_app/core/services/feature_flags/feature_flag_evaluator.dart';

/// Golden vectors come from an independent implementation (Python hashlib) and
/// are the SAME ones asserted in migrations/tests/019_feature_flags.test.sql.
const _salt = 'feature-flag-test-salt';
const _key = 'new_feed';

String _id(int i) => '00000000-0000-4000-8000-${i.toString().padLeft(12, '0')}';

FeatureFlagRule _rule({
  bool enabled = true,
  bool kill = false,
  int pct = 100,
  List<String> platforms = const ['android', 'ios', 'web'],
  List<String> envs = const ['production', 'staging'],
  String? min,
  String? max,
  DateTime? starts,
  DateTime? ends,
  bool fallback = false,
  String salt = _salt,
  String key = _key,
}) => FeatureFlagRule(
  key: key,
  salt: salt,
  enabled: enabled,
  killSwitch: kill,
  rolloutPercentage: pct,
  targetPlatforms: platforms,
  targetEnvironments: envs,
  minAppVersion: min,
  maxAppVersion: max,
  startsAt: starts,
  endsAt: ends,
  defaultFallback: fallback,
);

FeatureFlagContext _ctx({
  String platform = 'android',
  String env = 'production',
  String? version = '1.2.0+5',
  String id = 'user-1',
  DateTime? now,
}) => FeatureFlagContext(
  platform: platform,
  environment: env,
  appVersion: version,
  identifier: id,
  now: now ?? DateTime.utc(2026, 11, 15, 12),
);

void main() {
  const evaluator = FeatureFlagEvaluator();

  group('calculateBucket', () {
    test('matches the cross-language golden vectors', () {
      expect(calculateBucket(_salt, _key, _id(0)), 4);
      expect(calculateBucket(_salt, _key, _id(1)), 24);
      expect(calculateBucket(_salt, _key, 'a1b2c3d4-0000-4000-8000-00000000abcd'), 69);
      expect(calculateBucket(_salt, _key, 'device-install-0001'), 51);
      expect(calculateBucket(_salt, 'other_flag', _id(1)), 2);
      expect(calculateBucket('another-salt', _key, _id(1)), 32);
    });

    test('is always within 1..100 and stable across calls', () {
      for (var i = 0; i < 1000; i++) {
        final b = calculateBucket(_salt, _key, _id(i));
        expect(b, inInclusiveRange(1, 100));
        expect(calculateBucket(_salt, _key, _id(i)), b);
      }
    });
  });

  group('rollout distribution', () {
    int enabledAt(int pct) {
      final rule = _rule(pct: pct);
      var n = 0;
      for (var i = 0; i < 1000; i++) {
        if (evaluator.evaluate(rule, _ctx(id: _id(i)))) n++;
      }
      return n;
    }

    test('25% of 1000 users enables 220..280 with zero variance on re-runs', () {
      final first = enabledAt(25);
      expect(first, inInclusiveRange(220, 280));
      for (var run = 0; run < 5; run++) {
        expect(enabledAt(25), first);
      }
      expect(first, 254); // exact value from the Python reference
    });

    test('0% enables nobody, 100% enables everybody', () {
      expect(enabledAt(0), 0);
      expect(enabledAt(100), 1000);
    });

    test('cohorts are monotonic: enabled at 5% stays enabled at 10% and 25%', () {
      final r5 = _rule(pct: 5), r10 = _rule(pct: 10), r25 = _rule(pct: 25);
      var seenAt5 = 0;
      for (var i = 0; i < 1000; i++) {
        final c = _ctx(id: _id(i));
        if (evaluator.evaluate(r5, c)) {
          seenAt5++;
          expect(evaluator.evaluate(r10, c), isTrue, reason: 'user $i dropped at 10%');
          expect(evaluator.evaluate(r25, c), isTrue, reason: 'user $i dropped at 25%');
        }
        if (evaluator.evaluate(r10, c)) {
          expect(evaluator.evaluate(r25, c), isTrue);
        }
      }
      expect(seenAt5, 46);
    });

    test('rotating the salt reshuffles the cohort', () {
      final a = _rule(pct: 25), b = _rule(pct: 25, salt: 'rotated');
      var differing = 0;
      for (var i = 0; i < 1000; i++) {
        final c = _ctx(id: _id(i));
        if (evaluator.evaluate(a, c) != evaluator.evaluate(b, c)) differing++;
      }
      expect(differing, greaterThan(100));
    });
  });

  group('pipeline order', () {
    test('1. kill switch beats everything, even a whitelisted user at 100%', () {
      final d = evaluator.evaluateDetailed(_rule(kill: true), _ctx(), whitelisted: true);
      expect(d.enabled, isFalse);
      expect(d.reason, FeatureFlagReason.killSwitch);
    });

    test('1. kill switch beats default_fallback = true', () {
      expect(evaluator.evaluate(_rule(kill: true, fallback: true), _ctx()), isFalse);
    });

    test('2. disabled flag is false', () {
      expect(evaluator.evaluateDetailed(_rule(enabled: false), _ctx()).reason, FeatureFlagReason.disabled);
    });

    test('3. schedule window', () {
      final now = DateTime.utc(2026, 11, 15, 12);
      expect(evaluator.evaluateDetailed(_rule(starts: now.add(const Duration(hours: 1))), _ctx(now: now)).reason,
          FeatureFlagReason.notStarted);
      expect(evaluator.evaluateDetailed(_rule(ends: now), _ctx(now: now)).reason, FeatureFlagReason.ended);
      expect(evaluator.evaluate(_rule(starts: now, ends: now.add(const Duration(hours: 1))), _ctx(now: now)), isTrue);
    });

    test('4. platform gate', () {
      expect(evaluator.evaluateDetailed(_rule(platforms: ['ios']), _ctx(platform: 'android')).reason,
          FeatureFlagReason.platformExcluded);
      expect(evaluator.evaluate(_rule(platforms: ['android']), _ctx(platform: 'android')), isTrue);
    });

    test('4b. environment gate (dev builds are excluded by the default rule)', () {
      expect(evaluator.evaluateDetailed(_rule(), _ctx(env: 'dev')).reason, FeatureFlagReason.environmentExcluded);
      expect(evaluator.evaluate(_rule(envs: ['dev', 'production']), _ctx(env: 'dev')), isTrue);
    });

    test('5. version bounds', () {
      expect(evaluator.evaluate(_rule(min: '1.3.0'), _ctx(version: '1.2.0+5')), isFalse);
      expect(evaluator.evaluate(_rule(min: '1.2.0'), _ctx(version: '1.2.0+5')), isTrue);
      expect(evaluator.evaluate(_rule(max: '1.1.9'), _ctx(version: '1.2.0+5')), isFalse);
      expect(evaluator.evaluate(_rule(min: '1.0.0', max: '2.0.0'), _ctx(version: '1.9.9+1')), isTrue);
    });

    test('5. a bound without a build number ignores the build (max 1.2.0 includes 1.2.0+7)', () {
      expect(evaluator.evaluate(_rule(max: '1.2.0'), _ctx(version: '1.2.0+7')), isTrue);
      expect(evaluator.evaluate(_rule(max: '1.2.0+3'), _ctx(version: '1.2.0+7')), isFalse);
      expect(evaluator.evaluate(_rule(min: '1.2.0+9'), _ctx(version: '1.2.0+7')), isFalse);
    });

    test('5. unknown app version never passes a version-gated flag', () {
      expect(evaluator.evaluateDetailed(_rule(min: '1.0.0'), _ctx(version: null)).reason,
          FeatureFlagReason.versionOutOfRange);
      expect(evaluator.evaluate(_rule(), _ctx(version: null)), isTrue); // no bounds: unaffected
    });

    test('6. whitelist bypasses the percentage but not schedule / platform / version', () {
      final zero = _rule(pct: 0);
      expect(evaluator.evaluateDetailed(zero, _ctx(), whitelisted: true).reason, FeatureFlagReason.whitelisted);
      expect(evaluator.evaluate(_rule(pct: 0, platforms: ['ios']), _ctx(platform: 'android'), whitelisted: true), isFalse);
      expect(evaluator.evaluate(_rule(pct: 0, min: '9.0.0'), _ctx(), whitelisted: true), isFalse);
    });

    test('8. outside the bucket returns default_fallback', () {
      // _id(0) has bucket 4 -> outside a 3% rollout.
      final ctx = _ctx(id: _id(0));
      expect(evaluator.evaluate(_rule(pct: 3), ctx), isFalse);
      expect(evaluator.evaluate(_rule(pct: 3, fallback: true), ctx), isTrue);
      expect(evaluator.evaluate(_rule(pct: 4), ctx), isTrue);
    });

    test('any unexpected error yields default_fallback instead of throwing', () {
      final broken = FeatureFlagRule(
        key: _key,
        salt: _salt,
        enabled: true,
        rolloutPercentage: 50,
        defaultFallback: true,
        // contains() throws: simulates any unexpected runtime failure
        targetPlatforms: _ThrowingList(),
      );
      final d = evaluator.evaluateDetailed(broken, _ctx());
      expect(d.enabled, isTrue);
      expect(d.reason, FeatureFlagReason.error);
    });
  });

  group('FeatureFlagRule.tryParse', () {
    test('parses the server contract and never exposes user ids', () {
      final rule = FeatureFlagRule.tryParse(_key, {
        'managed': true,
        'enabled': true,
        'kill_switch': false,
        'rollout_percentage': 25,
        'target_platforms': ['android'],
        'target_environments': ['production'],
        'min_app_version': '1.2.0',
        'max_app_version': null,
        'starts_at': '2026-11-01T00:00:00+00:00',
        'ends_at': null,
        'salt': _salt,
        'default_fallback': false,
        'target_user_count': 3,
      })!;
      expect(rule.rolloutPercentage, 25);
      expect(rule.targetUserCount, 3);
      expect(rule.startsAt, DateTime.utc(2026, 11, 1));
      expect(rule.toJson().containsKey('target_user_ids'), isFalse);
    });

    test('rejects entries without a salt and tolerates garbage', () {
      expect(FeatureFlagRule.tryParse(_key, {'enabled': true}), isNull);
      expect(FeatureFlagRule.tryParse(_key, 'nope'), isNull);
      expect(FeatureFlagRule.tryParse(_key, {'salt': 's', 'rollout_percentage': 500})!.rolloutPercentage, 100);
    });
  });
}

class _ThrowingList implements List<String> {
  @override
  bool contains(Object? element) => throw StateError('boom');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
