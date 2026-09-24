import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/helpers/safe_emit_mixin.dart';
import '../../../posts/cubits/posts_cubit/posts_cubit.dart';
import '../../../posts/models/post_model.dart';
import '../../../posts/models/profile_posts_page.dart';
import '../../../posts/services/posts_services.dart';
part 'profile_posts_state.dart';

class ProfilePostsCubit extends Cubit<ProfilePostsState>
    with SafeEmitMixin<ProfilePostsState> {
  static const int _pageSize = 15;
  static const Duration _loadMoreCooldown = Duration(seconds: 5);
  static final DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(0);

  final String userId;
  final PostsServices _postsServices;
  final PostsCubit _postsCubit;
  late final StreamSubscription<PostsState> _feedSubscription;
  List<String> _ids = [];
  final Map<String, DateTime> _time = {};
  final Set<String> _pinned = {};

  bool _hasMore = false;
  bool? _cursorIsPinned;
  String? _cursorCreatedAt;
  String? _cursorId;
  DateTime? _newestCreatedAt;
  int _seenFeedEpoch = 0;
  bool _busy = false;
  DateTime? _loadMoreBlockedUntil;

  ProfilePostsCubit({
    required this.userId,
    required PostsServices postsServices,
    required PostsCubit postsCubit,
  }) : _postsServices = postsServices,
       _postsCubit = postsCubit,
       super(ProfilePostsInitial()) {
    _seenFeedEpoch = _postsCubit.feedEpoch;
    _feedSubscription = _postsCubit.stream.listen(_onFeedChanged);
  }

  Future<void> loadInitial() async {
    if (_busy) return;
    emit(ProfilePostsLoading());
    await _loadFirstPage(silent: false);
  }

  Future<void> refresh() => _loadFirstPage(silent: true);

  Future<void> _loadFirstPage({required bool silent}) async {
    if (_busy) return;
    _busy = true;
    try {
      await _waitForFeed();
      final page = await _postsServices.fetchUserProfilePosts(
        userId,
        pageSize: _pageSize,
      );
      if (isClosed) return;

      _postsCubit.mergePostsIntoCache(page.posts, appendNew: true);
      _seenFeedEpoch = _postsCubit.feedEpoch;
      _time.clear();
      _pinned.clear();
      _track(page.posts);
      _ids = [for (final p in page.posts) p.id]; // server order
      _setCursor(page);
      _newestCreatedAt = _maxCreatedAt(page.posts);
      _loadMoreBlockedUntil = null;
      _emitLoaded();
    } catch (e) {
      debugPrint('[ProfilePostsCubit] first page failed: $e');
      if (silent && _ids.isNotEmpty) return;
      emit(ProfilePostsError(_errorMessage(e)));
    } finally {
      _busy = false;
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! ProfilePostsLoaded ||
        !current.hasMore ||
        current.isLoadingMore ||
        _busy) {
      return;
    }
    final blockedUntil = _loadMoreBlockedUntil;
    if (blockedUntil != null && DateTime.now().isBefore(blockedUntil)) return;

    _busy = true;
    _emitLoaded(isLoadingMore: true);
    try {
      final page = await _postsServices.fetchUserProfilePosts(
        userId,
        pageSize: _pageSize,
        beforeIsPinned: _cursorIsPinned,
        beforeCreatedAt: _cursorCreatedAt,
        beforeId: _cursorId,
      );
      if (isClosed) return;

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
      debugPrint('[ProfilePostsCubit] loadMore failed: $e');
      _loadMoreBlockedUntil = DateTime.now().add(_loadMoreCooldown);
      _emitLoaded();
    } finally {
      _busy = false;
    }
  }

  // ── Keeping the list consistent with the shared PostsCubit cache ──────────

  void _onFeedChanged(PostsState feed) {
    if (feed is! PostsLoaded || state is! ProfilePostsLoaded || _busy) return;

    // The home feed was reloaded and replaced the cache wholesale.
    if (_postsCubit.feedEpoch != _seenFeedEpoch) {
      _seenFeedEpoch = _postsCubit.feedEpoch;
      unawaited(_restoreLostPosts());
      return;
    }
    _reconcile(feed.posts);
  }

  void _reconcile(List<PostModel> feed) {
    if (state is! ProfilePostsLoaded) return;
    final byId = {for (final p in feed) p.id: p};
    var changed = false;

    // 1) Left the cache: deleted / un-shared / temp share id swapped.
    final gone = [
      for (final id in _ids)
        if (!byId.containsKey(id)) id,
    ];
    if (gone.isNotEmpty) {
      final goneSet = gone.toSet();
      _ids = _ids.where((id) => !goneSet.contains(id)).toList();
      for (final id in gone) {
        _time.remove(id);
        _pinned.remove(id);
      }
      changed = true;
    }

    // 2) Pin flag changed: my optimistic toggle, or the owner pinned from
    //    another device (arrives through the realtime post update).
    var pinsChanged = false;
    for (final id in _ids) {
      final isPinned = byId[id]!.isPinned;
      if (isPinned != _pinned.contains(id)) {
        isPinned ? _pinned.add(id) : _pinned.remove(id);
        pinsChanged = true;
      }
    }
    if (pinsChanged) {
      _resort();
      _dropIdsBeyondCursor();
      changed = true;
    }

    // 3) Created / shared by this profile's owner after we loaded.
    final known = _ids.toSet();
    final fresh = [
      for (final p in feed)
        if (p.authorId == userId &&
            !known.contains(p.id) &&
            _isNewerThanLoaded(p))
          p,
    ];
    if (fresh.isNotEmpty) {
      _track(fresh);
      _ids = [..._ids, for (final p in fresh) p.id];
      final freshNewest = _maxCreatedAt(fresh);
      if (freshNewest != null) _newestCreatedAt = freshNewest;
      _resort(); // lands right below the pinned block
      changed = true;
    }

    if (changed) _emitLoaded();
  }

  /// Re-fetches only what a feed reload evicted, then reconciles. Posts that
  /// were deleted on the server simply do not come back and get pruned.
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
        if (isClosed) return;
        if (restored.isNotEmpty) {
          _postsCubit.mergePostsIntoCache(restored, appendNew: true);
        }
      }
    } finally {
      _busy = false;
    }
    if (isClosed) return;
    _reconcile(_currentFeed());
  }

  /// An unpinned post whose natural position lies beyond the loaded range is
  /// dropped locally: the next loadMore returns it at its exact place.
  void _dropIdsBeyondCursor() {
    if (!_hasMore) return;
    final cursorTime = DateTime.tryParse(_cursorCreatedAt ?? '');
    final cursorId = _cursorId;
    if (cursorTime == null || cursorId == null) return;

    final dropped = <String>{
      for (final id in _ids)
        if (!_pinned.contains(id) && _isAfterCursor(id, cursorTime, cursorId))
          id,
    };
    if (dropped.isEmpty) return;
    _ids = _ids.where((id) => !dropped.contains(id)).toList();
    for (final id in dropped) {
      _time.remove(id);
    }
  }

  bool _isAfterCursor(String id, DateTime cursorTime, String cursorId) {
    final c = (_time[id] ?? _epoch).compareTo(cursorTime);
    return c < 0 || (c == 0 && id.compareTo(cursorId) < 0);
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  /// Same ordering as the RPC: pinned first, then created_at DESC, id DESC.
  void _resort() {
    _ids.sort((a, b) {
      final pa = _pinned.contains(a);
      final pb = _pinned.contains(b);
      if (pa != pb) return pa ? -1 : 1;
      final byTime = (_time[b] ?? _epoch).compareTo(_time[a] ?? _epoch);
      return byTime != 0 ? byTime : b.compareTo(a);
    });
  }

  void _track(Iterable<PostModel> posts) {
    for (final p in posts) {
      _time[p.id] = _timeOf(p);
      if (p.isPinned) {
        _pinned.add(p.id);
      } else {
        _pinned.remove(p.id);
      }
    }
  }

  void _setCursor(ProfilePostsPage page) {
    _hasMore = page.hasMore;
    _cursorIsPinned = page.nextCursorIsPinned;
    _cursorCreatedAt = page.nextCursorCreatedAt;
    _cursorId = page.nextCursorId;
  }

  List<PostModel> _currentFeed() {
    final s = _postsCubit.state;
    return s is PostsLoaded ? s.posts : _postsCubit.cachedPosts;
  }

  /// Never merge before the home feed exists, otherwise the home screen would
  /// briefly show only this profile's posts.
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
      ProfilePostsLoaded(
        postIds: List.unmodifiable(_ids),
        hasMore: _hasMore,
        isLoadingMore: isLoadingMore,
      ),
    );
  }

  DateTime _timeOf(PostModel p) => DateTime.tryParse(p.createdAt) ?? _epoch;

  DateTime? _maxCreatedAt(Iterable<PostModel> posts) {
    DateTime? max;
    for (final p in posts) {
      final t = DateTime.tryParse(p.createdAt);
      if (t != null && (max == null || t.isAfter(max))) max = t;
    }
    return max;
  }

  bool _isNewerThanLoaded(PostModel p) {
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
