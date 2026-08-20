import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:social_media_app/features/group_calls/views/livekit_group_call_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/chat_shared/helpers/muted_badge_icon.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/services/active_call/active_call_session_data.dart';
import '../../../core/services/active_call/cubit/active_call_session_cubit.dart';
import '../cubit/group_details_cubit/group_details_cubit.dart';
import '../cubit/group_list_cubit/group_list_cubit.dart';
import '../../group_calls/models/group_call_model.dart';
import '../helpers/group_call_initiator.dart';
import '../helpers/group_members_online_label.dart';
import '../models/group_model.dart';
import '../../group_calls/services/group_call_signaling_service.dart';
import 'presence_animated_subtitle.dart';

class GroupChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final GroupModel group;
  final ItemScrollController itemScrollController;

  const GroupChatAppBar({
    super.key,
    required this.group,
    required this.itemScrollController,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final hasAvatar = group.avatarUrl?.isNotEmpty == true;
    final signalingService = context.read<GroupCallSignalingService>();

    return BlocBuilder<GroupDetailsCubit, GroupDetailsState>(
      builder: (context, detailsState) {
        final isMemberLive =
            detailsState is GroupDetailsLoaded
                ? detailsState.isMember
                : group.isMember;

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
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: primary,
                      size: 22,
                    ),
                  ),
                  titleSpacing: 0,
                  title: GestureDetector(
                    onTap:
                        () => Navigator.of(context).pushNamed(
                          AppRoutes.groupInfoViewRoute,
                          arguments: {
                            'group': group,
                            'cubit': context.read<GroupDetailsCubit>(),
                            'itemScrollController': itemScrollController,
                          },
                        ),
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
                                    updatedGroup.name[0].toUpperCase(),
                                    style: TextStyle(color: primary),
                                  )
                                  : null,
                        ),
                        const Gap(10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      updatedGroup.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge!
                                          .copyWith(color: primary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (updatedGroup.isMuted)
                                    const MutedBadgeIcon(size: 10),
                                ],
                              ),
                              PresenceAnimatedSubtitle(
                                presence: updatedGroup.presence,
                                fallback: GroupMembersOnlineLabel(
                                  groupId: updatedGroup.id,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleSmall!.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    if (isMemberLive) ...[
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
                                      (_) => LiveKitGroupCallView(
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
                        BlocBuilder<
                          ActiveCallSessionCubit,
                          ActiveCallSessionData?
                        >(
                          builder: (context, activeSession) {
                            final isLocalUserBusy = activeSession != null;
                            return Row(
                              children: [
                                IconButton(
                                  tooltip: 'Voice call',
                                  icon: Icon(
                                    Icons.phone_outlined,
                                    color:
                                        isLocalUserBusy ? Colors.grey : primary,
                                    size: 22,
                                  ),
                                  onPressed:
                                      isLocalUserBusy
                                          ? null
                                          : () => GroupCallInitiator.initiate(
                                            context,
                                            updatedGroup,
                                            GroupCallType.audio,
                                          ),
                                ),
                                IconButton(
                                  tooltip: 'Video call',
                                  icon: Icon(
                                    Icons.videocam_outlined,
                                    color:
                                        isLocalUserBusy ? Colors.grey : primary,
                                    size: 22,
                                  ),
                                  onPressed:
                                      isLocalUserBusy
                                          ? null
                                          : () => GroupCallInitiator.initiate(
                                            context,
                                            updatedGroup,
                                            GroupCallType.video,
                                          ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                    PopupMenuButton<String>(
                      color: Colors.white,
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: primary,
                        size: 22,
                      ),
                      offset: const Offset(-24, kToolbarHeight - 12),
                      onSelected: (value) {
                        if (value == 'info') {
                          Navigator.of(context).pushNamed(
                            AppRoutes.groupInfoViewRoute,
                            arguments: {
                              'group': updatedGroup,
                              'cubit': context.read<GroupDetailsCubit>(),
                              'itemScrollController': itemScrollController,
                            },
                          );
                        } else if (value == 'search') {
                          context
                              .read<GroupDetailsCubit>()
                              .searchController
                              .activate();
                        }
                      },
                      itemBuilder:
                          (_) => [
                            const PopupMenuItem(
                              value: 'search',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.search_rounded,
                                    size: 18,
                                    color: Colors.black45,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Search',
                                    style: TextStyle(color: Colors.black45),
                                  ),
                                ],
                              ),
                            ),
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
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
