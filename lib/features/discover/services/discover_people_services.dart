import 'package:flutter/cupertino.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:social_media_app/core/utilities/supabase_constants.dart';
import 'package:social_media_app/features/auth/data/models/user_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DiscoverPeopleServices {
  final _supabase = Supabase.instance.client;
  Future<bool> isConnected() async {
    return await InternetConnection().hasInternetAccess;
  }

  Future<List<UserData>> getAllUsers() async {
    if (!(await isConnected())) {
      throw Exception('no-internet');
    }

    final currUserId = _supabase.auth.currentUser!.id;
    try {
      final List<dynamic> data = await _supabase
          .from(SupabaseConstants.users)
          .select()
          .neq(UserColumns.id, currUserId);
      return data
          .map((user) => UserData.fromMap(user as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Fetching Users Error: $e');
      rethrow;
    }
  }
}
