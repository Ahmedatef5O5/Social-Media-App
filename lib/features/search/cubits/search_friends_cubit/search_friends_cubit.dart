import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../social_graph/models/friend_list_item_model.dart';
import '../../../social_graph/services/friendship_services.dart';
part 'search_friends_state.dart';

class SearchFriendsCubit extends Cubit<SearchFriendsState> {
  final FriendshipServices _friendshipServices;
  final String userId;

  SearchFriendsCubit(this.userId, {FriendshipServices? friendshipServices})
    : _friendshipServices = friendshipServices ?? FriendshipServices(),
      super(SearchFriendsInitial());

  static const int _pageSize = 30;
  String _query = '';
  bool _hasReachedMax = false;
  bool _isFetchingMore = false;
  final List<FriendListItemModel> _results = [];

  Future<void> search(String query) async {
    final trimmed = query.trim();
    _query = trimmed;
    _results.clear();
    _hasReachedMax = false;

    if (trimmed.isEmpty) {
      emit(SearchFriendsInitial());
      return;
    }

    emit(SearchFriendsLoading());
    try {
      final results = await _friendshipServices.searchFriends(
        userId: userId,
        query: trimmed,
        limit: _pageSize,
      );
      if (_query != trimmed) return;

      _results.addAll(results);
      _hasReachedMax = results.length < _pageSize;
      emit(
        SearchFriendsLoaded(
          friends: List.of(_results),
          hasReachedMax: _hasReachedMax,
        ),
      );
    } catch (e) {
      if (_query != trimmed) return;
      debugPrint('SearchFriendsCubit.search error: $e');
      emit(
        const SearchFriendsError(
          'Something went wrong. Please try again later.',
        ),
      );
    }
  }

  Future<void> loadMore() async {
    if (_query.isEmpty || _hasReachedMax || _isFetchingMore) return;
    _isFetchingMore = true;
    try {
      final more = await _friendshipServices.searchFriends(
        userId: userId,
        query: _query,
        limit: _pageSize,
        offset: _results.length,
      );
      _results.addAll(more);
      if (more.length < _pageSize) _hasReachedMax = true;
      emit(
        SearchFriendsLoaded(
          friends: List.of(_results),
          hasReachedMax: _hasReachedMax,
        ),
      );
    } catch (e) {
      debugPrint('SearchFriendsCubit.loadMore error: $e');
    } finally {
      _isFetchingMore = false;
    }
  }

  void removeByFriendshipId(String friendshipId) {
    _results.removeWhere((f) => f.friendshipId == friendshipId);
    emit(
      SearchFriendsLoaded(
        friends: List.of(_results),
        hasReachedMax: _hasReachedMax,
      ),
    );
  }
}
