import 'package:flutter_test/flutter_test.dart';
import 'package:social_media_app/features/posts/helpers/feed_window.dart';

void main() {
  final t0 = DateTime.utc(2026, 10, 9, 8);
  final t1 = DateTime.utc(2026, 10, 9, 9);

  group('FeedWindow', () {
    test('first request uses the first page size and cannot load more yet', () {
      const w = FeedWindow.initial();
      expect(w.nextLimit, FeedWindow.firstPageSize);
      expect(w.canLoadMore, isFalse);
      expect(w.asOf, isNull);
    });

    test(
      'a full first page allows loading more with the regular page size',
      () {
        final w = const FeedWindow.initial().afterFetch(
          requested: FeedWindow.firstPageSize,
          rankedCount: FeedWindow.firstPageSize,
          asOf: t0,
        );
        expect(w.offset, FeedWindow.firstPageSize);
        expect(w.exhausted, isFalse);
        expect(w.canLoadMore, isTrue);
        expect(w.nextLimit, FeedWindow.pageSize);
      },
    );

    test('a short page means the feed is exhausted', () {
      final w = const FeedWindow.initial().afterFetch(
        requested: FeedWindow.firstPageSize,
        rankedCount: 12,
        asOf: t0,
      );
      expect(w.exhausted, isTrue);
      expect(w.canLoadMore, isFalse);
    });

    test('exactly the requested count is NOT proof of the end', () {
      final w = const FeedWindow.initial().afterFetch(
        requested: FeedWindow.firstPageSize,
        rankedCount: FeedWindow.firstPageSize,
        asOf: t0,
      );
      expect(w.exhausted, isFalse);
    });

    test('offset accumulates across pages', () {
      var w = const FeedWindow.initial().afterFetch(
        requested: FeedWindow.firstPageSize,
        rankedCount: FeedWindow.firstPageSize,
        asOf: t0,
      );
      w = w.afterFetch(
        requested: FeedWindow.pageSize,
        rankedCount: FeedWindow.pageSize,
        asOf: t0,
      );
      expect(w.offset, FeedWindow.firstPageSize + FeedWindow.pageSize);
    });

    test('the first non-null asOf wins and is never overwritten', () {
      var w = const FeedWindow.initial().afterFetch(
        requested: FeedWindow.firstPageSize,
        rankedCount: FeedWindow.firstPageSize,
        asOf: t0,
      );
      w = w.afterFetch(
        requested: FeedWindow.pageSize,
        rankedCount: FeedWindow.pageSize,
        asOf: t1,
      );
      expect(w.asOf, t0);
    });

    test('a null asOf from an old server is tolerated', () {
      final w = const FeedWindow.initial().afterFetch(
        requested: FeedWindow.firstPageSize,
        rankedCount: FeedWindow.firstPageSize,
        asOf: null,
      );
      expect(w.asOf, isNull);
      expect(w.canLoadMore, isTrue);
    });

    test('the ceiling stops growth and the last page never overshoots it', () {
      var w = const FeedWindow.initial().afterFetch(
        requested: FeedWindow.firstPageSize,
        rankedCount: FeedWindow.firstPageSize,
        asOf: t0,
      );
      while (w.canLoadMore) {
        final limit = w.nextLimit;
        expect(w.offset + limit, lessThanOrEqualTo(FeedWindow.maxItems));
        w = w.afterFetch(requested: limit, rankedCount: limit, asOf: t0);
      }
      expect(w.offset, FeedWindow.maxItems);
      expect(w.exhausted, isTrue);
    });
  });
}
