import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_database_services.dart';
import '../../../core/services/supabase_storage_services.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../../home/models/story_model.dart';

class StoriesServices {
  final _supabase = Supabase.instance.client;
  final supabaseServices = SupabaseDatabaseServices.instance;
  final storageServices = SupabaseStorageServices();

  Future<String> uploadStoryFile(File file, String userId) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final path = '$userId/$fileName';
    await _supabase.storage.from(SupabaseConstants.stories).upload(path, file);
    return _supabase.storage.from(SupabaseConstants.stories).getPublicUrl(path);
  }

  Future<String> uploadStoryVideoFile(File file, String userId) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final path = '$userId/$fileName';

    await _supabase.storage
        .from(SupabaseConstants.storyVideos)
        .upload(path, file);

    return _supabase.storage
        .from(SupabaseConstants.storyVideos)
        .getPublicUrl(path);
  }

  Future<List<StoryModel>> fetchStories() async {
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
      await _supabase
          .from(SupabaseConstants.stories)
          .delete()
          .eq(StoryColumns.id, storyId);
    } catch (e) {
      rethrow;
    }
  }
}
