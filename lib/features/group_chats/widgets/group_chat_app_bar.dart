import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../core/chat_shared/helpers/muted_badge_icon.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/services/active_call/active_call_session_data.dart';
import '../../../core/services/active_call/cubits/active_call_session_cubit.dart';
import '../../../core/services/incoming_call_navigation_guard.dart';
import '../../../core/toast/app_toast.dart';
import '../../group_calls/helpers/group_call_join_helper.dart';
import '../../group_calls/models/group_call_model.dart';
import '../../group_calls/services/group_call_signaling_service.dart';
import '../cubits/group_details_cubit/group_details_cubit.dart';
import '../cubits/group_list_cubit/group_list_cubit.dart';
import '../helpers/group_call_initiator.dart';
import '../helpers/group_members_online_label.dart';
import '../models/group_model.dart';
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
                              ? Container(
                                padding: EdgeInsets.zero,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: AssetImage(
                                      AppImages.defaultGroupImg,
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
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
                                  style: Theme.of(context).textTheme.titleLarge!
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
                if (isMemberLive)
                  _GroupCallActionsSection(
                    groupId: group.id,
                    group: updatedGroup,
                  ),
                PopupMenuButton<String>(
                  color: Colors.white,
                  icon: Icon(Icons.more_vert_rounded, color: primary, size: 22),
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
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _GroupCallActionsSection extends StatefulWidget {
  final String groupId;
  final GroupModel group;

  const _GroupCallActionsSection({required this.groupId, required this.group});

  @override
  State<_GroupCallActionsSection> createState() =>
      _GroupCallActionsSectionState();
}

class _GroupCallActionsSectionState extends State<_GroupCallActionsSection> {
  late Stream<GroupCallModel?> _activeCallStream;

  @override
  void initState() {
    super.initState();
    _activeCallStream = _createStream();
  }

  @override
  void didUpdateWidget(covariant _GroupCallActionsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId) {
      _activeCallStream = _createStream();
    }
  }

  Stream<GroupCallModel?> _createStream() => context
      .read<GroupCallSignalingService>()
      .activeCallStream(widget.groupId);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return StreamBuilder<GroupCallModel?>(
      stream: _activeCallStream,
      builder: (context, snapshot) {
        final activeCall = snapshot.data;
        final hasActiveCall =
            activeCall != null &&
            (activeCall.status == GroupCallStatus.accepted ||
                activeCall.status == GroupCallStatus.ongoing);

        return BlocBuilder<ActiveCallSessionCubit, ActiveCallSessionData?>(
          builder: (context, activeSession) {
            if (hasActiveCall) {
              final isBusyWithOtherCall =
                  (activeSession != null &&
                      activeSession.callId != activeCall.callId) ||
                  IncomingCallNavigationGuard.isUserBusyWithAnotherCall(
                    activeCall.callId,
                  );

              return Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Material(
                  color:
                      isBusyWithOtherCall
                          ? Colors.grey
                          : const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      if (isBusyWithOtherCall) {
                        AppToast.warning(
                          'Please end your current call before joining another call.',
                        );
                        return;
                      }
                      GroupCallJoinHelper.join(context, activeCall);
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.call, size: 13, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Join',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            final isLocalUserBusy =
                activeSession != null ||
                IncomingCallNavigationGuard.isUserBusyWithAnotherCall();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Voice call',
                  icon: Icon(
                    Icons.phone_outlined,
                    color: isLocalUserBusy ? Colors.grey : primary,
                    size: 22,
                  ),
                  onPressed:
                      isLocalUserBusy
                          ? null
                          : () => GroupCallInitiator.initiate(
                            context,
                            widget.group,
                            GroupCallType.audio,
                          ),
                ),
                IconButton(
                  tooltip: 'Video call',
                  icon: Icon(
                    Icons.videocam_outlined,
                    color: isLocalUserBusy ? Colors.grey : primary,
                    size: 22,
                  ),
                  onPressed:
                      isLocalUserBusy
                          ? null
                          : () => GroupCallInitiator.initiate(
                            context,
                            widget.group,
                            GroupCallType.video,
                          ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
