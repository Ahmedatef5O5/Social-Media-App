import 'package:flutter/foundation.dart';
import 'package:social_media_app/core/supabase/supabase_provider.dart';
import '../../utilities/supabase_constants.dart';
import '../models/mention_suggestion.dart';

class MentionSearchService {
  Future<List<MentionSuggestion>> search(String query, {int limit = 8}) async {
    try {
      final currentUserId = SupabaseProvider.id;
      final trimmed = query.trim();

      var builder = SupabaseProvider.client
          .from(SupabaseConstants.users)
          .select(
            '${UserColumns.id}, ${UserColumns.name}, ${UserColumns.imageUrl}',
          );

      if (trimmed.isNotEmpty) {
        builder = builder.ilike(UserColumns.name, '%$trimmed%');
      }
      builder = builder.neq(UserColumns.id, currentUserId);

      final rows = await builder.order(UserColumns.name).limit(limit);

      return (rows as List<dynamic>)
          .map(
            (row) => MentionSuggestion(
              userId: row[UserColumns.id] as String,
              name: row[UserColumns.name] as String? ?? 'User',
              imageUrl: row[UserColumns.imageUrl] as String?,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('❌ Mention search failed: $e');
      return [];
    }
  }
}
