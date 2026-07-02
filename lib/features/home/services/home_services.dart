import 'package:social_media_app/core/services/supabase_database_services.dart';
import 'package:social_media_app/features/comments/services/comments_service.dart';
import 'package:social_media_app/features/home/services/posts_services.dart';
import 'package:social_media_app/features/profile/services/user_services.dart';
import '../../../core/services/cloudinary_storage_services.dart';
import '../../stories/services/stories_services.dart';

class HomeServices {
  HomeServices._();
  static final HomeServices instance = HomeServices._();

  final SupabaseDatabaseServices supabaseServices =
      SupabaseDatabaseServices.instance;
  final CloudinaryStorageServices storage = CloudinaryStorageServices.instance;
  final PostsServices postServices = PostsServices();
  final StoriesServices storyServices = StoriesServices();
  final CommentsService commentServices = CommentsService();
  final UserService userServices = UserService();
}
