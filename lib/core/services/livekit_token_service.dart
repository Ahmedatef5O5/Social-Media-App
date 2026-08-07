import 'package:social_media_app/core/supabase/supabase_provider.dart';

class LiveKitConnectionInfo {
  final String token;
  final String url;

  const LiveKitConnectionInfo({required this.token, required this.url});
}

class LiveKitTokenService {
  LiveKitTokenService._();
  static final LiveKitTokenService instance = LiveKitTokenService._();

  Future<LiveKitConnectionInfo> generateToken({
    required String roomName,
    required String participantName,
    int effectiveTimeInSeconds = 3600,
  }) async {
    try {
      final response = await SupabaseProvider.client.functions.invoke(
        'generate-livekit-token',
        body: {
          'roomName': roomName,
          'participantName': participantName,
          'effectiveTimeInSeconds': effectiveTimeInSeconds,
        },
      );

      final data = response.data;
      if (data == null || data['token'] == null || data['url'] == null) {
        throw Exception('Failed to generate LiveKit token: empty response');
      }

      return LiveKitConnectionInfo(
        token: data['token'] as String,
        url: data['url'] as String,
      );
    } catch (e) {
      throw Exception('LiveKitTokenService.generateToken failed: $e');
    }
  }
}
