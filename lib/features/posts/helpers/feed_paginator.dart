import 'package:flutter/foundation.dart';

/// Immutable pagination state for a cursor-paged feed.
@immutable
class FeedPaginationState<T> {
  const FeedPaginationState({
    required this.items,
    required this.cursor,
    required this.hasReachedEnd,
    required this.loadedPages,
  });

  const FeedPaginationState.initial()
    : items = const [],
      cursor = null,
      hasReachedEnd = false,
      loadedPages = 0;

  final List<T> items;

  /// `created_at` of the oldest item currently held. The next request asks
  /// the server for rows strictly older than this — which is what makes
  /// pagination stable while new posts are being inserted at the top.
  ///
  /// Offset-based paging (`.range(20, 39)`) would silently skip or repeat
  /// rows whenever someone publishes a post between two page loads. That is
  /// why this is a keyset cursor, not an offset.
  final DateTime? cursor;

  final bool hasReachedEnd;
  final int loadedPages;

  bool get isEmpty => items.isEmpty;

  @override
  String toString() =>
      'FeedPaginationState(items: ${items.length}, cursor: $cursor, '
      'end: $hasReachedEnd, pages: $loadedPages)';
}

/// Pure, dependency-free feed pagination.
///
/// V6 finding C-03: `PostsServices.fetchPosts()` issues a `.select()` with
/// an `.order()` and no `.range()`/`.limit()` at all — the feed downloads
/// every post the user is allowed to see, on every cold start and every
/// pull-to-refresh. This class holds the *logic* half of the fix, separated
/// from Supabase so every boundary condition is unit-testable without a
/// network.
class FeedPaginator<T> {
  const FeedPaginator({
    required this.idOf,
    required this.createdAtOf,
    this.pageSize = defaultPageSize,
  }) : assert(pageSize > 0, 'pageSize must be positive');

  static const int defaultPageSize = 20;

  final String Function(T item) idOf;
  final DateTime Function(T item) createdAtOf;
  final int pageSize;

  FeedPaginationState<T> initial() => FeedPaginationState<T>.initial();

  /// Folds a freshly fetched page into the current state.
  ///
  /// * [isFirstPage] `true` replaces everything (cold start, pull-to-refresh).
  /// * Duplicates are resolved by id, with the INCOMING row winning — a
  ///   later page carries fresher like counts than a page fetched minutes ago.
  /// * End-of-feed is `incoming.length < pageSize`. Asking for 20 and
  ///   getting 20 is never proof there are no more; asking for 20 and
  ///   getting 19 is.
  FeedPaginationState<T> applyPage(
    FeedPaginationState<T> current,
    List<T> incoming, {
    required bool isFirstPage,
  }) {
    final byId = <String, T>{};

    if (!isFirstPage) {
      for (final item in current.items) {
        byId[idOf(item)] = item;
      }
    }
    for (final item in incoming) {
      byId[idOf(item)] = item;
    }

    final merged = sort(byId.values.toList());

    return FeedPaginationState<T>(
      items: merged,
      cursor: merged.isEmpty ? null : createdAtOf(merged.last),
      hasReachedEnd: incoming.length < pageSize,
      loadedPages: isFirstPage ? 1 : current.loadedPages + 1,
    );
  }

  /// Newest first, with the id as a deterministic tie-breaker so two posts
  /// created in the same millisecond never swap places between rebuilds.
  List<T> sort(List<T> items) {
    final list = List<T>.from(items);
    list.sort((a, b) {
      final byTime = createdAtOf(b).compareTo(createdAtOf(a));
      if (byTime != 0) return byTime;
      return idOf(b).compareTo(idOf(a));
    });
    return list;
  }

  /// Whether a `loadMore` request should be issued at all. Guards against
  /// the scroll listener firing dozens of times per second at the bottom
  /// of the list.
  bool canLoadMore(FeedPaginationState<T> state, {required bool isLoading}) {
    return !isLoading && !state.hasReachedEnd && state.cursor != null;
  }

  /// Inserts a realtime-arrived item at the top without disturbing the
  /// cursor — a new post must never move the pagination boundary.
  FeedPaginationState<T> prepend(FeedPaginationState<T> current, T item) {
    final id = idOf(item);
    final withoutDuplicate =
        current.items.where((existing) => idOf(existing) != id).toList();
    final merged = sort([item, ...withoutDuplicate]);

    return FeedPaginationState<T>(
      items: merged,
      cursor: current.cursor,
      hasReachedEnd: current.hasReachedEnd,
      loadedPages: current.loadedPages,
    );
  }

  FeedPaginationState<T> removeById(FeedPaginationState<T> current, String id) {
    final remaining = current.items.where((item) => idOf(item) != id).toList();
    return FeedPaginationState<T>(
      items: remaining,
      cursor: current.cursor,
      hasReachedEnd: current.hasReachedEnd,
      loadedPages: current.loadedPages,
    );
  }
}
