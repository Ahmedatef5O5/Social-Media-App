import 'package:flutter/material.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../helpers/comment_tree_builder.dart';
import '../../../core/mentions/models/mention_ref.dart';
import '../models/comment_model.dart';
import '../models/comment_sort_option.dart';
import '../models/comment_type.dart';

class CommentsService {
  final _supabase = SupabaseProvider.client;
  static const String _selectWithRelations =
      '*, users($_authorFields), comment_reactions(*), comment_mentions(${CommentMentionColumns.mentionedUserId},${CommentMentionColumns.startIndex},${CommentMentionColumns.endIndex})';
  static const String _authorFields =
      '${UserColumns.name},${UserColumns.imageUrl}';

  Future<List<CommentModel>> getComments({
    required String postId,
    required CommentSortOption sort,
  }) async {
    try {
      var topLevelQuery = _supabase
          .from(SupabaseConstants.comments)
          .select(_selectWithRelations)
          .eq(CommentColumns.postId, postId)
          .filter(CommentColumns.parentCommentId, 'is', null);

      final List<Map<String, dynamic>> topLevelRows;
      switch (sort) {
        case CommentSortOption.newest:
          topLevelRows = await topLevelQuery.order(
            CommentColumns.createdAt,
            ascending: false,
          );
          break;
        case CommentSortOption.oldest:
          topLevelRows = await topLevelQuery.order(
            CommentColumns.createdAt,
            ascending: true,
          );
          break;
        case CommentSortOption.mostRelevant:
          topLevelRows = await topLevelQuery
              .order(CommentColumns.relevanceScore, ascending: false)
              .order(CommentColumns.createdAt, ascending: false);
          break;
      }

      final replyRows = await _supabase
          .from(SupabaseConstants.comments)
          .select(_selectWithRelations)
          .eq(CommentColumns.postId, postId)
          .not(CommentColumns.parentCommentId, 'is', null)
          .order(CommentColumns.createdAt, ascending: true);

      final combined = [...topLevelRows, ...replyRows];
      final flatComments =
          combined.map((row) => CommentModel.fromMap(row)).toList();

      return CommentTreeBuilder.build(flatComments);
    } catch (e) {
      debugPrint('❌ Error fetching comments: $e');
      rethrow;
    }
  }

  Future<String> addComment({
    required String postId,
    required String authorId,
    String? commentText,
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
    List<MentionRef> mentions = const [],
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
          'p_mentions': mentions.map((m) => m.toRpcMap()).toList(),
        },
      );

      return response as String;
    } catch (e) {
      debugPrint("DB Insert Error: $e");
      rethrow;
    }
  }

  Future<void> editComment({
    required String commentId,
    required String newText,
  }) async {
    await _supabase
        .from(SupabaseConstants.comments)
        .update({
          CommentColumns.text: newText,
          CommentColumns.isEdited: true,
          CommentColumns.updatedAt: DateTime.now().toIso8601String(),
        })
        .eq(CommentColumns.id, commentId);
  }

  Future<void> deleteComment({required String commentId}) async {
    await _supabase
        .from(SupabaseConstants.comments)
        .delete()
        .eq(CommentColumns.id, commentId);
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
