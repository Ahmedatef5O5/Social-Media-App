import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_media_app/core/guards/force_update_dialog.dart';
import 'package:social_media_app/core/guards/maintenance_gate_screen.dart';
import 'package:social_media_app/core/guards/suspension_interceptor.dart';
import 'package:social_media_app/core/guards/system_banner.dart';
import 'package:social_media_app/core/guards/system_control_gate.dart';
import 'package:social_media_app/core/services/app_system_status.dart';
import 'package:social_media_app/core/services/system_control_service.dart';
import 'package:social_media_app/l10n/generated/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Requires the Feature B ARB keys (l10n_additions/) and `flutter gen-l10n`.
Widget host(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

SystemControlService service(AppSystemStatus initial, {bool authed = true}) {
  final s = SystemControlService(
    fetcher: (_) async => <String, Object?>{'ok': false},
    isAuthenticated: () => authed,
  );
  s.status.value = initial;
  return s;
}

void main() {
  const app = Text('APP-CONTENT');

  group('SystemControlGate', () {
    testWidgets('shows only the app when nothing is restricted', (tester) async {
      await tester.pumpWidget(
        host(SystemControlGate(service: service(AppSystemStatus.open), child: app)),
      );
      expect(find.text('APP-CONTENT'), findsOneWidget);
      expect(find.byType(MaintenanceGateScreen), findsNothing);
    });

    testWidgets('maintenance covers the app and shows the admin message', (tester) async {
      final svc = service(
        const AppSystemStatus(
          maintenanceActive: true,
          maintenanceMessage: 'DB upgrade in progress',
        ),
      );
      await tester.pumpWidget(host(SystemControlGate(service: svc, child: app)));
      expect(find.byType(MaintenanceGateScreen), findsOneWidget);
      expect(find.text('DB upgrade in progress'), findsOneWidget);
      expect(find.text('Check again'), findsOneWidget);
    });

    testWidgets('falls back to the default message and Arabic copy', (tester) async {
      final svc = service(const AppSystemStatus(maintenanceActive: true));
      await tester.pumpWidget(
        host(
          SystemControlGate(service: svc, child: app),
          locale: const Locale('ar'),
        ),
      );
      expect(find.text('سنعود قريبًا'), findsOneWidget);
    });

    testWidgets('bypassed callers are never blocked', (tester) async {
      final svc = service(
        const AppSystemStatus(maintenanceActive: true, maintenanceBypassed: true),
      );
      await tester.pumpWidget(host(SystemControlGate(service: svc, child: app)));
      expect(find.byType(MaintenanceGateScreen), findsNothing);
    });

    testWidgets('disappears by itself when maintenance is lifted', (tester) async {
      final svc = service(const AppSystemStatus(maintenanceActive: true));
      await tester.pumpWidget(host(SystemControlGate(service: svc, child: app)));
      expect(find.byType(MaintenanceGateScreen), findsOneWidget);
      svc.status.value = AppSystemStatus.open;
      await tester.pump();
      expect(find.byType(MaintenanceGateScreen), findsNothing);
    });

    testWidgets('signed-out staff can enter sign-in mode', (tester) async {
      final svc = service(
        const AppSystemStatus(maintenanceActive: true),
        authed: false,
      );
      await tester.pumpWidget(host(SystemControlGate(service: svc, child: app)));
      await tester.tap(find.text('Staff sign in'));
      await tester.pump();
      expect(find.byType(MaintenanceGateScreen), findsNothing);
    });

    testWidgets('the blocked app is removed from semantics', (tester) async {
      final svc = service(const AppSystemStatus(maintenanceActive: true));
      await tester.pumpWidget(host(SystemControlGate(service: svc, child: app)));
      expect(find.byType(ExcludeSemantics), findsWidgets);
      expect(find.text('APP-CONTENT', skipOffstage: false), findsOneWidget);
    });

    testWidgets('forced update blocks and opens the store', (tester) async {
      String? opened;
      final svc = service(
        const AppSystemStatus(updateRequired: true, minSupportedVersion: '1.5.0'),
      );
      await tester.pumpWidget(
        host(
          SystemControlGate(
            service: svc,
            storeUrl: 'https://store.example/app',
            openStore: (u) async {
              opened = u;
              return true;
            },
            child: app,
          ),
        ),
      );
      expect(find.byType(ForceUpdateDialog), findsOneWidget);
      expect(find.textContaining('1.5.0'), findsOneWidget);
      await tester.tap(find.text('Update now'));
      await tester.pump();
      expect(opened, 'https://store.example/app');
    });

    testWidgets('a failed store launch shows an inline message', (tester) async {
      final svc = service(
        const AppSystemStatus(updateRequired: true, minSupportedVersion: '1.5.0'),
      );
      await tester.pumpWidget(
        host(
          SystemControlGate(
            service: svc,
            storeUrl: 'https://store.example/app',
            openStore: (_) async => false,
            child: app,
          ),
        ),
      );
      await tester.tap(find.text('Update now'));
      await tester.pump();
      expect(find.textContaining("Couldn't open the store"), findsOneWidget);
    });

    testWidgets('suspension shows reason, expiry and signs out', (tester) async {
      var signedOut = false;
      final svc = service(
        AppSystemStatus(
          isCallerSuspended: true,
          suspensionReason: 'Repeated spam',
          suspensionExpiresAt: DateTime(2027, 1, 15, 9, 30),
        ),
      );
      await tester.pumpWidget(
        host(
          SystemControlGate(
            service: svc,
            onSignOut: (_) async => signedOut = true,
            child: app,
          ),
        ),
      );
      expect(find.byType(SuspensionScreen), findsOneWidget);
      expect(find.text('Repeated spam'), findsOneWidget);
      expect(find.textContaining('Jan'), findsOneWidget);
      await tester.tap(find.text('Sign out'));
      await tester.pump();
      expect(signedOut, isTrue);
    });

    testWidgets('permanent suspension says there is no end date', (tester) async {
      final svc = service(
        const AppSystemStatus(isCallerSuspended: true, suspensionReason: 'Abuse'),
      );
      await tester.pumpWidget(
        host(SystemControlGate(service: svc, onSignOut: (_) async {}, child: app)),
      );
      expect(find.text('This suspension has no end date.'), findsOneWidget);
    });
  });

  group('banners', () {
    testWidgets('broadcast banner shows above the app and can be dismissed', (tester) async {
      final svc = service(
        const AppSystemStatus(
          bannerMessage: 'Calls may be slow',
          bannerSeverity: SystemBannerSeverity.warning,
        ),
      );
      await tester.pumpWidget(host(SystemControlGate(service: svc, child: app)));
      expect(find.text('Calls may be slow'), findsOneWidget);
      expect(find.text('APP-CONTENT'), findsOneWidget);
      await tester.tap(find.byTooltip('Dismiss'));
      await tester.pump();
      expect(find.text('Calls may be slow'), findsNothing);
    });

    testWidgets('critical banners cannot be dismissed', (tester) async {
      final svc = service(
        const AppSystemStatus(
          bannerMessage: 'Outage',
          bannerSeverity: SystemBannerSeverity.critical,
        ),
      );
      await tester.pumpWidget(host(SystemControlGate(service: svc, child: app)));
      expect(find.byTooltip('Dismiss'), findsNothing);
    });

    testWidgets('recommended update is a dismissible bar, not a block', (tester) async {
      final svc = service(
        const AppSystemStatus(updateRecommended: true, recommendedVersion: '1.6.0'),
      );
      await tester.pumpWidget(
        host(
          SystemControlGate(
            service: svc,
            storeUrl: 'https://store.example/app',
            child: app,
          ),
        ),
      );
      expect(find.byType(ForceUpdateDialog), findsNothing);
      expect(find.textContaining('1.6.0'), findsOneWidget);
      await tester.tap(find.byTooltip('Dismiss'));
      await tester.pump();
      expect(find.textContaining('1.6.0'), findsNothing);
    });

    test('visibility helpers respect dismissals and forced updates', () {
      const s = AppSystemStatus(
        updateRecommended: true,
        updateRequired: true,
        recommendedVersion: '2.0.0',
      );
      expect(shouldShowRecommendedUpdate(s, {}), isFalse);
    });
  });

  group('SuspensionInterceptor', () {
    setUp(SuspensionInterceptor.resetThrottle);

    test('recognises RLS rejections only', () {
      expect(
        SuspensionInterceptor.looksLikePermissionRejection(
          const PostgrestException(message: 'new row violates row-level security policy', code: '42501'),
        ),
        isTrue,
      );
      expect(
        SuspensionInterceptor.looksLikePermissionRejection(
          const PostgrestException(message: 'not found', code: 'PGRST116'),
        ),
        isFalse,
      );
      expect(SuspensionInterceptor.looksLikePermissionRejection(Exception('x')), isFalse);
    });

    test('triggers one throttled forced status check', () async {
      var calls = 0;
      final svc = SystemControlService(
        fetcher: (_) async {
          calls++;
          return <String, Object?>{'ok': true};
        },
        isAuthenticated: () => true,
      );
      const err = PostgrestException(message: 'rls', code: '42501');
      SuspensionInterceptor.onError(err, service: svc);
      SuspensionInterceptor.onError(err, service: svc);
      await Future<void>.delayed(Duration.zero);
      expect(calls, 1);
    });

    test('guard rethrows the original error', () async {
      final svc = SystemControlService(
        fetcher: (_) async => <String, Object?>{'ok': false},
        isAuthenticated: () => true,
      );
      expect(
        () => SuspensionInterceptor.guard<void>(
          () async => throw StateError('boom'),
          service: svc,
        ),
        throwsStateError,
      );
    });
  });
}
