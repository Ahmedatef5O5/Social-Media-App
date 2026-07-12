import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utilities/supabase_constants.dart';
import '../models/mention_suggestion.dart';

class MentionSearchService {
  final _supabase = Supabase.instance.client;

  Future<List<MentionSuggestion>> search(String query, {int limit = 8}) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      final trimmed = query.trim();

      var builder = _supabase
          .from(SupabaseConstants.users)
          .select(
            '${UserColumns.id}, ${UserColumns.name}, ${UserColumns.imageUrl}',
          );

      if (trimmed.isNotEmpty) {
        builder = builder.ilike(UserColumns.name, '%$trimmed%');
      }
      if (currentUserId != null) {
        builder = builder.neq(UserColumns.id, currentUserId);
      }

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
