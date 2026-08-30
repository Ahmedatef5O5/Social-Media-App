import 'package:flutter/material.dart';
import '../../features/posts/models/post_details_route_args.dart';
import '../../features/posts/services/posts_services.dart';
import '../../features/posts/views/post_details_view.dart';
import '../notifications/notification_navigator_key.dart';
import '../router/app_routes.dart';
import '../toast/app_toast.dart';

class ContentDeepLinkNavigator {
  ContentDeepLinkNavigator._();

  static Future<void> openPost(
    String postId, [
    PostDetailsActiveMode initialActiveMode = PostDetailsActiveMode.comments,
  ]) async {
    final post = await PostsServices().fetchPostById(postId);
    if (post == null) {
      AppToast.info('This post is no longer available.');
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.homeRoute,
        (route) => false,
      );
      navigatorKey.currentState?.pushNamed(
        AppRoutes.postDetailsViewRoute,
        arguments: PostDetailsRouteArgs(
          post: post,
          initialActiveMode: initialActiveMode,
        ),
      );
    });
  }

  static void openStoryById(String storyId, {String? authorId}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.homeRoute,
        (route) => false,
      );
      navigatorKey.currentState?.pushNamed(
        AppRoutes.storyDisplayViewRoute,
        arguments: {'storyId': storyId, 'authorId': authorId},
      );
    });
  }
}
