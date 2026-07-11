import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../model/comment_type.dart';

class CommentsService {
  final _supabase = Supabase.instance.client;

  Future<String> addComment({
    required String postId,
    required String authorId,
    required String? commentText,
    String? parentCommentId,
    CommentType commentType = CommentType.text,
    String? imageUrl,
    String? videoUrl,
    String? voiceUrl,
    String? fileUrl,
    String? fileName,
    int? fileSizeBytes,
    int? durationSeconds,
    String? imagePublicId,
    String? videoPublicId,
    String? voicePublicId,
    String? filePublicId,
    List<Map<String, dynamic>> mentions = const [],
  }) async {
    try {
      final response = await _supabase.rpc(
        SupabaseConstants.addCommentWithMentionsRpc,
        params: {
          'p_post_id': postId,
          'p_author_id': authorId,
          'p_text': commentText,
          'p_parent_comment_id': parentCommentId,
          'p_comment_type': commentType.value,
          'p_image_url': imageUrl,
          'p_video_url': videoUrl,
          'p_voice_url': voiceUrl,
          'p_file_url': fileUrl,
          'p_file_name': fileName,
          'p_file_size_bytes': fileSizeBytes,
          'p_duration_seconds': durationSeconds,
          'p_image_public_id': imagePublicId,
          'p_video_public_id': videoPublicId,
          'p_voice_public_id': voicePublicId,
          'p_file_public_id': filePublicId,
          'p_mentions': mentions,
        },
      );

      return response as String;
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

  Future<List<Map<String, dynamic>>> getCommentReactionsDetails(
    String commentId,
  ) async {
    try {
      final response = await _supabase
          .from('comment_reactions')
          .select(
            'emoji, created_at, users!fk_comment_reactions_user (id, name, image_url)',
          )
          .eq('comment_id', commentId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error fetching comment reactions details: $e");
      return [];
    }
  }
}
