import '../views/post_details_view.dart';
import 'post_model.dart';

class PostDetailsRouteArgs {
  final PostModel post;
  final PostDetailsActiveMode initialActiveMode;

  const PostDetailsRouteArgs({
    required this.post,
    this.initialActiveMode = PostDetailsActiveMode.comments,
  });
}
