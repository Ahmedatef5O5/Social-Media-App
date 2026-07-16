import 'dart:async';
import 'package:flutter/material.dart';
import 'package:social_media_app/features/posts/model/feed_event.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/media_cleanup_service.dart';
import '../../../core/services/network_status_service.dart';
import '../../../core/services/presence_service.dart';
import '../../../core/services/supabase_database_services.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../../comments/helper/comment_tree_builder.dart';
import '../../comments/model/comment_model.dart';
import '../model/post_model.dart';
import '../model/post_request_body.dart';

class PostsServices {
  final supabaseServices = SupabaseDatabaseServices.instance;
  final _supabase = SupabaseProvider.client;
  final NetworkStatusService _networkStatus;

  PostsServices({NetworkStatusService? networkStatus})
    : _networkStatus = networkStatus ?? NetworkStatusService.instance;

  static const String _postFields = ''' 
  *,
  saved_count,
  is_post_saved,
  shares_count,
  is_post_shared,
  ${SupabaseConstants.users} (${UserColumns.name}, ${UserColumns.imageUrl}, ${UserColumns.lastSeen}),
  ${SupabaseConstants.comments} (
  *,
  ${SupabaseConstants.users} (${UserColumns.name}, ${UserColumns.imageUrl}), 
  comment_reactions (*)
  ),
  ${SupabaseConstants.likes} (
  ${LikeColumns.userId}, 
  ${LikeColumns.reaction},
  ${SupabaseConstants.users} (${UserColumns.imageUrl}))
''';

  static const String _postsQuery = _postFields;

  PostModel _hydratePost(Map<String, dynamic> data) {
    final post = PostModel.fromMap(data);

    final flatComments =
        (data['comments'] as List? ?? [])
            .map((e) => CommentModel.fromMap(e))
            .toList();
    final tree = CommentTreeBuilder.build(flatComments);

    PostModel? hydratedOriginal;
    final originalData =
        data[PostColumns.originalPostRelation] as Map<String, dynamic>?;
    if (originalData != null) {
      hydratedOriginal = _hydratePost(originalData);
    }
    return post.copyWith(
      comments: tree,
      originalPost: hydratedOriginal ?? post.originalPost,
    );
  }

  Future<List<PostModel>> _resolveSharedPostsAndHydrate(
    List<Map<String, dynamic>> rawPostsData,
  ) async {
    if (rawPostsData.isEmpty) return [];

    final Set<String> sharedPostIds =
        rawPostsData
            .map((p) => p['shared_post_id'] as String?)
            .whereType<String>()
            .toSet();

    final Map<String, Map<String, dynamic>> originalsDataMap = {};

    if (sharedPostIds.isNotEmpty) {
      try {
        final originalsResponse = await _supabase
            .from(SupabaseConstants.posts)
            .select(_postsQuery)
            .inFilter(PostColumns.id, sharedPostIds.toList());

        for (final org in originalsResponse as List) {
          originalsDataMap[org[PostColumns.id] as String] =
              org as Map<String, dynamic>;
        }
      } catch (e) {
        debugPrint('Error fetching original posts batch: $e');
      }
    }

    return rawPostsData.map((data) {
      final mutableData = Map<String, dynamic>.from(data);
      final sharedId = mutableData['shared_post_id'] as String?;

      if (sharedId != null && originalsDataMap.containsKey(sharedId)) {
        mutableData[PostColumns.originalPostRelation] =
            originalsDataMap[sharedId];
      }
      return _hydratePost(mutableData);
    }).toList();
  }

