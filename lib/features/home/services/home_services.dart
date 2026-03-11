import 'dart:io';

import 'package:flutter/material.dart';
import 'package:social_media_app/core/services/supabase_database_services.dart';
import 'package:social_media_app/core/utilities/app_tables_names.dart';
import 'package:social_media_app/features/auth/data/models/user_data.dart';
import 'package:social_media_app/features/home/models/post_model.dart';
import 'package:social_media_app/features/home/models/post_request_body.dart';
import 'package:social_media_app/features/home/models/story_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeServices {
  final supabaseServices = SupabaseDatabaseServices.instance;

  Future<List<StoryModel>> fetchStories() async {
    try {
      return await supabaseServices.fetchRows(
        table: AppTablesNames.stories,
        filter:
            (query) =>
                query.select('''*,${AppTablesNames.users}(${UserColumns.name}, 
        ${UserColumns.imageUrl})}
        )'''),
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
        table: AppTablesNames.posts,
        filter:
            (query) => query
                .select(''' 
        *,
         ${AppTablesNames.users}
        (${UserColumns.name}, 
        ${UserColumns.imageUrl}
        ),
        ${AppTablesNames.comments}(
          *,
          ${AppTablesNames.users}(
             ${UserColumns.name}, 
             ${UserColumns.imageUrl}
          )
        )
        }
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
        table: AppTablesNames.posts,
        values: post.toMap(),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<UserData> fetchCurrentUser(String userId) async {
    try {
      final data =
          await Supabase.instance.client
              .from(AppTablesNames.users)
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

  Future<void> likePost(String postId, List<String> updateLikes) async {
    try {
      await supabaseServices.updateRow(
        table: AppTablesNames.posts,
        column: 'id',
        value: postId,
        values: {PostColumns.likes: updateLikes},
      );
    } catch (e) {
      debugPrint("Error updating likes in DB: $e");
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
        table: AppTablesNames.comments,
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
