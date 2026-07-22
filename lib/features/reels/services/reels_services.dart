import 'dart:math';
import '../../../core/services/supabase_database_services.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../model/reel_model.dart';
import '../utils/reels_interleaver.dart';

class ReelsServices {
  final supabaseServices = SupabaseDatabaseServices.instance;
  final _supabase = SupabaseProvider.client;

  static const String _reelFields = '''
    *,
    ${SupabaseConstants.reelChannels} (
      ${ReelChannelColumns.id},
      ${ReelChannelColumns.channelName},
      ${ReelChannelColumns.channelAvatarUrl}
    )
  ''';

  static const int _poolMultiplier = 4;

  static const int _maxPoolSize = 400;

  Future<List<ReelModel>> fetchReelsBatch({
    required int limit,
    Set<String> excludeIds = const {},
    String? category, // TODO(category-filter): wire up once categories exist
  }) async {
    final poolSize = min(
      _maxPoolSize,
      (limit + excludeIds.length) * _poolMultiplier,
    );

    var query = _supabase
        .from(SupabaseConstants.reelsCache)
        .select(_reelFields)
        .order(ReelColumns.publishedAt, ascending: false)
        .limit(poolSize);

    final response = await query;
    final pool =
        (response as List)
            .map((e) => ReelModel.fromMap(e as Map<String, dynamic>))
            .where((reel) => !excludeIds.contains(reel.youtubeVideoId))
            .toList();

    final shuffled = ReelsInterleaver.shuffle(pool);
    return shuffled.take(limit).toList();
  }
}