  Future<Map<String, bool>> _fetchOnlineMap(List<String> authorIds) async {
    if (authorIds.isEmpty) return {};
    final presenceRows = await _supabase
        .from(SupabaseConstants.userPresence)
        .select('user_id, is_online, updated_at')
        .inFilter(GroupMemberColumns.userId, authorIds);

    final onlineSet = <String>{
      for (final row in presenceRows as List)
        if (PresenceService.isConsideredOnline(
          isOnline: row[PresenceColumns.isOnline] as bool? ?? false,
          updatedAt:
              row[PresenceColumns.updatedAt] != null
                  ? DateTime.parse(row[PresenceColumns.updatedAt].toString())
                  : null,
        ))
          row[GroupMemberColumns.userId] as String,
    };
    return {for (final id in authorIds) id: onlineSet.contains(id)};
  }

  PostModel _applyOnline(PostModel post, Map<String, bool> onlineMap) {
    final withOnline = post.copyWith(
      isOnline: onlineMap[post.authorId] ?? false,
    );
    if (withOnline.originalPost == null) return withOnline;
    return withOnline.copyWith(
      originalPost: withOnline.originalPost!.copyWith(
        isOnline: onlineMap[withOnline.originalPost!.authorId] ?? false,
      ),
    );
  }

  Future<PostModel?> fetchPostById(String postId) async {
    try {
      final rows = await _supabase
          .from(SupabaseConstants.posts)
          .select(_postsQuery)
          .eq(PostColumns.id, postId)
          .limit(1);

      if (rows.isEmpty) return null;

      final hydratedList = await _resolveSharedPostsAndHydrate(
        List<Map<String, dynamic>>.from(rows),
      );
      if (hydratedList.isEmpty) return null;

      final postWithComments = hydratedList.first;
      final authorIds =
          <String>{
            postWithComments.authorId,
            if (postWithComments.originalPost != null)
              postWithComments.originalPost!.authorId,
          }.toList();

      final onlineMap = await _fetchOnlineMap(authorIds);
      return _applyOnline(postWithComments, onlineMap);
    } catch (e) {
      debugPrint('fetchPostById error: $e');
      return null;
    }
  }

