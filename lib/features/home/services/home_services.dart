import 'package:social_media_app/core/services/supabase_database_services.dart';
import 'package:social_media_app/features/home/models/story_model.dart';

class HomeServices {
  final supabaseServices = SupabaseDatabaseServices.instance;

  Future<List<StoryModel>> fetchStories() async {
    try {
      return await supabaseServices.fetchRows(
        table: 'stories',
        builder: (data, id) => StoryModel.fromMap(data),
        primaryKey: 'id',
      );
    } catch (e) {
      rethrow;
    }
  }
}
