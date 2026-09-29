import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/connectivity/services/connectivity_banner_controller.dart';
import '../../../core/services/current_user_name_resolver.dart';
import '../../../core/services/incoming_call_navigation_guard.dart';
import '../../../core/services/permissions/app_permissions_service.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../group_calls/helpers/group_call_join_helper.dart';
import '../../group_calls/models/group_call_model.dart';
import '../../group_calls/services/group_call_signaling_service.dart';
import '../../group_calls/views/outgoing_group_call_screen.dart';
import '../models/group_model.dart';

class GroupCallInitiator {
  static Future<void> initiate(
    BuildContext context,
    GroupModel group,
    GroupCallType type,
  ) async {
    if (!group.isMember) {
      debugPrint(
        '⛔ Blocked: attempted to initiate a group call as a non-member',
      );
      return;
    }

    final navigator = Navigator.of(context);
    final signaling = context.read<GroupCallSignalingService>();
    var outgoingFlagRaised = false;

    try {
      final isOffline = await ConnectivityBannerController.notifyIfOffline();
      if (isOffline) return;

      final user = SupabaseProvider.user;
      if (user == null) return;
      if (!context.mounted) return;

      final existingCall = await signaling.getActiveCall(group.id);
      if (!context.mounted) return;
      if (existingCall != null) {
        await GroupCallJoinHelper.join(context, existingCall);
        return;
      }

      final granted = await AppPermissionsService.instance
          .ensureCallPermissions(
            isVideo: type == GroupCallType.video,
            context: context,
          );
      if (!granted || !context.mounted) return;

      final currentUserName = await CurrentUserNameResolver.resolve();
      if (!context.mounted) return;

      IncomingCallNavigationGuard.setOutgoingGroupCallActive(true);
      outgoingFlagRaised = true;

      await signaling.initiateCall(
        groupId: group.id,
        groupName: group.name,
        groupAvatarUrl: group.avatarUrl,
        currentUserId: user.id,
        currentUserName: currentUserName,
        type: type,
      );

      outgoingFlagRaised = false;
      await navigator.push(
        MaterialPageRoute(
          builder:
              (_) => OutgoingGroupCallScreen(
                groupId: group.id,
                groupName: group.name,
                groupAvatarUrl: group.avatarUrl,
                callType: type,
              ),
        ),
      );
    } catch (e) {
      debugPrint('Error initiating group call: $e');
      if (outgoingFlagRaised) {
        IncomingCallNavigationGuard.setOutgoingGroupCallActive(false);
      }
    }
  }
}
