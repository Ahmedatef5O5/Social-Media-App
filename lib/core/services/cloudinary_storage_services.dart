import 'dart:io';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/foundation.dart';
import 'package:social_media_app/core/services/cloudinary_upload_result.dart';
import '../secrets/app_secrets.dart';

class CloudinaryStorageServices {
  CloudinaryStorageServices._();

  static final instance = CloudinaryStorageServices._();

  final _dio = dio_pkg.Dio(
    dio_pkg.BaseOptions(
      sendTimeout: const Duration(minutes: 3),
      receiveTimeout: const Duration(minutes: 3),
    ),
  );

  Future<CloudinaryUploadResult> uploadFile(
    File file,
    String topFolder,
    String subFolder, {
    String filePrefix = '',
    void Function(double progress)? onProgress,
    dio_pkg.CancelToken? cancelToken,
  }) async {
    if (!await file.exists()) {
      throw Exception('file_not_found: ${file.path}');
    }

    final cloudName = AppSecrets.cloudinaryCloudName;
    final uploadPreset = AppSecrets.cloudinaryUploadPreset;
    final ext = _extractExtension(file.path);
    final resourceType = _resolveResourceType(ext);

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final publicIdPrefix = '$filePrefix$timestamp';
    final folderPath = '$topFolder/$subFolder';

    onProgress?.call(0.0);

    try {
      final formData = dio_pkg.FormData.fromMap({
        'upload_preset': uploadPreset,
        'folder': folderPath,
        'public_id': publicIdPrefix,
        'file': await dio_pkg.MultipartFile.fromFile(
          file.path,
          filename: '$publicIdPrefix.$ext',
        ),
      });

      final response = await _dio.post(
        'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload',
        data: formData,
        onSendProgress: (sent, total) {
          final actualTotal = total > 0 ? total : 1;
          onProgress?.call((sent / actualTotal).clamp(0.0, 1.0));
        },
        cancelToken: cancelToken,
      );

      onProgress?.call(1.0);

      final data = response.data as Map<String, dynamic>;
      final secureUrl = data['secure_url'] as String?;
      final publicId = data['public_id'] as String?;
      if (secureUrl == null || publicId == null) {
        throw Exception(
          'cloudinary_upload_failed: missing secure_url/public_id',
        );
      }

      return CloudinaryUploadResult(
        secureUrl: buildOptimizedUrl(
          secureUrl,
          isVideo: resourceType == 'video',
        ),
        publicId: publicId,
        resourceType: resourceType,
      );
    } on dio_pkg.DioException catch (e) {
      if (e.type == dio_pkg.DioExceptionType.cancel) {
        debugPrint('⚠️ Upload canceled by user');
        throw const UploadCanceledException();
      }
      final serverMessage =
          (e.response?.data is Map)
              ? (e.response?.data['error']?['message'] as String?)
              : null;
      debugPrint('❌ Cloudinary upload error: ${serverMessage ?? e.message}');
      throw Exception(serverMessage ?? 'cloudinary_upload_failed');
    }
  }

  String buildOptimizedUrl(String secureUrl, {bool isVideo = false}) {
    const marker = '/upload/';
    final idx = secureUrl.indexOf(marker);
    if (idx == -1) return secureUrl;

    final transformation = isVideo ? 'f_auto,q_auto' : 'f_auto,q_auto';
    final insertAt = idx + marker.length;
    return '${secureUrl.substring(0, insertAt)}$transformation/${secureUrl.substring(insertAt)}';
  }

  String _extractExtension(String path) => path.split('.').last.toLowerCase();

  String _resolveResourceType(String ext) {
    const imageExts = {'jpg', 'jpeg', 'png', 'gif', 'webp'};
    const videoOrAudioExts = {'mp4', 'mov', 'm4a', 'aac', 'mp3', 'ogg'};

    if (imageExts.contains(ext)) return 'image';
    if (videoOrAudioExts.contains(ext)) return 'video';
    return 'raw';
  }
}

class UploadCanceledException implements Exception {
  const UploadCanceledException();

  @override
  String toString() => 'UploadCanceledException: upload was canceled by user';
}
