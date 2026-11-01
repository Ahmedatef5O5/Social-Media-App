part of 'group_profile_cubit.dart';

sealed class GroupProfileState {
  const GroupProfileState();
}

final class GroupProfileInitial extends GroupProfileState {
  const GroupProfileInitial();
}

final class GroupProfileLoading extends GroupProfileState {
  const GroupProfileLoading();
}

final class GroupProfileLoaded extends GroupProfileState {
  final GroupProfileModel profile;

  /// True while a join request / policy update is in flight.
  final bool isBusy;

  const GroupProfileLoaded(this.profile, {this.isBusy = false});
}

final class GroupProfileNotFound extends GroupProfileState {
  const GroupProfileNotFound();
}

final class GroupProfileError extends GroupProfileState {
  final String message;
  const GroupProfileError(this.message);
}
