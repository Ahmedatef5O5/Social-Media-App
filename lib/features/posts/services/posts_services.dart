import 'dart:async';
import 'package:flutter/material.dart';
import 'package:social_media_app/features/posts/model/feed_event.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/media_cleanup_service.dart';
import '../../../core/services/network_status_service.dart';
import '../../../core/services/presence_service.dart';
import '../../../core/services/supabase_database_services.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../../comments/helper/comment_tree_builder.dart';
import '../../comments/model/comment_model.dart';
import '../model/post_model.dart';
import '../model/post_request_body.dart';

class PostsServices {
  final supabaseServices = SupabaseDatabaseServices.instance;
  final _supabase = Supabase.instance.client;
  final NetworkStatusService _networkStatus;

  PostsServices({NetworkStatusService? networkStatus})
    : _networkStatus = networkStatus ?? NetworkStatusService.instance;

  static const String _postsQuery = ''' 
  *,
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

  Future<PostModel?> fetchPostById(String postId) async {
    try {
      final rows = await _supabase
          .from(SupabaseConstants.posts)
          .select(_postsQuery)
          .eq(PostColumns.id, postId)
          .limit(1);
      if (rows.isEmpty) return null;

      final data = rows.first as Map<String, dynamic>;
      final post = PostModel.fromMap(data);

      final flatComments =
          (data['comments'] as List? ?? [])
              .map((e) => CommentModel.fromMap(e))
              .toList();
      final tree = CommentTreeBuilder.build(flatComments);
      final postWithComments = post.copyWith(comments: tree);

      final presenceRows = await _supabase
          .from(SupabaseConstants.userPresence)
          .select('user_id, is_online, updated_at')
          .eq(GroupMemberColumns.userId, postWithComments.authorId)
          .limit(1);

      if (presenceRows.isEmpty) return postWithComments;

      final row = presenceRows.first as Map<String, dynamic>;
      final isOnline = PresenceService.isConsideredOnline(
        isOnline: row[PresenceColumns.isOnline] as bool? ?? false,
        updatedAt:
            row[PresenceColumns.updatedAt] != null
                ? DateTime.parse(row[PresenceColumns.updatedAt].toString())
                : null,
      );

      return postWithComments.copyWith(isOnline: isOnline);
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
      final posts = await supabaseServices.fetchRows(
        table: SupabaseConstants.posts,
        filter:
            (query) => query
                .select(_postsQuery)
                .order(PostColumns.createdAt, ascending: false),
        builder: (Map<String, dynamic> data, String id) {
          final post = PostModel.fromMap(data);
          final flatComments =
              (data['comments'] as List? ?? [])
                  .map((e) => CommentModel.fromMap(e))
                  .toList();
          final tree = CommentTreeBuilder.build(flatComments);
          return post.copyWith(comments: tree);
        },
        primaryKey: PostColumns.id,
      );

      if (posts.isEmpty) return posts;

      final authorIds = posts.map((p) => p.authorId).toSet().toList();
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

      return posts
          .map((p) => p.copyWith(isOnline: onlineSet.contains(p.authorId)))
          .toList();
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
}
