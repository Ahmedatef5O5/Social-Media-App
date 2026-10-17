import 'package:flutter/foundation.dart';

/// Offset paging state for the RANKED home feed.
///
/// The ranking score is not monotonic in time, so a `created_at` cursor
/// (see `FeedPaginator`) cannot page it. Instead the server freezes its
/// clock at [asOf] on the first page and returns it; every later page sends
/// the same [asOf] plus the number of ranked rows already consumed
/// ([offset]), which keeps the ordering stable between requests.
@immutable
class FeedWindow {
  const FeedWindow._(this.offset, this.exhausted, this.asOf);

  /// Nothing fetched yet.
  const FeedWindow.initial() : offset = 0, exhausted = false, asOf = null;

  static const int firstPageSize = 30;
  static const int pageSize = 20;

  /// Hard ceiling on items per session (bounds memory and hydration cost).
  static const int maxItems = 300;

  /// Ranked rows consumed so far (counted BEFORE excluding known ids, so it
  /// always matches the server-side offset).
  final int offset;

  /// True once the server returned fewer rows than asked for, or the
  /// ceiling was reached.
  final bool exhausted;

  /// Server timestamp that freezes the ranking for this paging session.
  final DateTime? asOf;

  /// `p_limit` for the next request.
  int get nextLimit {
    if (offset == 0) return firstPageSize;
    final remaining = maxItems - offset;
    return remaining < pageSize ? remaining : pageSize;
  }

  bool get canLoadMore => !exhausted && offset > 0 && offset < maxItems;

  /// Records the outcome of a request that asked for [requested] rows and
  /// got [rankedCount] ranked rows back. The first non-null [asOf] wins.
  FeedWindow afterFetch({
    required int requested,
    required int rankedCount,
    required DateTime? asOf,
  }) {
    final newOffset = offset + rankedCount;
    return FeedWindow._(
      newOffset,
      rankedCount < requested || newOffset >= maxItems,
      this.asOf ?? asOf,
    );
  }

  @override
  String toString() =>
      'FeedWindow(offset: $offset, exhausted: $exhausted, asOf: $asOf)';
}
