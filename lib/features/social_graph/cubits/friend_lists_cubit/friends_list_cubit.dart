import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/social_graph/services/friendship_services.dart';
import '../../../../core/helpers/safe_emit_mixin.dart';
import '../../models/friend_list_item_model.dart';
part 'friends_list_state.dart';

class FriendsListCubit extends Cubit<FriendsListState>
    with SafeEmitMixin<FriendsListState> {
  final FriendshipServices _friendshipServices;
  final String userId;

  FriendsListCubit(this._friendshipServices, {required this.userId})
    : super(FriendsListInitial());

  static const _pageSize = 30;

  final List<FriendListItemModel> _friends = [];
  int? _totalCount;
  bool _hasReachedMax = false;
  bool _isFetchingMore = false;
  int _generation = 0;

  void _emitLoaded({bool isLoadingMore = false, bool loadMoreFailed = false}) {
    if (isClosed) return;
    emit(
      FriendsListLoaded(
        friends: List.of(_friends),
        hasReachedMax: _hasReachedMax,
        totalCount: _totalCount,
        isLoadingMore: isLoadingMore,
        loadMoreFailed: loadMoreFailed,
      ),
    );
  }

  /// Loads the first page. With [isRefresh] (pull-to-refresh) the current list
  /// stays on screen instead of flashing the skeleton.
  Future<void> loadFriends({bool isRefresh = false}) async {
    final generation = ++_generation;
    _isFetchingMore = false;
    if (!(isRefresh && state is FriendsListLoaded)) {
      emit(FriendsListLoading());
    }

    try {
      final page = await _friendshipServices.getFriendsPage(
        userId,
        offset: 0,
        limit: _pageSize,
      );
      if (isClosed || generation != _generation) return;

      _friends
        ..clear()
        ..addAll(page.items);
      _totalCount = page.totalCount;
      _hasReachedMax = page.items.length < _pageSize;
      _emitLoaded();
    } catch (e) {
      debugPrint('[FriendsListCubit] loadFriends error: $e');
      if (isClosed || generation != _generation) return;
      if (e.toString().contains('no-internet')) {
        emit(
          FriendsListError(
            "No internet connection. Please check your network.",
          ),
        );
      } else {
        emit(const FriendsListError('Failed to load friends list.'));
      }
    }
  }

  /// Called while scrolling. Ignored until the first page is shown, while a
  /// page is in flight, after the last page, and after a failure (the user
  /// retries explicitly with [retryLoadMore]).
  Future<void> loadMore() async {
    final current = state;
    if (current is! FriendsListLoaded ||
        _isFetchingMore ||
        _hasReachedMax ||
        current.loadMoreFailed) {
      return;
    }
    await _fetchNextPage();
  }

  Future<void> retryLoadMore() async {
    if (state is! FriendsListLoaded || _isFetchingMore || _hasReachedMax) {
      return;
    }
    await _fetchNextPage();
  }

  Future<void> _fetchNextPage() async {
    _isFetchingMore = true;
    final generation = _generation;
    _emitLoaded(isLoadingMore: true);

    try {
      // The offset is the number of rows already loaded, so it stays correct
      // after a local unfriend removed a row from both the list and the server.
      final page = await _friendshipServices.getFriendsPage(
        userId,
        offset: _friends.length,
        limit: _pageSize,
      );
      if (isClosed || generation != _generation) return;

      final knownIds = _friends.map((f) => f.friendshipId).toSet();
      final freshItems =
          page.items.where((f) => knownIds.add(f.friendshipId)).toList();

      _friends.addAll(freshItems);
      _totalCount = page.totalCount ?? _totalCount;
      // A page made only of already-known rows would loop forever: stop.
      _hasReachedMax = page.items.length < _pageSize || freshItems.isEmpty;
      _emitLoaded();
    } catch (e) {
      debugPrint('[FriendsListCubit] loadMore error: $e');
      if (isClosed || generation != _generation) return;
      _emitLoaded(loadMoreFailed: true);
    } finally {
      _isFetchingMore = false;
    }
  }

  Future<void> unfriend(String friendshipId) async {
    final backupFriends = List<FriendListItemModel>.of(_friends);
    final backupTotal = _totalCount;

    _friends.removeWhere((f) => f.friendshipId == friendshipId);
    if (_totalCount != null && _totalCount! > 0) _totalCount = _totalCount! - 1;
    _emitLoaded();

    try {
      await _friendshipServices.unfriend(friendshipId);
    } catch (e) {
      debugPrint('[FriendsListCubit] unfriend error: $e');
      if (isClosed) return;
      _friends
        ..clear()
        ..addAll(backupFriends);
      _totalCount = backupTotal;
      _emitLoaded();
    }
  }
}
