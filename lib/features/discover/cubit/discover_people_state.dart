part of 'discover_people_cubit.dart';

sealed class DiscoverPeopleState {
  const DiscoverPeopleState();
}

final class DiscoverPeopleInitial extends DiscoverPeopleState {}

class DiscoverPeopleRefreshFeedback extends DiscoverPeopleState {}

final class DiscoverPeopleLoading extends DiscoverPeopleState {}

final class DiscoverPeopleSuccess extends DiscoverPeopleState {
  final List<DiscoverPersonModel> users;
  final bool hasReachedMax;
  const DiscoverPeopleSuccess({
    required this.users,
    required this.hasReachedMax,
  });
}

final class DiscoverPeopleFailure extends DiscoverPeopleState {
  final String message;
  const DiscoverPeopleFailure(this.message);
}
