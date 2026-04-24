import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/presence_service.dart';
import '../../../core/services/supabase_database_services.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../../comments/helper/comment_tree_builder.dart';
import '../../comments/model/comment_model.dart';
import '../models/post_model.dart';
import '../models/post_request_body.dart';

class PostsServices {
  final supabaseServices = SupabaseDatabaseServices.instance;
  final _supabase = Supabase.instance.client;

  Future<bool> isConnected() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

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
  ${SupabaseConstants.users} (${UserColumns.imageUrl}))
''';

  Future<List<PostModel>> fetchPosts() async {
    if (!(await isConnected())) {
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
          .from('user_presence')
          .select('user_id, is_online, updated_at')
          .inFilter('user_id', authorIds);

      final onlineSet = <String>{
        for (final row in presenceRows as List)
          if (PresenceService.isConsideredOnline(
            isOnline: row['is_online'] as bool? ?? false,
            updatedAt:
                row['updated_at'] != null
                    ? DateTime.parse(row['updated_at'].toString())
                    : null,
          ))
            row['user_id'] as String,
      };

      return posts
          .map((p) => p.copyWith(isOnline: onlineSet.contains(p.authorId)))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<void> getPostsStream() {
    final controller = StreamController<void>.broadcast();

    void notify(dynamic _) {
      if (!controller.isClosed) controller.add(null);
    }

    const channelName = 'home_feed_watcher';
    _supabase.removeChannel(_supabase.channel(channelName));

    final channel = _supabase
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConstants.posts,
          callback: notify,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConstants.likes,
          callback: notify,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_presence',
          callback: notify,
        )
        .subscribe((status, [error]) {
          debugPrint('[PostsStream] channel status: $status');
        });

    Future.microtask(() => notify(null));

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
      await _supabase
          .from(SupabaseConstants.posts)
          .delete()
          .eq(PostColumns.id, postId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleLike({
    required String postId,
    required String userId,
    required bool isLiked,
  }) async {
    try {
      if (isLiked) {
        await _supabase.from(SupabaseConstants.likes).delete().match({
          LikeColumns.postId: postId,
          LikeColumns.userId: userId,
        });
      } else {
        await _supabase.from(SupabaseConstants.likes).insert({
          LikeColumns.postId: postId,
          LikeColumns.userId: userId,
        });
      }
    } catch (e) {
      debugPrint("Error toggling like in DB: $e");
      rethrow;
    }
  }
}
