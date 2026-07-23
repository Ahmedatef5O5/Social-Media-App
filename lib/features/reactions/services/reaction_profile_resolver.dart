import '../../single_chats/models/chat_user_model.dart';
import '../../reactions/model/reaction_entry.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/utilities/supabase_constants.dart';

abstract class ReactionProfileResolver {
  Future<Map<String, ReactionEntry>> resolve(List<String> userIds);
}

class SingleChatReactionProfileResolver implements ReactionProfileResolver {
  final String currentUserId;
  final String currentUserName;
  final String? currentUserImageUrl;
  final ChatUserModel receiver;

  SingleChatReactionProfileResolver({
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserImageUrl,
    required this.receiver,
  });

  @override
  Future<Map<String, ReactionEntry>> resolve(List<String> userIds) async {
    final Map<String, ReactionEntry> result = {};
    final missingIds = <String>[];
    for (final id in userIds) {
      if (id == receiver.id) {
        result[id] = ReactionEntry(
          userId: id,
          userName: receiver.name,
          userImageUrl: receiver.imageUrl,
          lastSeen: receiver.lastSeen,
          emoji: '',
        );
      } else if (id == currentUserId && currentUserImageUrl != null) {
        result[id] = ReactionEntry(
          userId: id,
          userName: currentUserName,
          userImageUrl: currentUserImageUrl,
          lastSeen: null,
          emoji: '',
        );
      } else {
        missingIds.add(id);
      }
    }
    if (missingIds.isNotEmpty) {
      final response = await SupabaseProvider.client
          .from(SupabaseConstants.users)
          .select(
            '${UserColumns.id}, ${UserColumns.name}, '
            '${UserColumns.imageUrl}, ${UserColumns.lastSeen}',
          )
          .inFilter(UserColumns.id, missingIds);

      for (final row in List<Map<String, dynamic>>.from(response)) {
        final id = row[UserColumns.id] as String;
        final lastSeenStr = row[UserColumns.lastSeen] as String?;
        result[id] = ReactionEntry(
          userId: id,
          userName:
              row[UserColumns.name] as String? ??
              (id == currentUserId ? currentUserName : 'Unknown User'),
          userImageUrl: row[UserColumns.imageUrl] as String?,
          lastSeen: lastSeenStr != null ? DateTime.tryParse(lastSeenStr) : null,
          emoji: '',
        );
      }
    }
    return result;
  }
}

class GroupChatReactionProfileResolver implements ReactionProfileResolver {
  final Map<String, ReactionEntry> _cache = {};

  @override
  Future<Map<String, ReactionEntry>> resolve(List<String> userIds) async {
    final missing = userIds.where((id) => !_cache.containsKey(id)).toList();

    if (missing.isNotEmpty) {
      final response = await SupabaseProvider.client
          .from(SupabaseConstants.users)
          .select(
            '${UserColumns.id}, ${UserColumns.name}, '
            '${UserColumns.imageUrl}, ${UserColumns.lastSeen}',
          )
          .inFilter(UserColumns.id, missing);

      for (final row in List<Map<String, dynamic>>.from(response)) {
        final id = row[UserColumns.id] as String;
        final lastSeenStr = row[UserColumns.lastSeen] as String?;
        _cache[id] = ReactionEntry(
          userId: id,
          userName: row[UserColumns.name] as String? ?? 'Unknown User',
          userImageUrl: row[UserColumns.imageUrl] as String?,
          lastSeen: lastSeenStr != null ? DateTime.tryParse(lastSeenStr) : null,
          emoji: '',
        );
      }
    }

    return {
      for (final id in userIds)
        if (_cache.containsKey(id)) id: _cache[id]!,
    };
  }
}
