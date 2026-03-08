import 'package:social_media_app/core/services/supabase_database_services.dart';
import 'package:social_media_app/core/utilities/app_tables_names.dart';
import 'package:social_media_app/features/home/models/post_model.dart';
import 'package:social_media_app/features/home/models/post_request_body.dart';
import 'package:social_media_app/features/home/models/story_model.dart';

class HomeServices {
  final supabaseServices = SupabaseDatabaseServices.instance;

  Future<List<StoryModel>> fetchStories() async {
    try {
      return await supabaseServices.fetchRows(
        table: AppTablesNames.stories,
        filter:
            (query) =>
                query.select('''*,${AppTablesNames.users}(${UserColumns.name}, 
        ${UserColumns.imageUrl})}
        )'''),
        builder: (data, id) => StoryModel.fromMap(data),
        primaryKey: StoryColumns.id,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<PostModel>> fetchPosts() async {
    try {
      return await supabaseServices.fetchRows(
        table: AppTablesNames.posts,
        filter:
            (query) => query.select(''' 
        *,
         ${AppTablesNames.users}
        (${UserColumns.name}, ${UserColumns.imageUrl})
        
        '''),
        builder:
            (Map<String, dynamic> data, String id) => PostModel.fromMap(data),
        primaryKey: PostColumns.id,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addPost(PostRequestBody post) async {
    try {
      await supabaseServices.insertRow(
        table: AppTablesNames.posts,
        values: post.toMap(),
      );
    } catch (e) {
      rethrow;
    }
  }
}
