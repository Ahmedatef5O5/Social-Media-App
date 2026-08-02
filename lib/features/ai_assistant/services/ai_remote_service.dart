import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:social_media_app/core/supabase/supabase_provider.dart';

class AiRemoteService {
  Future<Map<String, dynamic>> invoke({
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final response = await SupabaseProvider.client.functions.invoke(
        'ai-gateway',
        body: {'action': action, 'payload': payload},
      );

      final data = response.data;
      if (data is Map<String, dynamic>) return data;

      return {'success': false, 'reason': 'error'};
    } on FunctionException catch (e) {
      final details = e.details;
      if (details is Map<String, dynamic>) return details;

      if (e.status == 429) {
        return {'success': false, 'reason': 'user_quota_exceeded'};
      }
      if (e.status == 401) {
        return {'success': false, 'reason': 'unauthenticated'};
      }
      return {'success': false, 'reason': 'error'};
    } catch (_) {
      return {'success': false, 'reason': 'error'};
    }
  }
}
