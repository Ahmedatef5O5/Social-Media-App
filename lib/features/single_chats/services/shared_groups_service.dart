import '../../../core/supabase/supabase_provider.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../models/shared_group_item.dart';

class SharedGroupsService {
  final _supabase = SupabaseProvider.client;

  Future<List<SharedGroupItem>> getMutualGroups({
    required String currentUserId,
    required String otherUserId,
  }) async {
    final rows = await _supabase.rpc(
      SupabaseConstants.getMutualGroupsRpc,
      params: {
        'p_current_user_id': currentUserId,
        'p_other_user_id': otherUserId,
      },
    );

    return (rows as List)
        .map((row) => SharedGroupItem.fromMap(row as Map<String, dynamic>))
        .toList();
  }
}
