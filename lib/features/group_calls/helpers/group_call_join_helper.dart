import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/active_call/cubits/active_call_session_cubit.dart';
import '../../../core/services/current_user_name_resolver.dart';
import '../../../core/services/permissions/app_permissions_service.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../models/group_call_model.dart';
import '../services/group_call_signaling_service.dart';
import '../views/livekit_group_call_view.dart';

/// One implementation of "join a group call that is already running".

class GroupCallJoinHelper {
  const GroupCallJoinHelper._();

  static Future<void> join(BuildContext context, GroupCallModel call) async {
    final navigator = Navigator.of(context);
    final signaling = context.read<GroupCallSignalingService>();
    final sessionCubit = context.read<ActiveCallSessionCubit>();

    final user = SupabaseProvider.user;
    if (user == null) return;

    final alreadyInThisCall = sessionCubit.state?.callId == call.callId;

    if (!alreadyInThisCall) {
      final granted = await AppPermissionsService.instance
          .ensureCallPermissions(
            isVideo: call.type == GroupCallType.video,
            context: context,
          );
      if (!granted || !context.mounted) return;
    }

    final userName = await CurrentUserNameResolver.resolve();

    var callToJoin = call;
    if (!alreadyInThisCall) {
      callToJoin = await signaling.acceptCall(call.callId);
    }

    if (!context.mounted) return;
    await navigator.push(
      MaterialPageRoute(
        builder:
            (_) => LiveKitGroupCallView(
              call: callToJoin,
              currentUserId: user.id,
              currentUserName: userName,
            ),
      ),
    );
  }
}
