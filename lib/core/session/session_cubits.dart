import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/cache/repository/media_cache_repository.dart';
import 'package:social_media_app/core/services/cloudinary_storage_services.dart';
import 'package:social_media_app/features/group_chats/cubits/group_list_cubit/group_list_cubit.dart';
import 'package:social_media_app/features/group_chats/services/group_chat_services.dart';
import 'package:social_media_app/features/home/cubits/home_cubit/home_cubit.dart';
import 'package:social_media_app/features/posts/cubits/posts_cubit/posts_cubit.dart';
import 'package:social_media_app/features/posts/services/posts_services.dart';
import 'package:social_media_app/features/profile/services/user_services.dart';
import 'package:social_media_app/features/reels/cubits/reels_feed_cubit/reels_feed_cubit.dart';
import 'package:social_media_app/features/single_calls/cubits/single_call_cubit/call_cubit.dart';
import 'package:social_media_app/features/single_calls/services/call_signaling_service.dart';
import 'package:social_media_app/features/single_chats/cubits/chats_cubit/chats_cubit.dart';
import 'package:social_media_app/features/single_chats/services/chat_services.dart';
import 'package:social_media_app/features/stories/cubits/stories_cubit/stories_cubit.dart';

/// Every Cubit whose data belongs to ONE signed-in account.

class SessionCubits {
  final String? userId;
  final PostsCubit posts;
  final HomeCubit home;
  final StoriesCubit stories;
  final ReelsFeedCubit reels;
  final GroupListCubit groups;
  final CallCubit call;
  final ChatsCubit chats;

  SessionCubits._({
    required this.userId,
    required this.posts,
    required this.home,
    required this.stories,
    required this.reels,
    required this.groups,
    required this.call,
    required this.chats,
  });

  /// Builds a bundle. Data loading starts only when [userId] is non-null, so
  /// a signed-out app never issues requests with an empty user id.
  factory SessionCubits.create(
    BuildContext context, {
    required String? userId,
  }) {
    final posts = PostsCubit(
      postsServices: context.read<PostsServices>(),
      storage: context.read<CloudinaryStorageServices>(),
      mediaCacheRepository: context.read<MediaCacheRepository>(),
    );
    final home = HomeCubit(
      userService: context.read<UserService>(),
      postsCubit: posts,
    );
    final stories = StoriesCubit();
    final reels = ReelsFeedCubit();
    final groups = GroupListCubit(context.read<GroupChatServices>());
    final call = CallCubit(
      signalingService: context.read<CallSignalingService>(),
      chatServices: context.read<ChatServices>(),
    );
    final chats = ChatsCubit(context.read<ChatServices>());

    if (userId != null) {
      posts.fetchPosts();
      home.getCurrentUserData();
      stories.fetchStories();
      groups.monitorGroups();
      chats.monitorChats();
    }

    return SessionCubits._(
      userId: userId,
      posts: posts,
      home: home,
      stories: stories,
      reels: reels,
      groups: groups,
      call: call,
      chats: chats,
    );
  }

  /// Closes every Cubit. One failing `close()` must not leave the others
  /// (and their channels) alive.
  Future<void> close() async {
    final closers = <Future<void> Function()>[
      chats.close,
      groups.close,
      call.close,
      reels.close,
      stories.close,
      home.close,
      posts.close,
    ];
    for (final close in closers) {
      try {
        await close();
      } catch (e, s) {
        debugPrint('[SessionCubits] close failed: $e\n$s');
      }
    }
  }
}
