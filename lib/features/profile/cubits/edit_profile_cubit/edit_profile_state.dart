part of 'edit_profile_cubit.dart';

sealed class EditProfileState {
  const EditProfileState();
}

final class EditProfileInitial extends EditProfileState {}

final class EditProfileLoading extends EditProfileState {}

final class EditProfileSuccess extends EditProfileState {
  final UserData updatedUser;

  EditProfileSuccess(this.updatedUser);
}

final class EditProfileError extends EditProfileState {
  final String errMsg;

  const EditProfileError(this.errMsg);
}
