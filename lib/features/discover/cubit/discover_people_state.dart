part of 'discover_people_cubit.dart';

sealed class DiscoverPeopleState {
  const DiscoverPeopleState();
}

final class DiscoverPeopleInitial extends DiscoverPeopleState {}

final class DiscoverPeopleLoading extends DiscoverPeopleState {}

final class DiscoverPeopleSuccess extends DiscoverPeopleState {
  final List<UserData> users;
  const DiscoverPeopleSuccess(this.users);
}

final class DiscoverPeopleFailure extends DiscoverPeopleState {
  final String message;
  const DiscoverPeopleFailure(this.message);
}
