import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/core/services/cloudinary_upload_result.dart';
import 'package:social_media_app/features/auth/data/models/user_data.dart';
import '../../../core/services/cloudinary_storage_services.dart';
import '../../../core/supabase/supabase_provider.dart';

class EditProfileServices {
  final _supabase = SupabaseProvider.client;
  final _picker = ImagePicker();
  final CloudinaryStorageServices storage = CloudinaryStorageServices.instance;

  Future<void> updateUserData(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    await _supabase.from('users').update(updates).eq('id', userId);
  }

  Future<CloudinaryUploadResult> uploadImage({
    required File file,
    required String userId,
    required String folder,
  }) async {
    final filePrefix = folder == 'avatars' ? 'profile_' : 'background_';
    return await storage.uploadFile(
      file,
      folder,
      userId,
      filePrefix: filePrefix,
    );
  }

  Future<UserData> fetchUpdatedUser(String userId) async {
    final data =
        await _supabase.from('users').select().eq('id', userId).single();
    return UserData.fromMap(data);
  }

  Future<File?> pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      // imageQuality: 70,
    );
    if (pickedFile != null) {
      return File(pickedFile.path);
    } else {
      return null;
    }
  }
}
