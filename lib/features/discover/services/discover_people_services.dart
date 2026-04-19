import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:social_media_app/core/utilities/supabase_constants.dart';
import 'package:social_media_app/features/auth/data/models/user_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DiscoverPeopleServices {
  final _supabase = Supabase.instance.client;
  Future<bool> isConnected() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
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