  Future<List<PostModel>> fetchPosts() async {
    if (!(await _networkStatus.isConnected())) {
      throw Exception('no-internet');
    }
    try {
      final response = await _supabase
          .from(SupabaseConstants.posts)
          .select(_postsQuery)
          .order(PostColumns.createdAt, ascending: false);

      final List<Map<String, dynamic>> rawPosts =
          List<Map<String, dynamic>>.from(response);

      final posts = await _resolveSharedPostsAndHydrate(rawPosts);

      if (posts.isEmpty) return posts;

      final authorIds =
          <String>{
            for (final p in posts) ...[
              p.authorId,
              if (p.originalPost != null) p.originalPost!.authorId,
            ],
          }.toList();

      final onlineMap = await _fetchOnlineMap(authorIds);

      return posts.map((p) => _applyOnline(p, onlineMap)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<FeedEvent> getPostsStream() {
    final controller = StreamController<FeedEvent>.broadcast();

    const channelName = 'home_feed_watcher';
    _supabase.removeChannel(_supabase.channel(channelName));

    final channel = _supabase
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: SupabaseConstants.posts,
          callback: (payload) {
            final postId = payload.newRecord[PostColumns.id] as String?;
            if (postId != null && !controller.isClosed) {
              controller.add(PostInsertedEvent(postId));
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: SupabaseConstants.posts,
          callback: (payload) {
            final postId = payload.newRecord[PostColumns.id] as String?;
            if (postId != null && !controller.isClosed) {
              controller.add(PostUpdatedEvent(postId));
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: SupabaseConstants.posts,
          callback: (payload) {
            final postId = payload.oldRecord[PostColumns.id] as String?;
            if (postId != null && !controller.isClosed) {
              controller.add(PostDeletedEvent(postId));
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConstants.likes,
          callback: (payload) {
            final record =
                payload.newRecord.isNotEmpty
                    ? payload.newRecord
                    : payload.oldRecord;
            final postId = record[LikeColumns.postId] as String?;
            if (postId != null && !controller.isClosed) {
              controller.add(LikeChangedEvent(postId, payload.eventType));
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConstants.postShares,
          callback: (payload) {
            final record =
                payload.newRecord.isNotEmpty
                    ? payload.newRecord
                    : payload.oldRecord;
            final postId = record[PostShareColumns.postId] as String?;
            if (postId != null && !controller.isClosed) {
              controller.add(ShareChangedEvent(postId, payload.eventType));
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConstants.userPresence,
          callback: (payload) {
            final record = payload.newRecord;
            final userId = record[GroupMemberColumns.userId] as String?;
            if (userId != null && !controller.isClosed) {
              final isOnline =
                  record[PresenceColumns.isOnline] as bool? ?? false;
              final updatedAtRaw = record[PresenceColumns.updatedAt] as String?;
              final updatedAt =
                  updatedAtRaw != null ? DateTime.tryParse(updatedAtRaw) : null;
              controller.add(PresenceChangedEvent(userId, isOnline, updatedAt));
            }
          },
        )
        .subscribe((status, [error]) {
          debugPrint('[FeedStream] status: $status');
        });

    controller.onCancel = () {
      _supabase.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
  }

  Future<void> addPost(PostRequestBody post) async {
    try {
      await supabaseServices.insertRow(
        table: SupabaseConstants.posts,
        values: post.toMap(),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await MediaCleanupService.instance.deleteWithMedia(
        table: SupabaseConstants.posts,
        id: postId,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleReaction({
    required String postId,
    required String userId,
    required String emoji,
    String? currentEmoji,
  }) async {
    try {
      await _supabase.from(SupabaseConstants.likes).delete().match({
        LikeColumns.postId: postId,
        LikeColumns.userId: userId,
      });

      if (currentEmoji == emoji) return;

      await _supabase.from(SupabaseConstants.likes).insert({
        LikeColumns.postId: postId,
        LikeColumns.userId: userId,
        LikeColumns.reaction: emoji,
      });
    } catch (e) {
      debugPrint("Error toggling reaction in DB: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> toggleSharePost({required String postId}) async {
    try {
      final response = await _supabase.rpc(
        SupabaseConstants.togglePostShareRpc,
        params: {'p_post_id': postId},
      );
      final rows = response as List;
      if (rows.isEmpty) {
        throw Exception('toggle_post_share returned no rows');
      }
      return rows.first as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error toggling share in DB: $e');
      rethrow;
    }
  }

  Future<void> toggleSavePost({
    required String postId,
    required String userId,
    required bool isCurrentlySaved,
  }) async {
    try {
      if (isCurrentlySaved) {
        await _supabase.from(SupabaseConstants.savedPosts).delete().match({
          SavedPostColumns.postId: postId,
          SavedPostColumns.userId: userId,
        });
      } else {
        await _supabase.from(SupabaseConstants.savedPosts).insert({
          SavedPostColumns.postId: postId,
          SavedPostColumns.userId: userId,
        });
      }
    } catch (e) {
      debugPrint('Error toggling saved post in DB: $e');
      rethrow;
    }
  }

  Future<List<PostModel>> fetchSavedPosts(String userId) async {
    if (!(await _networkStatus.isConnected())) {
      throw Exception('no-internet');
    }
    try {
      final rows = await _supabase
          .from(SupabaseConstants.savedPosts)
          .select(
            '${SavedPostColumns.createdAt}, ${SupabaseConstants.posts} ($_postsQuery)',
          )
          .eq(SavedPostColumns.userId, userId)
          .order(SavedPostColumns.createdAt, ascending: false);

      final List<Map<String, dynamic>> rawPostsData = [];
      for (final row in rows as List) {
        final postData = row[SupabaseConstants.posts] as Map<String, dynamic>?;
        if (postData != null) {
          rawPostsData.add(postData);
        }
      }

      final savedPosts = await _resolveSharedPostsAndHydrate(rawPostsData);
      return savedPosts;
    } catch (e) {
      debugPrint('fetchSavedPosts error: $e');
      rethrow;
    }
  }
}
