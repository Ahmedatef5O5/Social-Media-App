import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:social_media_app/features/reels/services/reel_player_controller_pool.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class _MockController extends Mock implements YoutubePlayerController {}

void main() {
  const idA = 'dQw4w9WgXcQ';
  const idB = 'aqz-KE-bpKQ';

  late List<_MockController> created;
  late ReelPlayerControllerPool pool;

  _MockController makeController() {
    final c = _MockController();
    when(
      () => c.loadVideoById(videoId: any(named: 'videoId')),
    ).thenAnswer((_) async {});
    when(() => c.playVideo()).thenAnswer((_) async {});
    when(() => c.pauseVideo()).thenAnswer((_) async {});
    when(() => c.close()).thenAnswer((_) async {});
    created.add(c);
    return c;
  }

  setUp(() {
    created = [];
    pool = ReelPlayerControllerPool(controllerFactory: makeController);
  });

  group('video id validation', () {
    test('accepts only 11-char ids of [A-Za-z0-9_-]', () {
      expect(ReelPlayerControllerPool.isValidVideoId(idA), isTrue);
      expect(ReelPlayerControllerPool.isValidVideoId(idB), isTrue);
      expect(ReelPlayerControllerPool.isValidVideoId(''), isFalse);
      expect(ReelPlayerControllerPool.isValidVideoId('${idA}x'), isFalse);
      expect(
        ReelPlayerControllerPool.isValidVideoId("abc');alert(1);//"),
        isFalse,
      );
    });

    test('activate rejects a malformed id without creating a player', () {
      expect(() => pool.activate(0, 'bad id'), throwsArgumentError);
      expect(created, isEmpty);
      expect(pool.controller, isNull);
    });
  });

  group('activation', () {
    test('reading controller before activate creates nothing', () {
      expect(pool.controller, isNull);
      expect(created, isEmpty);
    });

    test('first activate creates one player and loads the video', () {
      final c = pool.activate(0, idA);

      expect(created.length, 1);
      expect(identical(c, created.first), isTrue);
      expect(identical(pool.controller, c), isTrue);
      expect(pool.activeIndex, 0);
      verify(() => created.first.loadVideoById(videoId: idA)).called(1);
    });

    test('same reel again resumes instead of creating a new player', () {
      pool.activate(0, idA);
      pool.activate(0, idA);

      expect(created.length, 1);
      verify(() => created.first.loadVideoById(videoId: idA)).called(1);
      verify(() => created.first.playVideo()).called(1);
    });

    test('another reel gets a FRESH controller (never a re-mounted one)', () {
      final first = pool.activate(0, idA);
      final second = pool.activate(1, idB);

      expect(created.length, 2);
      expect(identical(first, second), isFalse);
      expect(identical(pool.controller, second), isTrue);
      expect(pool.activeIndex, 1);
      expect(pool.isActive(0), isFalse);
      verify(() => created[1].loadVideoById(videoId: idB)).called(1);
      verifyNever(() => created[0].loadVideoById(videoId: idB));
    });
  });

  group('retiring and closing', () {
    test(
      'previous controller is retired, not closed, until disposeRetired',
      () async {
        pool.activate(0, idA);
        pool.activate(1, idB);

        expect(pool.retiredCount, 1);
        verifyNever(() => created[0].close());

        await pool.disposeRetired();

        expect(pool.retiredCount, 0);
        verify(() => created[0].close()).called(1);
        verifyNever(() => created[1].close());
      },
    );

    test('at most one live controller after each swap is cleaned up', () async {
      for (var i = 0; i < 12; i++) {
        pool.activate(i, 'video${i.toString().padLeft(6, '0')}');
        await pool.disposeRetired();
      }

      expect(created.length, 12);
      // Every controller except the current one has been closed exactly once.
      for (var i = 0; i < 11; i++) {
        verify(() => created[i].close()).called(1);
      }
      verifyNever(() => created[11].close());
    });
  });

  group('pause / play', () {
    test('pause and play are no-ops before anything is loaded', () {
      pool.pause();
      pool.play();
      expect(created, isEmpty);
    });

    test('pause and play reach the current player', () {
      pool.activate(0, idA);
      pool.pause();
      pool.play();

      verify(() => created.first.pauseVideo()).called(1);
      verify(() => created.first.playVideo()).called(1);
    });
  });

  group('disposeAll', () {
    test(
      'closes the current and the retired controllers once, idempotent',
      () async {
        pool.activate(0, idA);
        pool.activate(1, idB);

        await pool.disposeAll();
        await pool.disposeAll();

        verify(() => created[0].close()).called(1);
        verify(() => created[1].close()).called(1);
        expect(pool.controller, isNull);
      },
    );

    test('without a player does not fail', () async {
      await pool.disposeAll();
      expect(created, isEmpty);
    });

    test('using the pool after disposeAll fails loudly', () async {
      await pool.disposeAll();

      expect(() => pool.activate(0, idA), throwsStateError);
    });
  });
}
