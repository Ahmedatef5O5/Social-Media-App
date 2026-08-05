import 'package:flutter/foundation.dart';
import 'package:social_media_app/core/supabase/supabase_provider.dart';

class MediaCleanupService {
  MediaCleanupService._();

  static final MediaCleanupService instance = MediaCleanupService._();

  Future<void> deleteWithMedia({
    required String table,
    required String id,
  }) async {
    final response = await SupabaseProvider.client.functions.invoke(
      'delete-media-asset',
      body: {'table': table, 'id': id},
    );

    if (response.status != 200) {
      throw Exception(
        'delete_media_asset_failed: ${response.data ?? response.status}',
      );
    }
  }

  Future<void> deleteRawAssets({
    required List<String> publicIds,
    required String resourceType,
  }) async {
    if (publicIds.isEmpty) return;
    try {
      final response = await SupabaseProvider.client.functions.invoke(
        'delete-media-asset',
        body: {
          'mode': 'raw',
          'publicIds': publicIds,
          'resourceType': resourceType,
        },
      );
      if (response.status != 200) {
        debugPrint(
          '[MediaCleanupService] deleteRawAssets failed: '
          '${response.data ?? response.status}',
        );
      }
    } catch (e) {
      debugPrint('[MediaCleanupService] deleteRawAssets error: $e');
    }
  }
}
