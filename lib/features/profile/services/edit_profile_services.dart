import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileServices {
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();

  Future<void> updateUserData(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    await _supabase.from('users').update(updates).eq('id', userId);
  }

  Future<String> uploadImage({
    required File file,
    required String path,
    required String bucket,
  }) async {
    await _supabase.storage
        .from(bucket)
        .upload(path, file, fileOptions: const FileOptions(upsert: true));
    return _supabase.storage.from(bucket).getPublicUrl(path);
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
