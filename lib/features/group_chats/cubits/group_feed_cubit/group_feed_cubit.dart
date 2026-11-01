import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/helpers/safe_emit_mixin.dart';
import '../../../posts/cubits/posts_cubit/posts_cubit.dart';
import '../../../posts/models/group_posts_page.dart';
import '../../../posts/models/post_model.dart';
import '../../../posts/services/posts_services.dart';
part 'group_feed_state.dart';

/// Newest-first feed of ONE group. Mirrors ProfilePostsCubit: it keeps only
/// ids and borrows hydrated posts from the shared PostsCubit cache, so likes,
/// reactions and deletes stay consistent with the home feed.
class GroupFeedCubit extends Cubit<GroupFeedState>
    with SafeEmitMixin<GroupFeedState> {
  static const int _pageSize = 15;
  static const Duration _loadMoreCooldown = Duration(seconds: 5);
  static final DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(0);

  final String groupId;
  final PostsServices _postsServices;
  final PostsCubit _postsCubit;
  late final StreamSubscription<PostsState> _feedSubscription;

  List<String> _ids = [];
  final Map<String, DateTime> _time = {};
  bool _hasMore = false;
  String? _cursorCreatedAt;
  String? _cursorId;
  DateTime? _newestCreatedAt;
  int _seenFeedEpoch = 0;
  bool _busy = false;
  bool _evicted = false;
  DateTime? _loadMoreBlockedUntil;

  GroupFeedCubit({
    required this.groupId,
    required PostsServices postsServices,
    required PostsCubit postsCubit,
  }) : _postsServices = postsServices,
       _postsCubit = postsCubit,
       super(const GroupFeedInitial()) {
    _seenFeedEpoch = _postsCubit.feedEpoch;
    _feedSubscription = _postsCubit.stream.listen(_onFeedChanged);
  }

  Future<void> loadInitial() async {
    if (_busy) return;
    emit(const GroupFeedLoading());
    await _loadFirstPage(silent: false);
  }

  Future<void> refresh() => _loadFirstPage(silent: true);

  /// The user left / was removed / blocked: drop everything immediately and
  /// make sure the shared cache forgets this group's posts.
  void evict() {
    _evicted = true;
    _ids = [];
    _time.clear();
    _hasMore = false;
    _postsCubit.removePostsOfGroup(groupId);
    emit(const GroupFeedLoaded(postIds: [], hasMore: false));
  }

  Future<void> _loadFirstPage({required bool silent}) async {
    if (_busy || _evicted) return;
    _busy = true;
    try {
      await _waitForFeed();
      final page = await _postsServices.fetchGroupPostsPage(
        groupId,
        pageSize: _pageSize,
      );
      if (isClosed || _evicted) return;

      _postsCubit.mergePostsIntoCache(page.posts, appendNew: true);
      _seenFeedEpoch = _postsCubit.feedEpoch;
      _time.clear();
      _track(page.posts);
      _ids = [for (final p in page.posts) p.id];
      _setCursor(page);
      _newestCreatedAt = _maxCreatedAt(page.posts);
      _loadMoreBlockedUntil = null;
      _emitLoaded();
    } catch (e) {
      debugPrint('[GroupFeedCubit] first page failed: $e');
      if (silent && _ids.isNotEmpty) return;
      emit(GroupFeedError(_errorMessage(e)));
    } finally {
      _busy = false;
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! GroupFeedLoaded ||
        !current.hasMore ||
        current.isLoadingMore ||
        _busy ||
        _evicted) {
      return;
    }
    final blockedUntil = _loadMoreBlockedUntil;
    if (blockedUntil != null && DateTime.now().isBefore(blockedUntil)) return;

    _busy = true;
    _emitLoaded(isLoadingMore: true);
    try {
      final page = await _postsServices.fetchGroupPostsPage(
        groupId,
        pageSize: _pageSize,
        beforeCreatedAt: _cursorCreatedAt,
        beforeId: _cursorId,
      );
      if (isClosed || _evicted) return;

      _postsCubit.mergePostsIntoCache(page.posts, appendNew: true);
      _track(page.posts);
      final known = _ids.toSet();
      _ids = [
        ..._ids,
        for (final p in page.posts)
          if (!known.contains(p.id)) p.id,
      ];
      _setCursor(page);
      _resort();
      _emitLoaded();
    } catch (e) {
      debugPrint('[GroupFeedCubit] loadMore failed: $e');
      _loadMoreBlockedUntil = DateTime.now().add(_loadMoreCooldown);
      _emitLoaded();
    } finally {
      _busy = false;
    }
  }

  // ── Keeping the list consistent with the shared PostsCubit cache ──────────

  void _onFeedChanged(PostsState feed) {
    if (feed is! PostsLoaded ||
        state is! GroupFeedLoaded ||
        _busy ||
        _evicted) {
      return;
    }
    if (_postsCubit.feedEpoch != _seenFeedEpoch) {
      _seenFeedEpoch = _postsCubit.feedEpoch;
      unawaited(_restoreLostPosts());
      return;
    }
    _reconcile(feed.posts);
  }

  void _reconcile(List<PostModel> feed) {
    if (state is! GroupFeedLoaded) return;
    final byId = {for (final p in feed) p.id: p};
    var changed = false;

    // Deleted (by me or a moderator) -> gone from the cache.
    final gone = [
      for (final id in _ids)
        if (!byId.containsKey(id)) id,
    ];
    if (gone.isNotEmpty) {
      final goneSet = gone.toSet();
      _ids = _ids.where((id) => !goneSet.contains(id)).toList();
      for (final id in gone) {
        _time.remove(id);
      }
      changed = true;
    }

    // Posted into this group after we loaded (e.g. from CreatePostView).
    final known = _ids.toSet();
    final fresh = [
      for (final p in feed)
        if (p.groupId == groupId && !known.contains(p.id) && _isNewer(p)) p,
    ];
    if (fresh.isNotEmpty) {
      _track(fresh);
      _ids = [..._ids, for (final p in fresh) p.id];
      final newest = _maxCreatedAt(fresh);
      if (newest != null) _newestCreatedAt = newest;
      _resort();
      changed = true;
    }

    if (changed) _emitLoaded();
  }

  Future<void> _restoreLostPosts() async {
    final inFeed = {for (final p in _currentFeed()) p.id};
    final lostIds = [
      for (final id in _ids)
        if (!inFeed.contains(id)) id,
    ];
    _busy = true;
    try {
      if (lostIds.isNotEmpty) {
        final restored = await _postsServices.fetchPostsByIds(lostIds);
        if (isClosed || _evicted) return;
        if (restored.isNotEmpty) {
          _postsCubit.mergePostsIntoCache(restored, appendNew: true);
        }
      }
    } finally {
      _busy = false;
    }
    if (isClosed || _evicted) return;
    _reconcile(_currentFeed());
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  void _resort() {
    _ids.sort((a, b) {
      final byTime = (_time[b] ?? _epoch).compareTo(_time[a] ?? _epoch);
      return byTime != 0 ? byTime : b.compareTo(a);
    });
  }

  void _track(Iterable<PostModel> posts) {
    for (final p in posts) {
      _time[p.id] = DateTime.tryParse(p.createdAt) ?? _epoch;
    }
  }

  void _setCursor(GroupPostsPage page) {
    _hasMore = page.hasMore;
    _cursorCreatedAt = page.nextCursorCreatedAt;
    _cursorId = page.nextCursorId;
  }

  List<PostModel> _currentFeed() {
    final s = _postsCubit.state;
    return s is PostsLoaded ? s.posts : _postsCubit.cachedPosts;
  }

  Future<void> _waitForFeed() async {
    if (_postsCubit.state is PostsLoaded ||
        _postsCubit.cachedPosts.isNotEmpty) {
      return;
    }
    if (_postsCubit.state is PostsInitial) unawaited(_postsCubit.fetchPosts());
    final next = await _postsCubit.stream
        .firstWhere((s) => s is PostsLoaded || s is PostsLoadError)
        .timeout(const Duration(seconds: 15));
    if (next is PostsLoadError) throw Exception('feed-unavailable');
  }

  void _emitLoaded({bool isLoadingMore = false}) {
    emit(
      GroupFeedLoaded(
        postIds: List.unmodifiable(_ids),
        hasMore: _hasMore,
        isLoadingMore: isLoadingMore,
      ),
    );
  }

  DateTime? _maxCreatedAt(Iterable<PostModel> posts) {
    DateTime? max;
    for (final p in posts) {
      final t = DateTime.tryParse(p.createdAt);
      if (t != null && (max == null || t.isAfter(max))) max = t;
    }
    return max;
  }

  bool _isNewer(PostModel p) {
    final t = DateTime.tryParse(p.createdAt);
    if (t == null) return false;
    final newest = _newestCreatedAt;
    return newest == null || t.isAfter(newest);
  }

  String _errorMessage(Object e) =>
      e.toString().contains('no-internet')
          ? 'No internet connection. Please check your network.'
          : 'Failed to load posts.';

  @override
  Future<void> close() {
    _feedSubscription.cancel();
    return super.close();
  }
}
