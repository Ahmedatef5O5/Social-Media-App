// import 'dart:io';
// import 'package:dio/dio.dart' as dio_pkg;
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../secrets/app_secrets.dart';

// class SupabaseStorageServices {
//   SupabaseStorageServices._();

//   static final instance = SupabaseStorageServices._();

//   final _supabase = SupabaseProvider.client;

//   final _dio = dio_pkg.Dio(
//     dio_pkg.BaseOptions(
//       sendTimeout: const Duration(minutes: 3),
//       receiveTimeout: const Duration(minutes: 3),
//     ),
//   );

//   Future<String> uploadFile(
//     File file,
//     String bucket,
//     String folder, {
//     String? userId,
//     String filePrefix = '',
//     void Function(double progress)? onProgress,
//     dio_pkg.CancelToken? cancelToken,
//   }) async {
//     if (!await file.exists()) {
//       throw Exception('file_not_found: ${file.path}');
//     }

//     final session = _supabase.auth.currentSession;
//     if (session == null || session.isExpired) {
//       throw Exception('session_expired');
//     }

//     final ext = _extractExtension(file.path);
//     final timestamp = DateTime.now().millisecondsSinceEpoch;
//     final fileName = '$filePrefix$timestamp.$ext';

//     final effectiveUserId = userId ?? _supabase.auth.currentUser?.id;
//     final uploadPath =
//         effectiveUserId != null
//             ? '$effectiveUserId/$folder/$fileName'
//             : '$folder/$fileName';

//     final contentType = _resolveContentType(ext, folder);
//     final fileLength = await file.length();

//     final accessToken = session.accessToken;

//     onProgress?.call(0.0);

//     try {
//       await _dio.put(
//         '${AppSecrets.supabaseUrl}/storage/v1/object/$bucket/$uploadPath',
//         data: file.openRead(),
//         options: dio_pkg.Options(
//           headers: {
//             'Authorization': 'Bearer $accessToken',
//             'Content-Type': contentType,
//             'x-upsert': 'false',
//             'Content-Length': fileLength.toString(),
//           },
//         ),
//         onSendProgress: (sent, total) {
//           final actualTotal = total > 0 ? total : fileLength;
//           onProgress?.call((sent / actualTotal).clamp(0.0, 1.0));
//         },
//       );

//       onProgress?.call(1.0);

//       return _supabase.storage.from(bucket).getPublicUrl(uploadPath);
//     } on dio_pkg.DioException catch (e) {
//       if (e.type == dio_pkg.DioExceptionType.cancel) {
//         debugPrint('⚠️ Upload canceled by user');
//         throw const UploadCanceledException();
//       }
//       debugPrint('❌ Upload error: ${e.response?.data ?? e.message}');
//       rethrow;
//     }
//   }

//   String _extractExtension(String path) => path.split('.').last.toLowerCase();

//   String _resolveContentType(String ext, String folder) {
//     switch (ext) {
//       case 'jpg':
//       case 'jpeg':
//         return 'image/jpeg';
//       case 'png':
//         return 'image/png';
//       case 'gif':
//         return 'image/gif';
//       case 'webp':
//         return 'image/webp';
//       case 'mp4':
//         return 'video/mp4';
//       case 'mov':
//         return 'video/quicktime';
//       case 'm4a':
//       case 'aac':
//         return 'audio/x-m4a';
//       case 'mp3':
//         return 'audio/mpeg';
//       case 'ogg':
//         return 'audio/ogg';
//       case 'pdf':
//         return 'application/pdf';
//       default:
//         if (folder.contains('image')) return 'image/jpeg';
//         if (folder.contains('video')) return 'video/mp4';
//         if (folder.contains('voice') || folder.contains('audio')) {
//           return 'audio/mpeg';
//         }
//         return 'application/octet-stream';
//     }
//   }
// }

class UploadCanceledException implements Exception {
  const UploadCanceledException();

  @override
  String toString() => 'UploadCanceledException: upload was canceled by user';
}
