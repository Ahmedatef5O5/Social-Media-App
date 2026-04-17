import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utilities/supabase_constants.dart';

class CommentsService {
  final _supabase = Supabase.instance.client;

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

  Stream<List<Map<String, dynamic>>> getCommentsStream() {
    return _supabase
        .from(SupabaseConstants.comments)
        .stream(primaryKey: [CommentColumns.id]);
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
