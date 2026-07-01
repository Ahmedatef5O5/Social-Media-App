import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/discover/services/discover_people_services.dart';
import '../../auth/data/models/user_data.dart';
part 'discover_people_state.dart';

class DiscoverPeopleCubit extends Cubit<DiscoverPeopleState> {
  final DiscoverPeopleServices _discoverPeopleServices;
  DiscoverPeopleCubit(this._discoverPeopleServices)
    : super(DiscoverPeopleInitial());

  int _currentPage = 0;
  bool _hasReachedMax = false;
  bool _isFetchingMore = false;
  final List<UserData> _users = [];

  Future<void> getDiscoverPeople({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 0;
      _hasReachedMax = false;
      _users.clear();
      emit(DiscoverPeopleLoading());
    } else if (_currentPage == 0) {
      emit(DiscoverPeopleLoading());
    }

    if (_hasReachedMax || _isFetchingMore) return;
    _isFetchingMore = true;

    try {
      final start = DateTime.now();

      final users = await _discoverPeopleServices.getAllUsers(
        page: _currentPage,
        pageSize: 15,
      );

      if (users.isEmpty || users.length < 15) {
        _hasReachedMax = true;
      }

      _users.addAll(users);
      _currentPage++;
      _isFetchingMore = false;

      if (isRefresh) {
        emit(DiscoverPeopleRefreshFeedback());

        final elapsed = DateTime.now().difference(start);
        if (elapsed < const Duration(milliseconds: 600)) {
          await Future.delayed(const Duration(milliseconds: 600) - elapsed);
        }
      }

      emit(
        DiscoverPeopleSuccess(
          users: List.from(_users),
          hasReachedMax: _hasReachedMax,
        ),
      );
    } catch (e) {
      _isFetchingMore = false;

      if (e.toString().contains('no-internet')) {
        emit(
          DiscoverPeopleFailure(
            "No internet connection. Please check your network.",
          ),
        );
      } else {
        emit(
          DiscoverPeopleFailure(
            "Something went wrong. Please try again later.",
          ),
        );
      }
      debugPrint('Error in getDiscoverPeople: $e');
    }
  }
}
