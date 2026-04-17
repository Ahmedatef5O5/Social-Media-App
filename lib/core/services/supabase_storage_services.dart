import 'dart:io';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../secrets/app_secrets.dart';

class SupabaseStorageServices {
  final _supabase = Supabase.instance.client;

  dio_pkg.CancelToken? _uploadCancelToken;

  Future<String?> uploadFile(
    File file,
    String bucket,
    String folderName, {
    void Function(double)? onProgress,
  }) async {
    try {
      if (!await file.exists()) {
        throw Exception('file_not_found');
      }

      _uploadCancelToken = dio_pkg.CancelToken();

      final ext = file.path.split('.').last.toLowerCase();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
      final uploadPath = '$folderName/$fileName';
      String contentType = _determineContentType(ext);

      final fileLength = await file.length();

      final accessToken =
          _supabase.auth.currentSession?.accessToken ??
          AppSecrets.supabaseAnonKey;

      final dioClient = dio_pkg.Dio();

      await dioClient.put(
        '${AppSecrets.supabaseUrl}/storage/v1/object/$bucket/$uploadPath',
        data: file.openRead(),
        cancelToken: _uploadCancelToken,
        options: dio_pkg.Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': contentType,
            'x-upsert': 'false',
            'Content-Length': fileLength.toString(),
          },
        ),
        onSendProgress: (sent, total) {
          final actualTotal = total > 0 ? total : fileLength;
          final progress = (sent / actualTotal).clamp(0.0, 1.0);
          onProgress?.call(progress);
        },
      );

      return _supabase.storage.from(bucket).getPublicUrl(uploadPath);
    } catch (e) {
      if (e is dio_pkg.DioException &&
          e.type == dio_pkg.DioExceptionType.cancel) {
        debugPrint('Upload Canceled by User');
        throw Exception('canceled');
      }
      debugPrint('Error uploading file in HomeServices: $e');
      rethrow;
    }
  }

  void cancelCurrentUpload() {
    if (_uploadCancelToken != null && !_uploadCancelToken!.isCancelled) {
      _uploadCancelToken?.cancel("Upload Canceled by User");
    }
  }

  String _determineContentType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}
