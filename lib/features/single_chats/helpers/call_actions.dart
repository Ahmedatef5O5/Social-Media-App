import '../../../core/connectivity/services/connectivity_banner_controller.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../single_calls/models/call_model.dart';

class CallActions {
  static Future<CallModel?> buildCall({
    required CallType type,
    required String receiverId,
    required String receiverName,
    required String receiverAvatar,
  }) async {
    final isOffline = await ConnectivityBannerController.notifyIfOffline();
    if (isOffline) {
      return null;
    }

    final currentUser = SupabaseProvider.user;
    if (currentUser == null) return null;

    final userData =
        await SupabaseProvider.client
            .from('users')
            .select('name, image_url')
            .eq('id', currentUser.id)
            .maybeSingle();

    final callerName = (userData?['name'] as String?) ?? 'Unknown';
    final callerAvatar = (userData?['image_url'] as String?) ?? '';

    return CallModel(
      callId: 'room_${DateTime.now().millisecondsSinceEpoch}',
      callerId: currentUser.id,
      callerName: callerName,
      callerAvatar: callerAvatar,
      receiverId: receiverId,
      receiverName: receiverName,
      receiverAvatar: receiverAvatar,
      status: CallStatus.ringing,
      type: type,
    );
  }
}
