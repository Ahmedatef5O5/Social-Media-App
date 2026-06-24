import 'package:flutter/material.dart';
import 'package:social_media_app/core/utilities/supabase_constants.dart';
import 'package:social_media_app/features/auth/data/models/user_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final _supabase = Supabase.instance.client;

  Future<UserData> fetchCurrentUser(String userId) async {
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
}
