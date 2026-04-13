import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:social_media_app/core/services/supabase_database_services.dart';
import 'package:social_media_app/core/utilities/supabase_constants.dart';
import 'package:social_media_app/features/auth/data/models/user_data.dart';
import 'package:social_media_app/features/home/models/post_model.dart';
import 'package:social_media_app/features/home/models/post_request_body.dart';
import 'package:social_media_app/features/home/models/story_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart' as dio_pkg;
import '../../../core/secrets/app_secrets.dart';
import '../helper/comment_tree_builder.dart';
import '../models/comment_model.dart';

class HomeServices {
  final supabaseServices = SupabaseDatabaseServices.instance;
  final _supabase = Supabase.instance.client;

  Future<bool> isConnected() async {
    return await InternetConnection().hasInternetAccess;
  }

  Future<String> uploadStoryFile(File file, String userId) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final path = '$userId/$fileName';
    await _supabase.storage.from(SupabaseConstants.stories).upload(path, file);
    return _supabase.storage.from(SupabaseConstants.stories).getPublicUrl(path);
  }

  Future<void> createStory(StoryModel story) async {
    await _supabase.from(SupabaseConstants.stories).insert(story.toMap());
  }

  Future<void> deleteStory(String storyId) async {
    try {
      await _supabase
          .from(SupabaseConstants.stories)
          .delete()
          .eq(StoryColumns.id, storyId);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<StoryModel>> fetchStories() async {
    try {
      return await supabaseServices.fetchRows(
        table: SupabaseConstants.stories,
        filter:
            (query) => query
                .select('''*,${SupabaseConstants.users}(${UserColumns.name}, 
        ${UserColumns.imageUrl})}
        )''')
                .order(StoryColumns.createdAt, ascending: false),
        builder: (data, id) => StoryModel.fromMap(data),
        primaryKey: StoryColumns.id,
      );
    } catch (e) {
      rethrow;
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

  Future<UserData> fetchCurrentUser(String userId) async {
    try {
      final data =
          await Supabase.instance.client
              .from(SupabaseConstants.users)
              .select()
              .eq(UserColumns.id, userId)
              .maybeSingle();
      if (data == null) throw 'User not found';
      return UserData.fromMap(data);
    } catch (e) {
      debugPrint("Error in fetchCurrentUser: $e");
      rethrow;
    }
  }

  dio_pkg.CancelToken? _uploadCancelToken;
  Future<String?> uploadFile(
    File file,
    String bucket,
    String folderName, {
    void Function(double)? onProgress,
  }) async {
    try {
      if (!await file.exists()) {
        throw Exception('file_not_found');
      }

      _uploadCancelToken = dio_pkg.CancelToken();

      final ext = file.path.split('.').last.toLowerCase();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
      final uploadPath = '$folderName/$fileName';
      String contentType = _determineContentType(ext);

      final fileLength = await file.length();

      final accessToken =
          _supabase.auth.currentSession?.accessToken ??
          AppSecrets.supabaseAnonKey;

      final dioClient = dio_pkg.Dio();

      await dioClient.put(
        '${AppSecrets.supabaseUrl}/storage/v1/object/$bucket/$uploadPath',
        data: file.openRead(),
        cancelToken: _uploadCancelToken,
        options: dio_pkg.Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': contentType,
            'x-upsert': 'false',
            'Content-Length': fileLength.toString(),
          },
        ),
        onSendProgress: (sent, total) {
          final actualTotal = total > 0 ? total : fileLength;
          final progress = (sent / actualTotal).clamp(0.0, 1.0);
          onProgress?.call(progress);
        },
      );

      return _supabase.storage.from(bucket).getPublicUrl(uploadPath);
    } catch (e) {
      if (e is dio_pkg.DioException &&
          e.type == dio_pkg.DioExceptionType.cancel) {
        debugPrint('Upload Canceled by User');
        throw Exception('canceled');
      }
      debugPrint('Error uploading file in HomeServices: $e');
      rethrow;
    }
  }

  void cancelCurrentUpload() {
    if (_uploadCancelToken != null && !_uploadCancelToken!.isCancelled) {
      _uploadCancelToken?.cancel("Upload Canceled by User");
    }
  }

  String _determineContentType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
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

  Future<String> addComment({
    required String postId,
    required String authorId,
    required String commentText,
    String? parentCommentId,
  }) async {
    try {
      final response =
          await _supabase
              .from(SupabaseConstants.comments)
              .insert({
                CommentColumns.postId: postId,
                CommentColumns.authorId: authorId,
                CommentColumns.text: commentText,
                if (parentCommentId != null)
                  CommentColumns.parentCommentId: parentCommentId,
              })
              .select(CommentColumns.id)
              .single();

      return response[CommentColumns.id] as String;
    } catch (e) {
      debugPrint("DB Insert Error: $e");
      rethrow;
    }
  }

  Future<void> toggleCommentReaction({
    required String commentId,
    required String userId,
    required String emoji,
  }) async {
    try {
      final existing =
          await _supabase.from('comment_reactions').select().match({
            'comment_id': commentId,
            'user_id': userId,
          }).maybeSingle();

      if (existing != null) {
        if (existing['emoji'] == emoji) {
          await _supabase.from('comment_reactions').delete().match({
            'comment_id': commentId,
            'user_id': userId,
          });
        } else {
          await _supabase
              .from('comment_reactions')
              .update({'emoji': emoji})
              .match({'comment_id': commentId, 'user_id': userId});
        }
      } else {
        await _supabase.from('comment_reactions').insert({
          'comment_id': commentId,
          'user_id': userId,
          'emoji': emoji,
        });
      }
    } catch (e) {
      debugPrint("Error toggling comment reaction: $e");
      rethrow;
    }
  }
}
