import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:social_media_app/core/services/network_status_service.dart';
import 'package:social_media_app/core/supabase/supabase_provider.dart';
import 'package:social_media_app/core/utilities/supabase_constants.dart';
import 'package:social_media_app/features/social_graph/models/discover_person_model.dart';

class DiscoverPeopleServices {
  final NetworkStatusService _networkStatus;
  DiscoverPeopleServices({NetworkStatusService? networkStatus})
    : _networkStatus = networkStatus ?? NetworkStatusService.instance;

  Future<List<DiscoverPersonModel>> getAllUsers({
    int page = 0,
    int pageSize = 15,
  }) async {
    if (!(await _networkStatus.isConnected())) {
      throw Exception('no-internet');
    }

    try {
      final data = await SupabaseProvider.client.rpc(
        SupabaseConstants.getDiscoverPeopleRpc,
        params: {
          'p_current_user_id': SupabaseProvider.id,
          'p_limit': pageSize,
          'p_offset': page * pageSize,
        },
      );

      return (data as List)
          .cast<Map<String, dynamic>>()
          .map(DiscoverPersonModel.fromMap)
          .toList();
    } catch (e) {
      debugPrint('Fetching Users Error: $e');
      rethrow;
    }
  }
}
