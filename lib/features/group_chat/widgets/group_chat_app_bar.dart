import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/router/app_routes.dart';
import '../../calls/views/outgoing_group_call_screen.dart';
import '../../calls/views/zego_group_call_view.dart';
import '../cubit/group_list_cubit/group_list_cubit.dart';
import '../models/group_call_model.dart';
import '../models/group_model.dart';
import '../services/group_call_signaling_service.dart';

class GroupChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final GroupModel group;

  const GroupChatAppBar({super.key, required this.group});

  Future<void> _initiateCall(BuildContext context, GroupCallType type) async {
    final navigator = Navigator.of(context);
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      final profileData =
          await Supabase.instance.client
              .from('users')
              .select('name')
              .eq('id', user.id)
              .maybeSingle();
      final currentUserName =
          (profileData?['name'] as String?) ?? user.email ?? 'Me';

      final signaling = GroupCallSignalingService();

      final existingCall = await signaling.getActiveCall(group.id);
      if (existingCall != null) {
        final joined = await signaling.acceptCall(existingCall.callId);
        navigator.push(
          MaterialPageRoute(
            builder:
                (_) => ZegoGroupCallView(
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
                callType: type,
              ),
        ),
      );
    } catch (e) {
      debugPrint('Error initiating group call: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final hasAvatar = group.avatarUrl?.isNotEmpty == true;
    final signalingService = GroupCallSignalingService();

    return BlocBuilder<GroupListCubit, GroupListState>(
      builder: (context, state) {
        final updatedGroup =
            (state is GroupListLoaded)
                ? state.groups.firstWhere(
                  (g) => g.id == group.id,
                  orElse: () => group,
                )
                : group;
        final avatarUrl = updatedGroup.avatarUrl;

        return StreamBuilder<GroupCallModel?>(
          stream: signalingService.activeCallStream(group.id),
          builder: (context, snapshot) {
            final activeCall = snapshot.data;
            final hasActiveCall =
                activeCall != null &&
                (activeCall.status == GroupCallStatus.accepted ||
                    activeCall.status == GroupCallStatus.ongoing);

            return AppBar(
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: InkWell(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.arrow_back_ios_new, color: primary, size: 22),
              ),
              titleSpacing: 0,
              title: GestureDetector(
                onTap:
                    () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.groupInfoViewRoute, arguments: group),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: primary.withValues(alpha: 0.12),
                      backgroundImage:
                          hasAvatar
                              ? CachedNetworkImageProvider(avatarUrl!)
                              : null,
                      child:
                          !hasAvatar
                              ? Text(
                                group.name[0].toUpperCase(),
                                style: TextStyle(color: primary),
                              )
                              : null,
                    ),
                    const Gap(10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.name,
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge!.copyWith(color: primary),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Tap for group info',
                            style: Theme.of(
                              context,
                            ).textTheme.titleSmall!.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                if (hasActiveCall)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: const Icon(Icons.call, size: 16),
                      label: const Text('Join'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (_) => ZegoGroupCallView(
                                  call: activeCall,
                                  currentUserId:
                                      Supabase
                                          .instance
                                          .client
                                          .auth
                                          .currentUser!
                                          .id,
                                  currentUserName: 'Me',
                                ),
                          ),
                        );
                      },
                    ),
                  )
                else ...[
                  IconButton(
                    tooltip: 'Voice call',
                    icon: Icon(Icons.phone_outlined, color: primary, size: 22),
                    onPressed:
                        () => _initiateCall(context, GroupCallType.audio),
                  ),
                  IconButton(
                    tooltip: 'Video call',
                    icon: Icon(
                      Icons.videocam_outlined,
                      color: primary,
                      size: 22,
                    ),
                    onPressed:
                        () => _initiateCall(context, GroupCallType.video),
                  ),
                ],
                PopupMenuButton<String>(
                  color: Colors.white,
                  icon: Icon(Icons.more_vert_rounded, color: primary, size: 22),
                  offset: const Offset(-24, kToolbarHeight - 12),
                  onSelected: (value) {
                    if (value == 'info') {
                      Navigator.of(context).pushNamed(
                        AppRoutes.groupInfoViewRoute,
                        arguments: group,
                      );
                    }
                  },
                  itemBuilder:
                      (_) => [
                        const PopupMenuItem(
                          value: 'info',
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 18,
                                color: Colors.black45,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'group info',
                                style: TextStyle(color: Colors.black45),
                              ),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
