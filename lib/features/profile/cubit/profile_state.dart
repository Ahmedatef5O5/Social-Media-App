part of 'profile_cubit.dart';

sealed class ProfileState {
  const ProfileState();
}

final class ProfileInitial extends ProfileState {}

final class ProfileLoading extends ProfileState {}

final class ProfileLoaded extends ProfileState {
  final ProfileStatsModel stats;
  final UserData user;
  const ProfileLoaded(this.stats, this.user);
}

final class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);
}
