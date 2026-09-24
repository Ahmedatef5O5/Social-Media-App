import '../../../core/services/supabase_database_services.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../models/reel_model.dart';
import '../utils/reels_interleaver.dart';

class ReelsServices {
  final supabaseServices = SupabaseDatabaseServices.instance;
  final _supabase = SupabaseProvider.client;

  static const int _poolMultiplier = 4;
  static const int _maxPoolSize = 800;

  Future<List<ReelModel>> fetchReelsBatch({
    required int limit,
    Set<String> excludeIds = const {},
    List<String>? preferredCategories,
    List<String>? categoryFilter,
  }) async {
    final poolSize = (limit * _poolMultiplier).clamp(limit, _maxPoolSize);

    final response = await _supabase.rpc(
      SupabaseConstants.getBalancedReelsFeedRpc,
      params: {
        'limit_per_request': poolSize,
        'exclude_video_ids': excludeIds.toList(),
        if (preferredCategories != null && preferredCategories.isNotEmpty)
          'preferred_categories': preferredCategories,
        if (categoryFilter != null && categoryFilter.isNotEmpty)
          'category_filter': categoryFilter,
      },
    );

    final pool =
        (response as List)
            .map((e) => ReelModel.fromMap(e as Map<String, dynamic>))
            .toList();

    final shuffled = ReelsInterleaver.shuffle(pool);
    return shuffled.take(limit).toList();
  }

  Future<List<ReelModel>> searchReels({
    required String query,
    int limit = 30,
    int offset = 0,
  }) async {
    final response = await _supabase.rpc(
      'search_reels',
      params: {'p_query': query, 'p_limit': limit, 'p_offset': offset},
    );
    return (response as List)
        .map((e) => ReelModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
