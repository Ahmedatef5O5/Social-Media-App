import 'dart:io';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:social_media_app/core/services/cloudinary_upload_result.dart';
import 'package:social_media_app/core/services/network_status_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/cloudinary_storage_services.dart';
import '../../../core/services/media_cleanup_service.dart';
import '../../../core/services/supabase_database_services.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../model/story_model.dart';

class StoriesServices {
  final _supabase = Supabase.instance.client;
  final supabaseServices = SupabaseDatabaseServices.instance;
  final CloudinaryStorageServices storage = CloudinaryStorageServices.instance;

  Future<CloudinaryUploadResult> uploadStoryFile(
    File file,
    String userId, {
    void Function(double progress)? onProgress,
    dio_pkg.CancelToken? cancelToken,
  }) async {
    return await storage.uploadFile(
      file,
      'stories',
      userId,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  Future<CloudinaryUploadResult> uploadStoryVideoFile(
    File file,
    String userId, {
    void Function(double progress)? onProgress,
    dio_pkg.CancelToken? cancelToken,
  }) async {
    return await storage.uploadFile(
      file,
      // SupabaseConstants.storyVideos,
      'stories',
      userId,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  Future<List<StoryModel>> fetchStories() async {
    if (!(await NetworkStatusService.instance.isConnected())) {
      throw Exception('no-internet');
    }

    try {
      return await supabaseServices.fetchRows(
        table: SupabaseConstants.stories,
        filter:
            (query) => query
                .select('''*,${SupabaseConstants.users}(${UserColumns.name}, 
        ${UserColumns.imageUrl})}
        )''')
                .order(StoryColumns.createdAt, ascending: false),
        builder: (data, id) => StoryModel.fromMap(data),
        primaryKey: StoryColumns.id,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createStory(StoryModel story) async {
    await _supabase.from(SupabaseConstants.stories).insert(story.toMap());
  }

  Future<void> deleteStory(String storyId) async {
    try {
      await MediaCleanupService.instance.deleteWithMedia(
        table: SupabaseConstants.stories,
        id: storyId,
      );
    } catch (e) {
      rethrow;
    }
  }
}
