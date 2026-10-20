import '../../../core/connectivity/services/connectivity_banner_controller.dart';
import '../../../core/services/current_user_name_resolver.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/toast/app_toast.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../../profile/services/user_services.dart';
import '../../single_calls/models/call_model.dart';
import 'package:social_media_app/core/localization/app_l10n.dart';

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

    try {
      final row =
          await SupabaseProvider.client
              .from(SupabaseConstants.users)
              .select(UserColumns.isDeleted)
              .eq(UserColumns.id, receiverId)
              .maybeSingle();
      if (row != null && row[UserColumns.isDeleted] == true) {
        AppToast.error(AppL10n.current.thisAccountHasBeen3);
        return null;
      }
    } catch (_) {}

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
      startTime: DateTime.now().toUtc(),
    );
  }
}
