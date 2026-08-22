import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/core/services/media_cleanup_service.dart';
import 'package:social_media_app/features/auth/data/models/user_data.dart';
import 'package:social_media_app/features/profile/services/edit_profile_services.dart';
import '../../../../core/errors/supabase_error_mapper.dart';
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
    bool removeProfileImage = false,
    bool removeBackgroundImage = false,
    Map<String, String>? socialLinks,
  }) async {
    emit(EditProfileLoading());
    try {
      // ── تحسين السرعة: رفع صورة البروفايل وصورة الكفر بالتوازي
      // بدل ما ننتظر كل واحدة لوحدها بالتتابع (Sequential await) ──
      final uploadResults = await Future.wait([
        profileImage != null
            ? _editProfileServices.uploadImage(
              file: profileImage,
              userId: oldUser.id,
              folder: 'avatars',
            )
            : Future.value(null),
        backgroundImage != null
            ? _editProfileServices.uploadImage(
              file: backgroundImage,
              userId: oldUser.id,
              folder: 'backgrounds',
            )
            : Future.value(null),
      ]);

      final profileUploadResult = uploadResults[0];
      final backgroundUploadResult = uploadResults[1];

      final updates = <String, dynamic>{
        'name': name,
        'username': userName,
        'title': title,
        'bio': bio,
        if (socialLinks != null) UserColumns.socialLinks: socialLinks,
      };

      if (profileUploadResult != null) {
        updates['image_url'] = profileUploadResult.secureUrl;
        updates['image_public_id'] = profileUploadResult.publicId;
      } else if (removeProfileImage) {
        updates['image_url'] = null;
        updates['image_public_id'] = null;
      }

      if (backgroundUploadResult != null) {
        updates['background_image_url'] = backgroundUploadResult.secureUrl;
        updates['background_image_public_id'] = backgroundUploadResult.publicId;
      } else if (removeBackgroundImage) {
        updates['background_image_url'] = null;
        updates['background_image_public_id'] = null;
      }

      await _editProfileServices.updateUserData(oldUser.id, updates);

      // ── تنظيف أي صورة قديمة بقت orphan على Cloudinary، بعد نجاح
      // الحفظ في الداتابيز فقط، وبدون await عشان ميأخرش ظهور النجاح
      // للمستخدم (fire-and-forget، وMediaCleanupService أصلاً
      // بتعمل catch داخلي فمافيش خطر على استقرار الشاشة) ──
      _cleanupStaleAssets(
        oldUser: oldUser,
        profileReplaced: profileUploadResult != null,
        profileRemoved: removeProfileImage,
        backgroundReplaced: backgroundUploadResult != null,
        backgroundRemoved: removeBackgroundImage,
      );

      UserData updatedUser;
      if (removeProfileImage || removeBackgroundImage) {
        updatedUser = await _editProfileServices.fetchUpdatedUser(oldUser.id);
      } else {
        updatedUser = oldUser.copyWith(
          name: name,
          userName: userName,
          title: title,
          bio: bio,
          imageUrl: profileUploadResult?.secureUrl ?? oldUser.imageUrl,
          backgroundImageUrl:
              backgroundUploadResult?.secureUrl ?? oldUser.backgroundImageUrl,
          socialLinks: socialLinks ?? oldUser.socialLinks,
        );
      }

      emit(EditProfileSuccess(updatedUser));
    } catch (e) {
      debugPrint('Error updating profile: $e');
      emit(EditProfileError(SupabaseErrorMapper.toUserMessage(e)));
    }
  }

  void _cleanupStaleAssets({
    required UserData oldUser,
    required bool profileReplaced,
    required bool profileRemoved,
    required bool backgroundReplaced,
    required bool backgroundRemoved,
  }) {
    final staleIds = <String>[];

    if (profileReplaced || profileRemoved) {
      final oldId = oldUser.imagePublicId;
      if (oldId != null && oldId.isNotEmpty) staleIds.add(oldId);
    }
    if (backgroundReplaced || backgroundRemoved) {
      final oldId = oldUser.backgroundImagePublicId;
      if (oldId != null && oldId.isNotEmpty) staleIds.add(oldId);
    }

    if (staleIds.isEmpty) return;
    MediaCleanupService.instance.deleteRawAssets(
      publicIds: staleIds,
      resourceType: 'image',
    );
  }
}
