import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/auth/data/models/user_data.dart';
import 'package:social_media_app/features/profile/services/edit_profile_services.dart';
part 'edit_profile_state.dart';

class EditProfileCubit extends Cubit<EditProfileState> {
  // Dependency Injection
  final EditProfileServices _editProfileServices;
  EditProfileCubit(this._editProfileServices) : super(EditProfileInitial());

  Future<void> updateProfile({
    required UserData oldUser,
    required String name,
    required String userName,
    required String title,
    required String bio,
    File? profileImage,
    File? backgroundImage,
  }) async {
    emit(EditProfileLoading());
    try {
      String? profileImageUrl;
      String? backgroundImageUrl;
      final timeStamp = DateTime.now().millisecondsSinceEpoch;
      if (profileImage != null) {
        profileImageUrl = await _editProfileServices.uploadImage(
          file: profileImage,
          path: '${oldUser.id}/profile_$timeStamp.jpg',
          bucket: 'avatars',
        );
      }
      if (backgroundImage != null) {
        backgroundImageUrl = await _editProfileServices.uploadImage(
          file: backgroundImage,
          path: '${oldUser.id}/background_$timeStamp.jpg',
          bucket: 'backgrounds',
        );
      }
      final updates = {
        'name': name,
        'username': userName,
        'title': title,
        'bio': bio,
        if (profileImageUrl != null) 'image_url': profileImageUrl,
        if (backgroundImageUrl != null)
          'background_image_url': backgroundImageUrl,
        // 'updated_at': DateTime.now().toIso8601String(),
      };
      await _editProfileServices.updateUserData(oldUser.id, updates);
      final updatedUser = oldUser.copyWith(
        name: name,
        userName: userName,
        title: title,
        bio: bio,
        imageUrl: profileImageUrl ?? oldUser.imageUrl,
        backgroundImageUrl: backgroundImageUrl ?? oldUser.backgroundImageUrl,
      );
      emit(EditProfileSuccess(updatedUser));
    } catch (e) {
      debugPrint('Error updating profile: $e');
      emit(EditProfileError(e.toString()));
    }
  }
}
