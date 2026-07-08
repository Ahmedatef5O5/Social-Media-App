part of 'home_cubit.dart';

sealed class HomeState {
  const HomeState();
}

final class HomeInitial extends HomeState {}

final class UserDataLoading extends HomeState {}

final class UserDataLoaded extends HomeState {
  final UserData userData;

  const UserDataLoaded(this.userData);
}

final class UserDataLoadError extends HomeState {
  final String message;

  UserDataLoadError(this.message);
}
