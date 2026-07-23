import '../../../core/services/supabase_database_services.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../model/reel_model.dart';
import '../utils/reels_interleaver.dart';

class ReelsServices {
  final supabaseServices = SupabaseDatabaseServices.instance;
  final _supabase = SupabaseProvider.client;
  static const int _poolMultiplier = 4;
  static const int _maxPoolSize = 400;

  Future<List<ReelModel>> fetchReelsBatch({
    required int limit,
    Set<String> excludeIds = const {},
    String? category,
  }) async {
    final poolSize = (limit * _poolMultiplier).clamp(limit, _maxPoolSize);

    final response = await _supabase.rpc(
      SupabaseConstants.getBalancedReelsFeedRpc,
      params: {
        'limit_per_request': poolSize,
        'exclude_video_ids': excludeIds.toList(),
      },
    );

    final pool =
        (response as List)
            .map((e) => ReelModel.fromMap(e as Map<String, dynamic>))
            .toList();

    final shuffled = ReelsInterleaver.shuffle(pool);
    return shuffled.take(limit).toList();
  }
}
