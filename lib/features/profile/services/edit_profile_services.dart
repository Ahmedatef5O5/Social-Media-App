import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/cloudinary_storage_services.dart';

class EditProfileServices {
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();
  final CloudinaryStorageServices storage = CloudinaryStorageServices.instance;

  Future<void> updateUserData(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    await _supabase.from('users').update(updates).eq('id', userId);
  }

  Future<String> uploadImage({
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
