import 'package:flutter/material.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../../reactions/models/reaction_entry.dart';
import '../../reactions/widgets/reactions_bottom_sheet.dart';
import '../services/comments_service.dart';

class CommentReactionsBottomSheet extends StatelessWidget {
  final String commentId;
  const CommentReactionsBottomSheet({super.key, required this.commentId});

  Future<List<ReactionEntry>> _fetch() async {
    final data = await CommentsService().getCommentReactionsDetails(commentId);
    return data.map((r) {
      final user = r['users'] as Map<String, dynamic>?;
      final lastSeenStr = user?[UserColumns.lastSeen] as String?;
      return ReactionEntry(
        userId: user?['id'] ?? '',
        userName: user?['name'] ?? 'Unknown User',
        userImageUrl: user?['image_url'],
        lastSeen: lastSeenStr != null ? DateTime.tryParse(lastSeenStr) : null,
        emoji: r['emoji'] as String? ?? '👍',
        createdAt: r['created_at'] as String?,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) =>
      ReactionsBottomSheet(fetchReactions: _fetch);
}
