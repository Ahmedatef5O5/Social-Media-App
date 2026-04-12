import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/discover/services/discover_people_services.dart';
import '../../auth/data/models/user_data.dart';
part 'discover_people_state.dart';

class DiscoverPeopleCubit extends Cubit<DiscoverPeopleState> {
  final DiscoverPeopleServices _discoverPeopleServices;
  DiscoverPeopleCubit(this._discoverPeopleServices)
    : super(DiscoverPeopleInitial());

  Future<void> getDiscoverPeople({bool isRefresh = false}) async {
    if (!isRefresh) emit(DiscoverPeopleLoading());
    try {
      final users = await _discoverPeopleServices.getAllUsers();
      emit(DiscoverPeopleSuccess(users));
    } catch (e) {
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
