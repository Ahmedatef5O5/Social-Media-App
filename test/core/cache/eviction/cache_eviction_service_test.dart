import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:social_media_app/core/cache/datasources/media_local_data_source.dart';
import 'package:social_media_app/core/cache/entities/media_cache_entry.dart';
import 'package:social_media_app/core/cache/eviction/cache_eviction_service.dart';
import 'package:social_media_app/core/cache/models/cached_media_model.dart';

class MockMediaLocalDataSource extends Mock implements MediaLocalDataSource {}

class MockBox extends Mock implements Box<dynamic> {}

void main() {
  late MockMediaLocalDataSource dataSource;
  late MockBox metaBox;
  late CacheEvictionService service;

  MediaCacheEntry entry({
    required String url,
    required String featureFolder,
    required DateTime cachedAt,
  }) {
    return MediaCacheEntry(
      secureUrl: url,
      mediaType: CachedMediaType.image,
      featureFolder: featureFolder,
      cachedAt: cachedAt,
      lastAccessedAt: cachedAt,
    );
  }

  setUp(() {
    dataSource = MockMediaLocalDataSource();
    metaBox = MockBox();
    when(() => dataSource.removeCachedMedia(any())).thenAnswer((_) async {});
    when(() => metaBox.put(any(), any())).thenAnswer((_) async {});
    when(() => metaBox.get(any())).thenReturn(null);
    service = CacheEvictionService(
      localDataSource: dataSource,
      metaBox: metaBox,
    );
  });

  group('runSweep', () {
    test('removes only expired entries, keeps fresh ones', () async {
      final now = DateTime.now();
      when(() => dataSource.getAllCachedEntries()).thenReturn([
        // 'stories' TTL is 24h — 2 days old is expired.
        entry(
          url: 'expired-story',
          featureFolder: 'stories',
          cachedAt: now.subtract(const Duration(days: 2)),
        ),
        // 'posts' TTL is 7 days — 1 hour old is fresh.
        entry(
          url: 'fresh-post',
          featureFolder: 'posts',
          cachedAt: now.subtract(const Duration(hours: 1)),
        ),
        // Unknown folder falls back to the 1-day default TTL — 2 days
        // old is expired under that default.
        entry(
          url: 'expired-unknown-folder',
          featureFolder: 'some_new_feature_nobody_registered_yet',
          cachedAt: now.subtract(const Duration(days: 2)),
        ),
      ]);

      final removedCount = await service.runSweep();

      expect(removedCount, 2);
      verify(() => dataSource.removeCachedMedia('expired-story')).called(1);
      verify(
        () => dataSource.removeCachedMedia('expired-unknown-folder'),
      ).called(1);
      verifyNever(() => dataSource.removeCachedMedia('fresh-post'));
    });

    test(
      'records the run timestamp and removed count in the meta box',
      () async {
        when(() => dataSource.getAllCachedEntries()).thenReturn([
          entry(
            url: 'expired',
            featureFolder: 'chats',
            cachedAt: DateTime.now().subtract(const Duration(days: 10)),
          ),
        ]);

        await service.runSweep();

        verify(() => metaBox.put('last_eviction_run_at', any())).called(1);
        verify(() => metaBox.put('last_eviction_removed_count', 1)).called(1);
      },
    );

    test('an empty cache is a no-op that still records the run', () async {
      when(() => dataSource.getAllCachedEntries()).thenReturn([]);

      final removedCount = await service.runSweep();

      expect(removedCount, 0);
      verifyNever(() => dataSource.removeCachedMedia(any()));
      verify(() => metaBox.put('last_eviction_removed_count', 0)).called(1);
    });

    test(
      'a second call while a sweep is in-flight is skipped, not run twice',
      () async {
        // Hang on removeCachedMedia (an async, awaited call) so the first
        // runSweep() is still "in flight" — with `_isSweeping` already
        // true — when we fire the second one.
        final removeCompleter = Completer<void>();
        when(() => dataSource.getAllCachedEntries()).thenReturn([
          entry(
            url: 'expired',
            featureFolder: 'chats',
            cachedAt: DateTime.now().subtract(const Duration(days: 10)),
          ),
        ]);
        when(
          () => dataSource.removeCachedMedia(any()),
        ).thenAnswer((_) => removeCompleter.future);

        final first = service.runSweep();
        final secondResult = await service.runSweep();

        // The overlapping call must short-circuit to 0 immediately,
        // never touching the data source itself.
        expect(secondResult, 0);

        removeCompleter.complete();
        final firstResult = await first;
        expect(firstResult, 1);

        // getAllCachedEntries must only ever have been called once — by
        // the first sweep. The second call returned before reaching it.
        verify(() => dataSource.getAllCachedEntries()).called(1);
      },
    );
  });

  group('lastRunAt', () {
    test('returns null when the meta box has no recorded run yet', () {
      when(() => metaBox.get('last_eviction_run_at')).thenReturn(null);
      expect(service.lastRunAt, isNull);
    });

    test('parses a previously-stored ISO timestamp', () {
      final stored = DateTime(2026, 1, 15, 10, 30);
      when(
        () => metaBox.get('last_eviction_run_at'),
      ).thenReturn(stored.toIso8601String());

      expect(service.lastRunAt, stored);
    });

    test('a corrupted timestamp string returns null instead of throwing', () {
      when(
        () => metaBox.get('last_eviction_run_at'),
      ).thenReturn('not-a-valid-date');

      expect(service.lastRunAt, isNull);
    });
  });
}
