import 'package:social_media_app/core/infrastructure/service_health_coordinator.dart';
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
    final healthTimer = Stopwatch()..start();
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

      ServiceHealthCoordinator.instance.reportLiveKitToken(
        success: true,
        duration: healthTimer.elapsed,
      );
      return LiveKitConnectionInfo(
        token: data['token'] as String,
        url: data['url'] as String,
      );
    } catch (e) {
      ServiceHealthCoordinator.instance.reportLiveKitToken(
        success: false,
        duration: healthTimer.elapsed,
        error: e,
      );
      throw Exception('LiveKitTokenService.generateToken failed: $e');
    }
  }

  /// Service-health hook for call views: call it from the
  /// `RoomDisconnectedEvent` handler with `event.reason?.name`.
  /// User-initiated endings are ignored; anything else counts as a drop.
  void reportConnectionEnded(String? disconnectReasonName) {
    ServiceHealthCoordinator.instance.reportLiveKitConnectionEnded(
      disconnectReasonName,
    );
  }
}
