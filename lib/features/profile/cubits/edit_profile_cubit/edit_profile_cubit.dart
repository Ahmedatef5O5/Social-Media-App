import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/features/auth/data/models/user_data.dart';
import 'package:social_media_app/features/profile/services/edit_profile_services.dart';
import '../../../../core/utilities/supabase_constants.dart';
part 'edit_profile_state.dart';

class EditProfileCubit extends Cubit<EditProfileState> {
  // Dependency Injection
  final EditProfileServices _editProfileServices;
  EditProfileCubit(this._editProfileServices) : super(EditProfileInitial());

  Future<File?> pickImage(ImageSource source) {
    return _editProfileServices.pickImage(source);
  }

  Future<void> updateProfile({
    required UserData oldUser,
    required String name,
    required String userName,
    required String title,
    required String bio,
    File? profileImage,
    File? backgroundImage,
    Map<String, String>? socialLinks,
  }) async {
    emit(EditProfileLoading());
    try {
      String? profileImageUrl, backgroundImageUrl;
      String? profileImagePublicId, backgroundImagePublicId;
      if (profileImage != null) {
        final result = await _editProfileServices.uploadImage(
          file: profileImage,
          userId: oldUser.id,
          folder: 'avatars',
        );
        profileImageUrl = result.secureUrl;
        profileImagePublicId = result.publicId;
      }
      if (backgroundImage != null) {
        final result = await _editProfileServices.uploadImage(
          file: backgroundImage,
          userId: oldUser.id,
          folder: 'backgrounds',
        );
        backgroundImageUrl = result.secureUrl;
        backgroundImagePublicId = result.publicId;
      }
      final updates = {
        'name': name,
        'username': userName,
        'title': title,
        'bio': bio,
        if (profileImageUrl != null) 'image_url': profileImageUrl,
        if (backgroundImageUrl != null)
          'background_image_url': backgroundImageUrl,

        if (profileImagePublicId != null)
          'image_public_id': profileImagePublicId,
        if (backgroundImagePublicId != null)
          'background_image_public_id': backgroundImagePublicId,

        if (socialLinks != null) UserColumns.socialLinks: socialLinks,
      };
      await _editProfileServices.updateUserData(oldUser.id, updates);
      final updatedUser = oldUser.copyWith(
        name: name,
        userName: userName,
        title: title,
        bio: bio,
        imageUrl: profileImageUrl ?? oldUser.imageUrl,
        backgroundImageUrl: backgroundImageUrl ?? oldUser.backgroundImageUrl,
        socialLinks: socialLinks ?? oldUser.socialLinks,
      );
      emit(EditProfileSuccess(updatedUser));
    } catch (e) {
      debugPrint('Error updating profile: $e');
      emit(EditProfileError(e.toString()));
    }
  }
}
