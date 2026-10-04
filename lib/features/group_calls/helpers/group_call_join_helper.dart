import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/active_call/cubits/active_call_session_cubit.dart';
import '../../../core/services/current_user_name_resolver.dart';
import '../../../core/services/incoming_call_navigation_guard.dart';
import '../../../core/services/permissions/app_permissions_service.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/toast/app_toast.dart';
import '../models/group_call_model.dart';
import '../services/group_call_signaling_service.dart';
import '../views/livekit_group_call_view.dart';

class GroupCallJoinHelper {
  const GroupCallJoinHelper._();

  static const String busyMessage =
      'Please end your current call before joining another call.';

  static Future<bool> join(BuildContext context, GroupCallModel call) async {
    final navigator = Navigator.of(context);
    final signaling = context.read<GroupCallSignalingService>();
    final sessionCubit = context.read<ActiveCallSessionCubit>();

    final user = SupabaseProvider.user;
    if (user == null) return false;

    final alreadyInThisCall = sessionCubit.state?.callId == call.callId;

    if (!alreadyInThisCall &&
        IncomingCallNavigationGuard.isUserBusyWithAnotherCall(call.callId)) {
      AppToast.warning(busyMessage);
      return false;
    }

    if (!alreadyInThisCall) {
      final granted = await AppPermissionsService.instance
          .ensureCallPermissions(
            isVideo: call.type == GroupCallType.video,
            context: context,
          );
      if (!granted || !context.mounted) return false;
    }

    final userName = await CurrentUserNameResolver.resolve();

    if (!alreadyInThisCall &&
        IncomingCallNavigationGuard.isUserBusyWithAnotherCall(call.callId)) {
      AppToast.warning(busyMessage);
      return false;
    }

    var callToJoin = call;
    if (!alreadyInThisCall) {
      callToJoin = await signaling.acceptCall(call.callId);
    }

    if (!context.mounted) return false;
    await navigator.push(
      MaterialPageRoute(
        builder:
            (_) => LiveKitGroupCallView(
              call: callToJoin,
              currentUserId: user.id,
              currentUserName: userName,
              isJoining: true,
            ),
      ),
    );
    return true;
  }
}
