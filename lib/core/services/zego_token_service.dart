import 'package:social_media_app/core/supabase/supabase_provider.dart';

class ZegoTokenService {
  ZegoTokenService._();
  static final ZegoTokenService instance = ZegoTokenService._();

  Future<String> generateToken({
    required String userId,
    int effectiveTimeInSeconds = 3600,
  }) async {
    try {
      final response = await SupabaseProvider.client.functions.invoke(
        'generate-zego-token',
        body: {
          'userId': userId,
          'effectiveTimeInSeconds': effectiveTimeInSeconds,
        },
      );

      if (response.data == null || response.data['token'] == null) {
        throw Exception('Failed to generate Zego token: empty response');
      }

      return response.data['token'] as String;
    } catch (e) {
      throw Exception('ZegoTokenService.generateToken failed: $e');
    }
  }
}
