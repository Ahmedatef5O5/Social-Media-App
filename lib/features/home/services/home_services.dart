import 'package:social_media_app/core/services/supabase_database_services.dart';
import 'package:social_media_app/features/comments/services/comments_service.dart';
import 'package:social_media_app/features/home/services/posts_services.dart';
import 'package:social_media_app/features/profile/services/user_services.dart';
import '../../../core/services/supabase_storage_services.dart';
import '../../stories/services/stories_services.dart';

class HomeServices {
  final supabaseServices = SupabaseDatabaseServices.instance;
  final storage = SupabaseStorageServices();
  final postServices = PostsServices();
  final storyServices = StoriesServices();
  final commentServices = CommentsService();
  final userServices = UserService();
}
