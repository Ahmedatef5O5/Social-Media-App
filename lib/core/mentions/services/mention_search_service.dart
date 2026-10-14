import 'package:flutter/foundation.dart';
import 'package:social_media_app/core/supabase/supabase_provider.dart';
import '../../utilities/supabase_constants.dart';
import '../models/mention_suggestion.dart';

class MentionSearchService {
  Future<List<MentionSuggestion>> search(
    String query, {
    int limit = 20,
    List<String>? restrictToUserIds,
  }) async {
    try {
      final currentUserId = SupabaseProvider.id;
      final trimmed = query.trim();

      if (restrictToUserIds != null && restrictToUserIds.isEmpty) {
        return []; // no members to suggest — short-circuit
      }

      var builder = SupabaseProvider.client
          .from(SupabaseConstants.users)
          .select(
            '${UserColumns.id}, ${UserColumns.name}, ${UserColumns.imageUrl}',
          );

      if (trimmed.isNotEmpty) {
        builder = builder.ilike(UserColumns.name, '%$trimmed%');
      }
      builder = builder
          .neq(UserColumns.id, currentUserId)
          .eq(UserColumns.isDeleted, false);

      if (restrictToUserIds != null) {
        builder = builder.inFilter(UserColumns.id, restrictToUserIds);
      }

      final rows = await builder.order(UserColumns.name).limit(limit);

      final List<MentionSuggestion> list = [];

      if (restrictToUserIds != null &&
          (trimmed.isEmpty ||
              'all'.toLowerCase().contains(trimmed.toLowerCase()) ||
              'الكل'.contains(trimmed))) {
        list.add(
          const MentionSuggestion(userId: 'all', name: 'all', imageUrl: null),
        );
      }

      list.addAll(
        (rows as List<dynamic>).map(
          (row) => MentionSuggestion(
            userId: row[UserColumns.id] as String,
            name: row[UserColumns.name] as String? ?? 'User',
            imageUrl: row[UserColumns.imageUrl] as String?,
          ),
        ),
      );

      return list;
    } catch (e) {
      debugPrint('❌ Mention search failed: $e');
      return [];
    }
  }
}
