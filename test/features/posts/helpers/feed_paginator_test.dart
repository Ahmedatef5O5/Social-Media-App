import 'package:flutter_test/flutter_test.dart';
import 'package:social_media_app/features/posts/helpers/feed_paginator.dart';

/// PRIORITY: P1 — core business logic (V6 C-03).
///
/// `PostsServices.fetchPosts()` currently issues `.select().or().order()`
/// with no `.range()` and no `.limit()`: the feed downloads every post the
/// user is allowed to see, on every cold start and every pull-to-refresh.
/// Across `lib/` there are 101 `.select()` calls against 15
/// `.range()/.limit()` calls, so this is a pattern, not a one-off.
///
/// The fix has two halves. This file tests the half that is pure logic —
/// cursor advance, deduplication, ordering, end-of-feed — so that every
/// boundary condition is pinned before any Supabase query changes. The
/// query half is a separate, opt-in step (see PATCHES.md) precisely
/// because the feed UI merges posts with reels by index and must be wired
/// deliberately.
class _Post {
  const _Post(this.id, this.createdAt, {this.likes = 0});
  final String id;
  final DateTime createdAt;
  final int likes;
}

void main() {
  final epoch = DateTime.utc(2026, 1, 1);
  DateTime at(int minutes) => epoch.add(Duration(minutes: minutes));

  const pageSize = 3;
  final paginator = FeedPaginator<_Post>(
    idOf: (p) => p.id,
    createdAtOf: (p) => p.createdAt,
    pageSize: pageSize,
  );

  List<String> idsOf(FeedPaginationState<_Post> s) =>
      s.items.map((p) => p.id).toList();

  group('initial state', () {
    test('starts empty, with no cursor and not at the end', () {
      final state = paginator.initial();
      expect(state.items, isEmpty);
      expect(state.cursor, isNull);
      expect(state.hasReachedEnd, isFalse);
      expect(state.loadedPages, 0);
    });

    test('canLoadMore is false before the first page — there is nothing to '
        'page from yet', () {
      expect(
        paginator.canLoadMore(paginator.initial(), isLoading: false),
        isFalse,
      );
    });
  });

  group('first page', () {
    test('a full page sets the cursor to the OLDEST item and does not claim '
        'the end', () {
      final state = paginator.applyPage(paginator.initial(), [
        _Post('a', at(30)),
        _Post('b', at(20)),
        _Post('c', at(10)),
      ], isFirstPage: true);

      expect(idsOf(state), ['a', 'b', 'c']);
      expect(state.cursor, at(10));
      expect(state.hasReachedEnd, isFalse);
      expect(state.loadedPages, 1);
    });

    test('a SHORT page means end-of-feed: asking for 3 and getting 2 is the '
        'only reliable proof there is no more', () {
      final state = paginator.applyPage(paginator.initial(), [
        _Post('a', at(20)),
        _Post('b', at(10)),
      ], isFirstPage: true);

      expect(state.hasReachedEnd, isTrue);
      expect(paginator.canLoadMore(state, isLoading: false), isFalse);
    });

    test('an empty first page is the empty-feed state, not an error', () {
      final state = paginator.applyPage(
        paginator.initial(),
        [],
        isFirstPage: true,
      );

      expect(state.items, isEmpty);
      expect(state.cursor, isNull);
      expect(state.hasReachedEnd, isTrue);
      expect(state.isEmpty, isTrue);
    });

    test('a page arriving out of order is normalised to newest-first', () {
      final state = paginator.applyPage(paginator.initial(), [
        _Post('b', at(20)),
        _Post('c', at(10)),
        _Post('a', at(30)),
      ], isFirstPage: true);
      expect(idsOf(state), ['a', 'b', 'c']);
    });
  });

  group('next page', () {
    late FeedPaginationState<_Post> page1;

    setUp(() {
      page1 = paginator.applyPage(paginator.initial(), [
        _Post('a', at(30)),
        _Post('b', at(20)),
        _Post('c', at(10)),
      ], isFirstPage: true);
    });

    test('appends and advances the cursor', () {
      final page2 = paginator.applyPage(page1, [
        _Post('d', at(9)),
        _Post('e', at(8)),
        _Post('f', at(7)),
      ], isFirstPage: false);

      expect(idsOf(page2), ['a', 'b', 'c', 'd', 'e', 'f']);
      expect(page2.cursor, at(7));
      expect(page2.loadedPages, 2);
      expect(page2.hasReachedEnd, isFalse);
    });

    test('a row repeated across pages appears ONCE — this is the boundary '
        'duplicate that offset paging creates whenever someone posts '
        'between two page loads', () {
      final page2 = paginator.applyPage(page1, [
        _Post('c', at(10)),
        _Post('d', at(9)),
        _Post('e', at(8)),
      ], isFirstPage: false);

      expect(idsOf(page2), ['a', 'b', 'c', 'd', 'e']);
      expect(idsOf(page2).toSet(), hasLength(5));
    });

    test('the LATER copy of a duplicate wins, so a like count fetched two '
        'minutes ago does not overwrite a fresher one', () {
      final page2 = paginator.applyPage(page1, [
        _Post('c', at(10), likes: 99),
      ], isFirstPage: false);

      expect(page2.items.firstWhere((p) => p.id == 'c').likes, 99);
    });

    test('a short next page ends the feed', () {
      final page2 = paginator.applyPage(page1, [
        _Post('d', at(9)),
      ], isFirstPage: false);

      expect(page2.hasReachedEnd, isTrue);
      expect(paginator.canLoadMore(page2, isLoading: false), isFalse);
    });

    test('an empty next page ends the feed and keeps existing items', () {
      final page2 = paginator.applyPage(page1, [], isFirstPage: false);

      expect(page2.hasReachedEnd, isTrue);
      expect(idsOf(page2), ['a', 'b', 'c']);
      expect(
        page2.cursor,
        at(10),
        reason: 'the cursor must not be lost when a page comes back empty',
      );
    });

    test('a pull-to-refresh (isFirstPage: true) REPLACES everything and '
        'resets the page counter — stale rows must not survive a refresh', () {
      final refreshed = paginator.applyPage(page1, [
        _Post('x', at(40)),
        _Post('y', at(35)),
      ], isFirstPage: true);

      expect(idsOf(refreshed), ['x', 'y']);
      expect(refreshed.loadedPages, 1);
    });

    test('ordering stays globally correct even if page 2 contains a row '
        'newer than page 1 (a post edited into a new position)', () {
      final page2 = paginator.applyPage(page1, [
        _Post('z', at(100)),
        _Post('d', at(9)),
        _Post('e', at(8)),
      ], isFirstPage: false);

      expect(idsOf(page2).first, 'z');
    });
  });

  group('canLoadMore guard', () {
    test('is false while a request is already in flight — this is what '
        'stops the scroll listener firing 30 requests per second at the '
        'bottom of the list', () {
      final state = paginator.applyPage(paginator.initial(), [
        _Post('a', at(30)),
        _Post('b', at(20)),
        _Post('c', at(10)),
      ], isFirstPage: true);

      expect(paginator.canLoadMore(state, isLoading: true), isFalse);
      expect(paginator.canLoadMore(state, isLoading: false), isTrue);
    });
  });

  group('realtime interaction', () {
    late FeedPaginationState<_Post> state;

    setUp(() {
      state = paginator.applyPage(paginator.initial(), [
        _Post('a', at(30)),
        _Post('b', at(20)),
        _Post('c', at(10)),
      ], isFirstPage: true);
    });

    test('a new post arriving over Realtime goes to the top WITHOUT moving '
        'the cursor — otherwise every new post would silently skip a page', () {
      final withNew = paginator.prepend(state, _Post('new', at(50)));

      expect(idsOf(withNew).first, 'new');
      expect(withNew.cursor, at(10));
      expect(withNew.loadedPages, 1);
    });

    test('prepending a post already in the list replaces it instead of '
        'duplicating it', () {
      final withDupe = paginator.prepend(state, _Post('b', at(20), likes: 5));

      expect(idsOf(withDupe), hasLength(3));
      expect(withDupe.items.firstWhere((p) => p.id == 'b').likes, 5);
    });

    test('a remote delete removes the row and leaves the cursor alone', () {
      final afterDelete = paginator.removeById(state, 'b');

      expect(idsOf(afterDelete), ['a', 'c']);
      expect(afterDelete.cursor, at(10));
    });

    test('deleting something that is not there is a no-op', () {
      expect(idsOf(paginator.removeById(state, 'nope')), ['a', 'b', 'c']);
    });
  });

  group('determinism', () {
    test('two posts created in the same instant keep a stable order across '
        'rebuilds', () {
      final a = paginator.applyPage(paginator.initial(), [
        _Post('p1', at(10)),
        _Post('p2', at(10)),
      ], isFirstPage: true);
      final b = paginator.applyPage(paginator.initial(), [
        _Post('p2', at(10)),
        _Post('p1', at(10)),
      ], isFirstPage: true);

      expect(idsOf(a), idsOf(b));
    });

    test('pageSize must be positive', () {
      expect(
        () => FeedPaginator<_Post>(
          idOf: (p) => p.id,
          createdAtOf: (p) => p.createdAt,
          pageSize: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
