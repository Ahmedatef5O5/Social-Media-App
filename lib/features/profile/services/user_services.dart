import 'package:flutter/material.dart';
import 'package:social_media_app/core/utilities/supabase_constants.dart';
import 'package:social_media_app/features/auth/data/models/user_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/network_status_service.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../models/profile_overview_model.dart';

class UserService {
  final _supabase = SupabaseProvider.client;
  final NetworkStatusService _networkStatus;

  UserService({NetworkStatusService? networkStatus})
    : _networkStatus = networkStatus ?? NetworkStatusService.instance;

  Future<UserData> fetchCurrentUser(String userId) async {
    if (!(await _networkStatus.isConnected())) {
      throw Exception('no-internet');
    }
    try {
      final data =
          await _supabase
              .from(SupabaseConstants.users)
              .select()
              .eq(UserColumns.id, userId)
              .maybeSingle();

      if (data == null) throw 'User not found';

      return UserData.fromMap(data);
    } catch (e) {
      debugPrint('Error fetching current user: $e');
      rethrow;
    }
  }

  Future<int> getUserPostsCount(String userId) async {
    try {
      final count = await _supabase
          .from(SupabaseConstants.posts)
          .count(CountOption.exact)
          .eq(PostColumns.authorId, userId);

      return count;
    } catch (e) {
      debugPrint('getUserPostsCount error: $e');
      return 0;
    }
  }

  Future<ProfileOverviewModel> getProfileOverview(String viewedUserId) async {
    final data = await _supabase.rpc(
      SupabaseConstants.getProfileOverviewRpc,
      params: {
        'p_viewed_user_id': viewedUserId,
        'p_current_user_id': SupabaseProvider.id,
      },
    );
    final row = (data as List).first as Map<String, dynamic>;
    return ProfileOverviewModel.fromMap(row);
  }
}
