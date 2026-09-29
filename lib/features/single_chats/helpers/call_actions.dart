import '../../../core/connectivity/services/connectivity_banner_controller.dart';
import '../../../core/services/current_user_name_resolver.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../profile/services/user_services.dart';
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

    final userService = UserService();
    final userInfo = await userService.fetchUserNameAndAvatar(currentUser.id);

    // Never 'Unknown' / a placeholder if the users row is slow or empty.
    final callerName = await CurrentUserNameResolver.resolve(
      userService: userService,
    );
    final callerAvatar = userInfo.avatarUrl ?? '';

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
