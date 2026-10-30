import 'dart:async';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_media_app/core/guards/system_gate_decision.dart';
import 'package:social_media_app/core/services/app_system_status.dart';
import 'package:social_media_app/core/services/system_control_service.dart';

/// PRIORITY: P0 — remote control must FAIL OPEN.
///
/// A control plane that can lock users out when it is unreachable is worse than
/// having none. These tests pin: fail-open on every error shape, single-flight
/// refreshes, throttling, forced re-run after a user change, and boundary
/// wake-ups.
Map<String, Object?> payload({
  bool ok = true,
  bool maintenanceEnabled = false,
  bool maintenanceActive = false,
  bool bypassed = false,
  bool updateRequired = false,
  bool suspended = false,
  String? starts,
  String? ends,
  String? suspensionExpires,
  String? serverTime,
  String? banner,
  String severity = 'info',
}) => {
  'ok': ok,
  'server_time': serverTime ?? '2026-11-01T12:00:00Z',
  'maintenance_enabled': maintenanceEnabled,
  'maintenance_active': maintenanceActive,
  'maintenance_bypassed': bypassed,
  'maintenance_message': 'Back soon',
  'maintenance_starts_at': starts,
  'maintenance_ends_at': ends,
  'min_supported_version': '1.2.0',
  'recommended_version': '1.3.0',
  'update_required': updateRequired,
  'update_recommended': false,
  'banner_message': banner,
  'banner_severity': severity,
  'is_caller_suspended': suspended,
  'suspension_reason': suspended ? 'Spam' : null,
  'suspension_expires_at': suspensionExpires,
};

