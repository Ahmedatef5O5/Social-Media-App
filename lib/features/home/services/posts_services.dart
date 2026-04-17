import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_database_services.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../../comments/helper/comment_tree_builder.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';
import '../models/post_request_body.dart';

class PostsServices {
  final supabaseServices = SupabaseDatabaseServices.instance;
  final _supabase = Supabase.instance.client;

  Future<bool> isConnected() async {
    return await InternetConnection().hasInternetAccess;
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
      return await supabaseServices.fetchRows(
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
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getPostsStream() {
    return _supabase
        .from(SupabaseConstants.posts)
        .stream(primaryKey: [PostColumns.id]);
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
