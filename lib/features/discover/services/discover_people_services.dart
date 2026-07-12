import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:social_media_app/core/services/network_status_service.dart';
import 'package:social_media_app/core/supabase/supabase_provider.dart';
import 'package:social_media_app/core/utilities/supabase_constants.dart';
import 'package:social_media_app/features/auth/data/models/user_data.dart';

class DiscoverPeopleServices {
  final NetworkStatusService _networkStatus;
  DiscoverPeopleServices({NetworkStatusService? networkStatus})
    : _networkStatus = networkStatus ?? NetworkStatusService.instance;

  Future<List<UserData>> getAllUsers({int page = 0, int pageSize = 15}) async {
    if (!(await _networkStatus.isConnected())) {
      throw Exception('no-internet');
    }

    final start = page * pageSize;
    final end = (page + 1) * pageSize - 1;

    final currUserId = SupabaseProvider.id;
    try {
      final List<dynamic> data = await SupabaseProvider.client
          .from(SupabaseConstants.users)
          .select()
          .neq(UserColumns.id, currUserId)
          .order(UserColumns.lastSeen, ascending: false)
          .range(start, end);
      return data
          .map((user) => UserData.fromMap(user as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Fetching Users Error: $e');
      rethrow;
    }
  }
}