SystemControlService build(
  SystemStatusFetcher fetcher, {
  DateTime Function()? now,
  bool authed = true,
}) => SystemControlService(
  fetcher: fetcher,
  now: now ?? () => DateTime.utc(2026, 11, 1, 12),
  appVersion: () => '1.0.0+2',
  isAuthenticated: () => authed,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppSystemStatus.tryParse', () {
    test('rejects anything that is not a successful object', () {
      expect(AppSystemStatus.tryParse(null), isNull);
      expect(AppSystemStatus.tryParse('x'), isNull);
      expect(AppSystemStatus.tryParse(<String, Object?>{}), isNull);
      expect(AppSystemStatus.tryParse(payload(ok: false)), isNull);
    });

    test('parses every field and tolerates unknown severity', () {
      final s =
          AppSystemStatus.tryParse(
            payload(
              maintenanceEnabled: true,
              maintenanceActive: true,
              suspended: true,
              banner: '  Hello  ',
              severity: 'wat',
            ),
          )!;
      expect(s.blocksForMaintenance, isTrue);
      expect(s.maintenanceMessage, 'Back soon');
      expect(s.bannerMessage, 'Hello');
      expect(s.bannerSeverity, SystemBannerSeverity.info);
      expect(s.isCallerSuspended, isTrue);
      expect(s.suspensionReason, 'Spam');
    });

    test('bypassed callers are not blocked', () {
      final s =
          AppSystemStatus.tryParse(
            payload(maintenanceActive: true, bypassed: true),
          )!;
      expect(s.blocksForMaintenance, isFalse);
    });

    test('equality ignores serverTime', () {
      final a = AppSystemStatus.tryParse(
        payload(serverTime: '2026-11-01T12:00:00Z'),
      );
      final b = AppSystemStatus.tryParse(
        payload(serverTime: '2026-11-01T12:05:00Z'),
      );
      expect(a, b);
    });
  });

  group('composeAppVersion', () {
    test('builds version+build for the RPC', () {
      expect(SystemControlService.composeAppVersion('1.0.0', '2'), '1.0.0+2');
      expect(SystemControlService.composeAppVersion('1.4', '17'), '1.4+17');
    });
    test('dev builds are never gated', () {
      expect(SystemControlService.composeAppVersion('0.0.0-dev', '0'), isNull);
    });
    test('invalid or zero build falls back to the bare version', () {
      expect(SystemControlService.composeAppVersion('1.0.0', '0'), '1.0.0');
      expect(SystemControlService.composeAppVersion('1.0.0', 'abc'), '1.0.0');
    });
  });

  group('decideGate', () {
    AppSystemStatus s({
      bool block = false,
      bool update = false,
      bool susp = false,
    }) => AppSystemStatus(
      maintenanceActive: block,
      updateRequired: update,
      isCallerSuspended: susp,
    );

    test('priority: maintenance > update > suspension', () {
      expect(
        decideGate(
          s(block: true, update: true, susp: true),
          authenticated: true,
        ),
        GateScreen.maintenance,
      );
      expect(
        decideGate(s(update: true, susp: true), authenticated: true),
        GateScreen.forceUpdate,
      );
      expect(
        decideGate(s(susp: true), authenticated: true),
        GateScreen.suspended,
      );
      expect(decideGate(s(), authenticated: true), GateScreen.none);
    });

    test('suspension screen needs a signed-in caller', () {
      expect(decideGate(s(susp: true), authenticated: false), GateScreen.none);
    });

    test(
      'staff sign-in mode lets signed-out staff reach the login screen only',
      () {
        expect(
          decideGate(
            s(block: true),
            authenticated: false,
            staffSignInMode: true,
          ),
          GateScreen.none,
        );
        expect(
          decideGate(
            s(block: true),
            authenticated: true,
            staffSignInMode: true,
          ),
          GateScreen.maintenance,
        );
      },
    );
  });

  group('SystemControlService.refresh', () {
    test('starts open and applies a successful payload', () async {
      final svc = build((_) async => payload(maintenanceActive: true));
      expect(svc.status.value, AppSystemStatus.open);
      await svc.refresh(force: true);
      expect(svc.status.value.maintenanceActive, isTrue);
    });

    test('passes the app version to the RPC', () async {
      String? seen;
      final svc = build((v) async {
        seen = v;
        return payload();
      });
      await svc.refresh(force: true);
      expect(seen, '1.0.0+2');
    });

    test(
      'FAIL OPEN: an error keeps the previous status and never throws',
      () async {
        var fail = false;
        final svc = build((_) async {
          if (fail) throw Exception('SocketException');
          return payload(maintenanceActive: true);
        });
        await svc.refresh(force: true);
        fail = true;
        await svc.refresh(force: true); // must not throw
        expect(svc.status.value.maintenanceActive, isTrue);
      },
    );

    test('FAIL OPEN: cold start offline stays unrestricted', () async {
      final svc = build((_) async => throw Exception('offline'));
      await svc.refresh(force: true);
      expect(svc.status.value, AppSystemStatus.open);
      expect(svc.currentGate, GateScreen.none);
    });

    test('malformed payloads are ignored', () async {
      final svc = build((_) async => payload(maintenanceActive: true));
      await svc.refresh(force: true);
      final bad = build((_) async => {'ok': false});
      await bad.refresh(force: true);
      expect(bad.status.value, AppSystemStatus.open);
      expect(svc.status.value.maintenanceActive, isTrue);
    });

    test('a hung request times out instead of pinning the slot', () {
      fakeAsync((async) {
        var calls = 0;
        final svc = SystemControlService(
          fetcher: (_) {
            calls++;
            return Completer<Object?>().future; // never completes
          },
          timeout: const Duration(seconds: 8),
          isAuthenticated: () => true,
        );
        svc.refresh(force: true);
        async.elapse(const Duration(seconds: 9));
        svc.refresh(force: true);
        async.flushMicrotasks();
        expect(calls, 2);
      });
    });

    test('concurrent callers share one request', () async {
      var calls = 0;
      final gate = Completer<Object?>();
      final svc = build((_) {
        calls++;
        return gate.future;
      });
      final a = svc.refresh(force: true);
      final b = svc.refresh();
      gate.complete(payload());
      await Future.wait([a, b]);
      expect(calls, 1);
    });

    test(
      'non-forced calls inside minInterval are skipped; forced ones run',
      () async {
        var calls = 0;
        var t = DateTime.utc(2026, 11, 1, 12);
        final svc = build((_) async {
          calls++;
          return payload();
        }, now: () => t);
        await svc.refresh();
        await svc.refresh();
        expect(calls, 1);
        t = t.add(const Duration(seconds: 16));
        await svc.refresh();
        expect(calls, 2);
        await svc.refresh(force: true);
        expect(calls, 3);
      },
    );

    test('a forced call during a request re-runs once afterwards', () async {
      var calls = 0;
      final first = Completer<Object?>();
      final svc = build((_) {
        calls++;
        return calls == 1
            ? first.future
            : Future.value(payload(suspended: true));
      });
      final running = svc.refresh(force: true);
      svc.onAuthChanged(); // user changed mid-flight
      first.complete(payload());
      await running;
      await Future<void>.delayed(Duration.zero);
      expect(calls, 2);
      expect(svc.status.value.isCallerSuspended, isTrue);
    });

    test('onAuthChanged bumps the epoch and clears staff mode', () async {
      final svc = build((_) async => payload());
      svc.enterStaffSignInMode();
      final epoch = svc.authEpoch.value;
      svc.onAuthChanged();
      expect(svc.staffSignInMode.value, isFalse);
      expect(svc.authEpoch.value, epoch + 1);
    });
  });

  group('boundary wake-ups', () {
    test('refreshes when a scheduled maintenance window starts', () {
      fakeAsync((async) {
        var calls = 0;
        final svc = SystemControlService(
          fetcher: (_) async {
            calls++;
            return payload(
              maintenanceEnabled: true,
              starts: '2026-11-01T12:10:00Z',
              serverTime: '2026-11-01T12:00:00Z',
            );
          },
          isAuthenticated: () => true,
        );
        svc.refresh(force: true);
        async.flushMicrotasks();
        expect(calls, 1);
        async.elapse(const Duration(minutes: 9));
        expect(calls, 1);
        async.elapse(const Duration(minutes: 2));
        async.flushMicrotasks();
        expect(calls, 2);
      });
    });

    test('refreshes when a suspension expires', () {
      fakeAsync((async) {
        var calls = 0;
        final svc = SystemControlService(
          fetcher: (_) async {
            calls++;
            return payload(
              suspended: true,
              suspensionExpires: '2026-11-01T12:05:00Z',
              serverTime: '2026-11-01T12:00:00Z',
            );
          },
          isAuthenticated: () => true,
        );
        svc.refresh(force: true);
        async.flushMicrotasks();
        async.elapse(const Duration(minutes: 6));
        async.flushMicrotasks();
        expect(calls, 2);
      });
    });
  });
}
