import 'package:supabase_flutter/supabase_flutter.dart';

class MediaCleanupService {
  MediaCleanupService._();

  static final MediaCleanupService instance = MediaCleanupService._();

  final _supabase = Supabase.instance.client;

  Future<void> deleteWithMedia({
    required String table,
    required String id,
  }) async {
    final response = await _supabase.functions.invoke(
      'delete-media-asset',
      body: {'table': table, 'id': id},
    );

    if (response.status != 200) {
      throw Exception(
        'delete_media_asset_failed: ${response.data ?? response.status}',
      );
    }
  }
}
