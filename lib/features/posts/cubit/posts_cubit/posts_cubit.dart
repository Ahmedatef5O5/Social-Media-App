// ignore_for_file: unused_field
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/features/social_graph/models/content_privacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:social_media_app/core/cache/constants/snapshot_keys.dart';
import 'package:social_media_app/core/cache/services/local_snapshot_store.dart';
import 'package:social_media_app/core/services/file_picker_services.dart';
import 'package:social_media_app/core/services/network_status_service.dart';
import 'package:social_media_app/features/auth/data/models/user_data.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/connectivity/services/connectivity_banner_controller.dart';
import '../../../../core/services/cloudinary_storage_services.dart';
import '../../../../core/presence/services/presence_service.dart';
import '../../../../core/services/fcm_services.dart';
import '../../../../core/supabase/supabase_provider.dart';
import '../../../../core/toast/app_toast.dart';
import '../../../comments/events/comment_event_bus.dart';
import '../../../comments/events/comment_events.dart';
import '../../../comments/model/comment_model.dart';
import '../../../notifications/repository/notifications_repository.dart';
import '../../model/feed_event.dart';
import '../../model/post_model.dart';
import '../../model/post_reaction_model.dart';
import '../../model/post_request_body.dart';
import '../../services/posts_services.dart';
import '../../../reels/model/reel_model.dart';
import 'package:social_media_app/core/mentions/mentions.dart';

part 'posts_state.dart';
part 'posts_feed_mixin.dart';
part 'posts_realtime_mixin.dart';
part 'posts_comment_bridge_mixin.dart';
part 'post_creation_mixin.dart';
part 'post_reactions_mixin.dart';
part 'reel_share_mixin.dart';

const int kMaxCachedPostsSnapshot = 30;

class PostsCubit extends Cubit<PostsState>
    with
        PostsRealtimeMixin,
        PostsFeedMixin,
        PostsCommentBridgeMixin,
        PostCreationMixin,
        PostReactionsMixin,
        ReelShareMixin {
  @override
  final PostsServices _postsServices;
  @override
  final CloudinaryStorageServices _storage;
  final NetworkStatusService _networkStatus;

  PostsCubit({
    required PostsServices postsServices,
    required CloudinaryStorageServices storage,
    NetworkStatusService? networkStatus,
  }) : _postsServices = postsServices,
       _storage = storage,
       _networkStatus = networkStatus ?? NetworkStatusService.instance,
       super(PostsInitial()) {
    _listenToCommentEvents();
  }

  @override
  UserData? currentUserData;

  void setCurrentUser(UserData user) {
    currentUserData = user;
  }

  @override
  List<PostModel> _fixLikersImages(List<PostModel> posts) {
    PostModel fixSingle(PostModel post) {
      if (post.likes == null || post.likes!.isEmpty) return post;
      final likersImages = post.likersImages ?? [];
      if (likersImages.length >= post.likes!.length) return post;
      final fixedImages = List<String>.from(likersImages);
      final missing = post.likes!.length - likersImages.length;
      for (int i = 0; i < missing; i++) {
        fixedImages.add('asset:default');
      }
      return post.copyWith(likersImages: fixedImages);
    }

    return posts.map((post) {
      final fixedPost = fixSingle(post);
      final original = fixedPost.originalPost;
      if (original == null) return fixedPost;
      final fixedOriginal = fixSingle(original);
      return identical(fixedOriginal, original)
          ? fixedPost
          : fixedPost.copyWith(originalPost: fixedOriginal);
    }).toList();
  }
}
