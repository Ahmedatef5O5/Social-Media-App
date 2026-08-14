import 'dart:typed_data';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Fetches remote media bytes through the shared HTTP cache so the AI
/// vision pipeline reuses whatever is already cached for on-screen display,
/// instead of re-downloading the file.
class RemoteMediaFetcher {
  static Future<Uint8List?> fetchBytes(String url) async {
    try {
      final file = await DefaultCacheManager().getSingleFile(url);
      return await file.readAsBytes();
    } catch (_) {
      return null;
    }
  }
}
