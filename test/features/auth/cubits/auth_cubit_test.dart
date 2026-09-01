import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:social_media_app/core/services/network_status_service.dart';
import 'package:social_media_app/features/auth/cubits/auth_cubit/auth_cubit.dart';
import 'package:social_media_app/features/auth/services/supabase_auth_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_pkg;

class MockSupabaseAuthServices extends Mock implements SupabaseAuthServices {}

class MockNetworkStatusService extends Mock implements NetworkStatusService {}

class FakeUser extends Fake implements supabase_pkg.User {}

void main() {
  setUpAll(() {
    // mocktail needs a registered fallback for any() used with a custom
    // type — User is passed to ensureUserExistsInDb(...).
    registerFallbackValue(FakeUser());
  });

  late MockSupabaseAuthServices authServices;
  late MockNetworkStatusService networkStatus;
  late StreamController<supabase_pkg.AuthState> authStateController;

  supabase_pkg.User testUser({String id = 'user-1'}) => supabase_pkg.User(
    id: id,
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: DateTime.now().toIso8601String(),
  );

  supabase_pkg.Session testSession({
    required supabase_pkg.User user,
    required int expiresInSeconds,
  }) => supabase_pkg.Session(
    accessToken: 'test-access-token',
    tokenType: 'bearer',
    expiresIn: expiresInSeconds,
    user: user,
  );

  setUp(() {
    authServices = MockSupabaseAuthServices();
    networkStatus = MockNetworkStatusService();
    authStateController = StreamController<supabase_pkg.AuthState>.broadcast();
    when(
      () => authServices.authStateStream,
    ).thenAnswer((_) => authStateController.stream);
    when(
      () => authServices.ensureUserExistsInDb(any()),
    ).thenAnswer((_) async {});
  });

  tearDown(() async {
    await authStateController.close();
  });

  AuthCubit buildCubit() =>
      AuthCubit(authServices, networkStatus: networkStatus);

  group('auth-state stream reactions (_monitorAuthState)', () {
    blocTest<AuthCubit, AuthState>(
      'signedIn with a session → AuthSuccess, and syncs the user to the DB',
      build: buildCubit,
      act: (cubit) {
        authStateController.add(
          supabase_pkg.AuthState(
            supabase_pkg.AuthChangeEvent.signedIn,
            testSession(user: testUser(), expiresInSeconds: 3600),
          ),
        );
      },
      wait: const Duration(milliseconds: 10),
      expect: () => [isA<AuthSuccess>()],
      verify: (_) {
        verify(() => authServices.ensureUserExistsInDb(any())).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'initialSession with a session → AuthSuccess too (app cold-started '
      'with an already-valid persisted session)',
      build: buildCubit,
      act: (cubit) {
        authStateController.add(
          supabase_pkg.AuthState(
            supabase_pkg.AuthChangeEvent.initialSession,
            testSession(user: testUser(), expiresInSeconds: 3600),
          ),
        );
      },
      wait: const Duration(milliseconds: 10),
      expect: () => [isA<AuthSuccess>()],
    );

    blocTest<AuthCubit, AuthState>(
      'initialSession with no session is silently ignored — not an error, '
      'just "no persisted session to restore"',
      build: buildCubit,
      act: (cubit) {
        authStateController.add(
          const supabase_pkg.AuthState(
            supabase_pkg.AuthChangeEvent.initialSession,
            null,
          ),
        );
      },
      wait: const Duration(milliseconds: 10),
      expect: () => [],
    );

    blocTest<AuthCubit, AuthState>(
      'signedOut → AuthSignedOut',
      build: buildCubit,
      act: (cubit) {
        authStateController.add(
          const supabase_pkg.AuthState(
            supabase_pkg.AuthChangeEvent.signedOut,
            null,
          ),
        );
      },
      wait: const Duration(milliseconds: 10),
      expect: () => [isA<AuthSignedOut>()],
    );
  });

  group('signInWithEmail', () {
    blocTest<AuthCubit, AuthState>(
      'emits AuthLoading immediately; the actual AuthSuccess only comes '
      'from the auth-state stream, not from signInWithEmail itself',
      build: buildCubit,
      setUp:
          () => when(
            () => authServices.signInWithEmail(any(), any()),
          ).thenAnswer((_) async {}),
      act: (cubit) => cubit.signInWithEmail('a@b.com', 'password123'),
      expect: () => [isA<AuthLoading>()],
      verify: (_) {
        verify(
          () => authServices.signInWithEmail('a@b.com', 'password123'),
        ).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'a wrong-password AuthException maps to a user-facing AuthFailure',
      build: buildCubit,
      setUp:
          () =>
              when(() => authServices.signInWithEmail(any(), any())).thenThrow(
                const supabase_pkg.AuthException(
                  'Invalid login credentials',
                  code: 'invalid_credentials',
                ),
              ),
      act: (cubit) => cubit.signInWithEmail('a@b.com', 'wrong'),
      expect:
          () => [
            isA<AuthLoading>(),
            isA<AuthFailure>().having(
              (s) => s.errMsg,
              'errMsg',
              'Incorrect email or password. Please try again.',
            ),
          ],
    );

    blocTest<AuthCubit, AuthState>(
      'a "cancelled"-worded error resets to AuthInitial instead of '
      'showing a scary error for what was really just the user backing out',
      build: buildCubit,
      setUp:
          () => when(
            () => authServices.signInWithEmail(any(), any()),
          ).thenThrow(Exception('user_cancelled')),
      act: (cubit) => cubit.signInWithEmail('a@b.com', 'x'),
      expect: () => [isA<AuthLoading>(), isA<AuthInitial>()],
    );
  });

  group('signInWithGoogle', () {
    blocTest<AuthCubit, AuthState>(
      'an "aborted" error (user closed the picker) resets to AuthInitial, '
      'checked before generic error handling',
      build: buildCubit,
      setUp:
          () => when(
            () => authServices.signInWithGoogle(),
          ).thenThrow(Exception('sign_in_aborted')),
      act: (cubit) => cubit.signInWithGoogle(),
      expect: () => [isA<AuthLoading>(), isA<AuthInitial>()],
    );

    blocTest<AuthCubit, AuthState>(
      'any other error still goes through normal mapping → AuthFailure',
      build: buildCubit,
      setUp:
          () => when(
            () => authServices.signInWithGoogle(),
          ).thenThrow(Exception('some unexpected google error')),
      act: (cubit) => cubit.signInWithGoogle(),
      expect: () => [isA<AuthLoading>(), isA<AuthFailure>()],
    );
  });

  group('signInWithFacebook / signInWithMicrosoft — OAuth result timeout', () {
    // These exercise the Step-3 fix directly: Future.delayed(10s) was
    // replaced with stream.firstWhere(...).timeout(10s). fake_async lets
    // us prove the 10-second bound is real without a slow test suite.

    test('the OAuth browser flow resolving via the auth-state stream before '
        'the timeout does NOT get forced back to AuthInitial', () {
      fakeAsync((async) {
        when(() => authServices.signInWithFacebook()).thenAnswer((_) async {});
        final cubit = buildCubit();
        final states = <AuthState>[];
        cubit.stream.listen(states.add);

        cubit.signInWithFacebook();
        async.elapse(const Duration(seconds: 3));

        // The real Supabase auth stream fires "signedIn" once the
        // deep-link redirect completes — well inside the 10s bound.
        authStateController.add(
          supabase_pkg.AuthState(
            supabase_pkg.AuthChangeEvent.signedIn,
            testSession(user: testUser(), expiresInSeconds: 3600),
          ),
        );
        async.elapse(const Duration(milliseconds: 1));

        expect(states, [isA<AuthLoading>(), isA<AuthSuccess>()]);

        // Advancing well past the old fixed 10s wait must change
        // nothing — there is no pending timer left to fire.
        async.elapse(const Duration(seconds: 15));
        expect(states, [isA<AuthLoading>(), isA<AuthSuccess>()]);

        cubit.close();
      });
    });

    test('a hung OAuth flow (stream never resolves) falls back to '
        'AuthInitial exactly at the 10s bound, not before and not never', () {
      fakeAsync((async) {
        when(() => authServices.signInWithMicrosoft()).thenAnswer((_) async {});
        final cubit = buildCubit();
        final states = <AuthState>[];
        cubit.stream.listen(states.add);

        cubit.signInWithMicrosoft();

        async.elapse(const Duration(seconds: 9));
        expect(states, [isA<AuthLoading>()]); // still waiting

        async.elapse(const Duration(seconds: 2)); // crosses the 10s mark
        expect(states, [isA<AuthLoading>(), isA<AuthInitial>()]);

        cubit.close();
      });
    });
  });

  group('checkAuthStatus', () {
    blocTest<AuthCubit, AuthState>(
      'no cached session at all → AuthInitial',
      build: buildCubit,
      setUp: () => when(() => authServices.currentSession).thenReturn(null),
      act: (cubit) => cubit.checkAuthStatus(),
      expect: () => [isA<AuthInitial>()],
    );

    blocTest<AuthCubit, AuthState>(
      'a still-valid cached session → AuthSuccess immediately, no network '
      'call needed',
      build: buildCubit,
      setUp:
          () => when(
            () => authServices.currentSession,
          ).thenReturn(testSession(user: testUser(), expiresInSeconds: 3600)),
      act: (cubit) => cubit.checkAuthStatus(),
      expect: () => [isA<AuthSuccess>()],
      verify: (_) {
        verifyNever(() => networkStatus.isConnected());
      },
    );

    blocTest<AuthCubit, AuthState>(
      'an expired session while offline keeps the cached session rather '
      'than forcing a sign-out the user did not ask for',
      build: buildCubit,
      setUp: () {
        when(
          () => authServices.currentSession,
        ).thenReturn(testSession(user: testUser(), expiresInSeconds: -3600));
        when(() => networkStatus.isConnected()).thenAnswer((_) async => false);
      },
      act: (cubit) => cubit.checkAuthStatus(),
      expect: () => [isA<AuthSuccess>()],
      verify: (_) {
        verifyNever(() => authServices.refreshSession());
      },
    );

    blocTest<AuthCubit, AuthState>(
      'an expired session while online refreshes silently → AuthSuccess',
      build: buildCubit,
      setUp: () {
        when(
          () => authServices.currentSession,
        ).thenReturn(testSession(user: testUser(), expiresInSeconds: -3600));
        when(() => networkStatus.isConnected()).thenAnswer((_) async => true);
        when(() => authServices.refreshSession()).thenAnswer(
          (_) async => supabase_pkg.AuthResponse(
            session: testSession(user: testUser(), expiresInSeconds: 3600),
          ),
        );
      },
      act: (cubit) => cubit.checkAuthStatus(),
      expect: () => [isA<AuthSuccess>()],
    );

    // NOT COVERED: "expired + online + refresh comes back empty/throws"
    // (checkAuthStatus() falls through to signOut() in that case).
    // signOut() unconditionally calls PresenceService.instance first,
    // which reaches the real Supabase singleton — untestable here without
    // either a Supabase test harness or refactoring PresenceService the
    // same way NetworkStatusService was here, which is a bigger change
    // than this baseline covers. Flagging it rather than writing a test
    // that would only be exercising the PresenceService failure path
    // instead of the sign-out logic it's meant to test.
  });
}
