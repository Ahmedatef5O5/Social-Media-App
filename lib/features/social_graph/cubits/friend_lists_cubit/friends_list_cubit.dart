import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/social_graph/services/friendship_services.dart';
import '../../models/friend_list_item_model.dart';
part 'friends_list_state.dart';

class FriendsListCubit extends Cubit<FriendsListState> {
  final FriendshipServices _friendshipServices;
  final String userId;

  FriendsListCubit(this._friendshipServices, {required this.userId})
    : super(FriendsListInitial());
  static const _pageSize = 30;
  int _page = 0;
  bool _hasReachedMax = false;
  bool _isFetchingMore = false;

  final List<FriendListItemModel> _friends = [];

  Future<void> loadFriends() async {
    emit(FriendsListLoading());
    try {
      _page = 0;
      _friends.clear();
      final result = await _friendshipServices.getFriends(
        userId,
        offset: 0,
        limit: _pageSize,
      );

      _friends.addAll(result);
      _hasReachedMax = result.length < _pageSize;
      emit(
        FriendsListLoaded(
          friends: List.from(_friends),
          hasReachedMax: _hasReachedMax,
        ),
      );
    } catch (e) {
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

  Future<void> loadMore() async {
    if (_isFetchingMore || _isFetchingMore) return;
    _isFetchingMore = true;
    try {
      _page++;
      final result = await _friendshipServices.getFriends(
        userId,
        offset: _page * _pageSize,
        limit: _pageSize,
      );
      _friends.addAll(result);
      _hasReachedMax = result.length < _pageSize;
      emit(
        FriendsListLoaded(
          friends: List.from(_friends),
          hasReachedMax: _hasReachedMax,
        ),
      );
    } catch (e) {
      _page--;
    } finally {
      _isFetchingMore = false;
    }
  }

  Future<void> unfriend(String friendshipId) async {
    final backup = List<FriendListItemModel>.from(_friends);
    _friends.removeWhere((f) => f.friendshipId == friendshipId);
    emit(
      FriendsListLoaded(
        friends: List.from(_friends),
        hasReachedMax: _hasReachedMax,
      ),
    );
    try {
      await _friendshipServices.unfriend(friendshipId);
    } catch (e) {
      _friends
        ..clear()
        ..addAll(backup);
      emit(
        FriendsListLoaded(
          friends: List.from(_friends),
          hasReachedMax: _hasReachedMax,
        ),
      );
    }
  }
}
