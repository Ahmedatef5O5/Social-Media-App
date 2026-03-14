import 'package:flutter/cupertino.dart';
import 'package:social_media_app/core/utilities/app_tables_names.dart';
import 'package:social_media_app/features/auth/data/models/user_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DiscoverPeopleServices {
  final _supabase = Supabase.instance.client;

  Future<List<UserData>> getAllUsers() async {
    final currUserId = _supabase.auth.currentUser!.id;
    try {
      final List<dynamic> data = await _supabase
          .from(AppTablesNames.users)
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
