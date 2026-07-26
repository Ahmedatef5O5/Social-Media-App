import 'dart:io';

import 'package:dio/dio.dart';

abstract class MediaCacheRepository {
  void initialize();

  Future<String?> resolveLocalPath(
    String secureUrl, {
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  });

  bool isAvailableOffline(String secureUrl);

  String? resolveLocalPathSync(String secureUrl);

  Future<int> runEvictionSweep();

  Future<void> adoptUploadedFile(String secureUrl, File localFile);
}
