import 'dart:io';
import 'package:flutter/material.dart';
import 'package:social_media_app/core/services/supabase_database_services.dart';
import 'package:social_media_app/core/utilities/supabase_constants.dart';
import 'package:social_media_app/features/auth/data/models/user_data.dart';
import 'package:social_media_app/features/home/models/post_model.dart';
import 'package:social_media_app/features/home/models/post_request_body.dart';
import 'package:social_media_app/features/home/models/story_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeServices {
  final supabaseServices = SupabaseDatabaseServices.instance;
  final _supabase = Supabase.instance.client;

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

  Future<List<PostModel>> fetchPosts() async {
    try {
      return await supabaseServices.fetchRows(
        table: SupabaseConstants.posts,
        filter:
            (query) => query
                .select(''' 
        *,
         ${SupabaseConstants.users}
        (${UserColumns.name}, 
        ${UserColumns.imageUrl}
        ),
        ${SupabaseConstants.comments}(
          *,
          ${SupabaseConstants.users}(
             ${UserColumns.name}, 
             ${UserColumns.imageUrl}
          )
        ),
          ${SupabaseConstants.likes}(
            ${LikeColumns.userId},
            ${SupabaseConstants.users} (
              ${UserColumns.imageUrl}
            )
        )  
        ''')
                .order(PostColumns.createdAt, ascending: false),
        builder:
            (Map<String, dynamic> data, String id) => PostModel.fromMap(data),
        primaryKey: PostColumns.id,
      );
    } catch (e) {
      rethrow;
    }
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

  Future<String?> uploadFile(
    File file,
    String bucket,
    String folderName,
  ) async {
    try {
      final extension = file.path.split('.').last;

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
      final path = '$folderName/$fileName';
      //
      await Supabase.instance.client.storage.from(bucket).upload(path, file);
      //
      final String publicUrl = Supabase.instance.client.storage
          .from(bucket)
          .getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading file: $e');
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

  Future<void> addComment({
    required String postId,
    required String authorId,
    required String commentText,
  }) async {
    try {
      await supabaseServices.insertRow(
        table: SupabaseConstants.comments,
        values: {
          CommentColumns.postId: postId,
          CommentColumns.authorId: authorId,
          CommentColumns.text: commentText,
          CommentColumns.createdAt: DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      rethrow;
    }
  }
}
