import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/connectivity/services/connectivity_banner_controller.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../profile/services/user_services.dart';
import '../../group_calls/models/group_call_model.dart';
import '../../group_calls/services/group_call_signaling_service.dart';
import '../../group_calls/views/livekit_group_call_view.dart';
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
    try {
      final isOffline = await ConnectivityBannerController.notifyIfOffline();
      if (isOffline) return;

      final user = SupabaseProvider.user!;
      final fetchedName = await UserService().fetchUserName(user.id);
      final currentUserName = fetchedName ?? user.email ?? 'Me';
      if (!context.mounted) return;
      final signaling = context.read<GroupCallSignalingService>();
      final existingCall = await signaling.getActiveCall(group.id);
      if (existingCall != null) {
        final joined = await signaling.acceptCall(existingCall.callId);
        navigator.push(
          MaterialPageRoute(
            builder:
                (_) => LiveKitGroupCallView(
                  call: joined,
                  currentUserId: user.id,
                  currentUserName: currentUserName,
                ),
          ),
        );
        return;
      }

      await signaling.initiateCall(
        groupId: group.id,
        groupName: group.name,
        groupAvatarUrl: group.avatarUrl,
        currentUserId: user.id,
        currentUserName: currentUserName,
        type: type,
      );

      navigator.push(
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
    }
  }
}
