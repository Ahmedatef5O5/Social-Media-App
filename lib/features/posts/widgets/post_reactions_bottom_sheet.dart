import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../../reactions/model/reaction_entry.dart';
import '../../reactions/widgets/reactions_bottom_sheet.dart';
import '../model/post_reaction_model.dart';

class PostReactionsBottomSheet extends StatelessWidget {
  final String postId;
  const PostReactionsBottomSheet({super.key, required this.postId});

  Future<List<ReactionEntry>> _fetch() async {
    final response = await Supabase.instance.client
        .from(SupabaseConstants.likes)
        .select('''
          ${LikeColumns.reaction},
          ${LikeColumns.createdAt},
          ${SupabaseConstants.users} (
            ${UserColumns.id},
            ${UserColumns.name},
            ${UserColumns.imageUrl},
            ${UserColumns.lastSeen}
          )
        ''')
        .eq(LikeColumns.postId, postId)
        .order(LikeColumns.createdAt, ascending: false);

    return List<Map<String, dynamic>>.from(response).map((r) {
      final user = r[SupabaseConstants.users] as Map<String, dynamic>?;
      final lastSeenStr = user?[UserColumns.lastSeen] as String?;
      return ReactionEntry(
        userId: user?[UserColumns.id] ?? '',
        userName: user?[UserColumns.name] ?? 'Unknown User',
        userImageUrl: user?[UserColumns.imageUrl],
        lastSeen: lastSeenStr != null ? DateTime.tryParse(lastSeenStr) : null,
        emoji: reactionGlyph(r[LikeColumns.reaction] as String? ?? 'like'),
        createdAt: r[LikeColumns.createdAt] as String?,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) =>
      ReactionsBottomSheet(fetchReactions: _fetch);
}
