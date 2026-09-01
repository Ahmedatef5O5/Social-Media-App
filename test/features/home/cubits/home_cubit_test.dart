import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:social_media_app/features/auth/data/models/user_data.dart';
import 'package:social_media_app/features/home/cubits/home_cubit/home_cubit.dart';
import 'package:social_media_app/features/posts/cubits/posts_cubit/posts_cubit.dart';
import 'package:social_media_app/features/profile/services/user_services.dart';

class MockUserService extends Mock implements UserService {}

class MockPostsCubit extends MockCubit<PostsState> implements PostsCubit {}

class FakeUserData extends Fake implements UserData {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeUserData());
  });

  late MockUserService userService;
  late MockPostsCubit postsCubit;

  UserData testUser({String id = 'user-1', String name = 'Test User'}) =>
      UserData(id: id, name: name, email: 'test@example.com');

  setUp(() {
    userService = MockUserService();
    postsCubit = MockPostsCubit();
    when(() => postsCubit.setCurrentUser(any())).thenAnswer((_) {});
  });

  /// [HomeCubit] normally resolves the signed-in user's id via the real
  /// `SupabaseProvider.id` singleton, which throws unless Supabase has
  /// been initialized — impossible in a plain unit test process. The
  /// `currentUserIdProvider` seam added alongside this test file lets
  /// tests supply a fixed id instead; every real caller (see
  /// `di/cubit_providers.dart`) omits it and is unaffected.
  HomeCubit buildCubit({String Function()? currentUserIdProvider}) {
    return HomeCubit(
      userService: userService,
      postsCubit: postsCubit,
      currentUserIdProvider: currentUserIdProvider ?? (() => 'user-1'),
    );
  }

  group('getCurrentUserData', () {
    blocTest<HomeCubit, HomeState>(
      'success: emits UserDataLoading then UserDataLoaded, and pushes the '
      'user into PostsCubit so posts/likes reflect the right author',
      build: buildCubit,
      setUp:
          () => when(
            () => userService.fetchCurrentUser('user-1'),
          ).thenAnswer((_) async => testUser()),
      act: (cubit) => cubit.getCurrentUserData(),
      expect:
          () => [
            isA<UserDataLoading>(),
            isA<UserDataLoaded>().having(
              (s) => s.userData.id,
              'userData.id',
              'user-1',
            ),
          ],
      verify: (cubit) {
        verify(() => postsCubit.setCurrentUser(any())).called(1);
        expect(cubit.currentUserData?.id, 'user-1');
      },
    );

    blocTest<HomeCubit, HomeState>(
      'isRefresh: true skips the loading state — a pull-to-refresh should '
      'not flash a full-screen loading UI over already-visible content',
      build: buildCubit,
      setUp:
          () => when(
            () => userService.fetchCurrentUser('user-1'),
          ).thenAnswer((_) async => testUser()),
      act: (cubit) => cubit.getCurrentUserData(isRefresh: true),
      expect: () => [], // no UserDataLoading, and no UserDataLoaded either
      // (isRefresh also skips the UserDataLoaded emit — see source)
      verify: (cubit) {
        expect(cubit.currentUserData?.id, 'user-1');
      },
    );

    blocTest<HomeCubit, HomeState>(
      'a fetch failure with no disk snapshot available (LocalSnapshotStore '
      'is uninitialized in tests, so it always misses here) surfaces as '
      'UserDataLoadError with a mapped message',
      build: buildCubit,
      setUp:
          () => when(
            () => userService.fetchCurrentUser('user-1'),
          ).thenThrow(Exception('SocketException: fail')),
      act: (cubit) => cubit.getCurrentUserData(),
      expect:
          () => [
            isA<UserDataLoading>(),
            isA<UserDataLoadError>().having(
              (s) => s.message,
              'message',
              'no-internet',
            ),
          ],
    );

    blocTest<HomeCubit, HomeState>(
      'once a user was successfully loaded, a LATER failure (e.g. a '
      'pull-to-refresh gone wrong) is swallowed rather than wiping the '
      'screen the user is already looking at',
      build: buildCubit,
      setUp: () {
        var callCount = 0;
        when(() => userService.fetchCurrentUser('user-1')).thenAnswer((
          _,
        ) async {
          callCount++;
          if (callCount == 1) return testUser();
          throw Exception('network blip');
        });
      },
      act: (cubit) async {
        await cubit.getCurrentUserData(); // succeeds, populates currentUserData
        await cubit.getCurrentUserData(isRefresh: true); // fails silently
      },
      expect:
          () => [
            isA<UserDataLoading>(),
            isA<UserDataLoaded>(),
            // no further state — the second call's failure is caught and
            // dropped because currentUserData is already non-null.
          ],
    );
  });

  group('refreshUserData', () {
    // NOTE ON SCOPE: refreshUserData()'s own try/catch is effectively
    // unreachable in normal operation, because getCurrentUserData() (via
    // _getCurrentUser()) already catches every error itself and never
    // rethrows — this is dead code the same way SupabaseErrorMapper's
    // duplicate network check is (see that test file). The one way to
    // reach it at all is if resolving the user id itself throws, which
    // is exactly what a real `SupabaseProvider.id` access could do if
    // the session became invalid mid-lifetime — so that's what this
    // test simulates via the injectable id provider.
    blocTest<HomeCubit, HomeState>(
      'if resolving the user id itself throws with "no-internet" in the '
      'message, the connectivity banner fires and (with no cached user '
      'yet) UserDataLoadError shows the offline copy',
      build:
          () => buildCubit(
            currentUserIdProvider: () => throw Exception('no-internet'),
          ),
      act: (cubit) => cubit.refreshUserData(),
      expect:
          () => [
            isA<UserDataLoading>(),
            isA<UserDataLoadError>().having(
              (s) => s.message,
              'message',
              'No internet connection. Please check your network.',
            ),
          ],
    );
  });

  group('resetSession', () {
    blocTest<HomeCubit, HomeState>(
      'clears the cached user and returns to HomeInitial — used on sign-out '
      'so the next sign-in never shows a flash of the previous user',
      build: buildCubit,
      setUp:
          () => when(
            () => userService.fetchCurrentUser('user-1'),
          ).thenAnswer((_) async => testUser()),
      act: (cubit) async {
        await cubit
            .getCurrentUserData(); // genuinely populate currentUserData first
        cubit.resetSession();
      },
      expect:
          () => [
            isA<UserDataLoading>(),
            isA<UserDataLoaded>(),
            isA<HomeInitial>(),
          ],
      verify: (cubit) {
        expect(cubit.currentUserData, isNull);
      },
    );
  });
}
