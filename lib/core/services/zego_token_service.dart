import 'package:supabase_flutter/supabase_flutter.dart';

class ZegoTokenService {
  ZegoTokenService._();
  static final ZegoTokenService instance = ZegoTokenService._();

  final _supabase = Supabase.instance.client;

  Future<String> generateToken({
    required String userId,
    int effectiveTimeInSeconds = 3600,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
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
