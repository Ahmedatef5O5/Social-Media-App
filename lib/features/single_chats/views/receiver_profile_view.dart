import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:social_media_app/core/helpers/formatted_date.dart';
import 'package:social_media_app/features/single_chats/models/chat_block_status.dart';
import 'package:social_media_app/features/single_chats/models/chat_user_model.dart';
import '../../../core/cache/services/starred_message_store.dart';
import '../../../core/chat_shared/helpers/muted_badge_icon.dart';
import '../../../core/chat_shared/views/starred_messages_view.dart';
import '../../../core/chat_shared/cubits/shared_media_cubit/shared_media_cubit.dart';
import '../../../core/chat_shared/widgets/shared_media_preview_section.dart';
import '../../../core/chat_shared/models/starred_message_entry.dart';
import '../../../core/chat_shared/widgets/starred_messages_row.dart';
import '../../../core/presence/cubit/presence_cubit/presence_cubit.dart';
import '../../../core/presence/model/chat_action_type.dart';
import '../../../core/presence/model/presence_info.dart';
import '../../../core/chat_shared/services/shared_media_data_source.dart';
import '../../../core/services/active_call/active_call_session_data.dart';
import '../../../core/services/active_call/cubit/active_call_session_cubit.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/widgets/animated_activity_text.dart';
import '../../../core/widgets/calls/call_icon_button.dart';
import '../../../core/widgets/custom_user_profile_image_section.dart';
import '../../single_calls/models/call_model.dart';
import '../cubits/chat_details_cubit/chat_details_cubit.dart';
import '../cubits/shared_groups_cubit/shared_groups_cubit.dart';
import '../cubits/shared_groups_cubit/shared_groups_state.dart';
import '../helpers/safe_pop.dart';
import '../services/chat_services.dart';
import '../services/shared_groups_service.dart';
import '../widgets/shared_groups_section.dart';

class ReceiverProfileView extends StatefulWidget {
  final ChatUserModel receiverUser;

  final ItemScrollController? itemScrollController;

  const ReceiverProfileView({
    super.key,
    required this.receiverUser,
    this.itemScrollController,
  });

  @override
  State<ReceiverProfileView> createState() => _ReceiverProfileViewState();
}

class _ReceiverProfileViewState extends State<ReceiverProfileView> {
  late final SharedMediaCubit _mediaCubit;
  late final SharedGroupsCubit _groupsCubit;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<ChatDetailsCubit>();
    cubit.watchMuteStatus(widget.receiverUser.id);
    _mediaCubit = SharedMediaCubit(
      SingleChatMediaDataSource(
        services: context.read<ChatServices>(),
        currentUserId: cubit.currentUserId,
        currentUserName: cubit.currentUserName,
        currentUserAvatar: cubit.senderImageUrl,
        receiverUser: widget.receiverUser,
      ),
    );
    _groupsCubit = SharedGroupsCubit(
      service: SharedGroupsService(),
      currentUserId: SupabaseProvider.id,
      otherUserId: widget.receiverUser.id,
    );
  }

  @override
  void dispose() {
    _mediaCubit.close();
    _groupsCubit.close();
    super.dispose();
  }

  Future<void> _openStarredMessages(BuildContext context) async {
    final cubit = context.read<ChatDetailsCubit>();
    final starredIds = await StarredMessagesStore.instance.getStarredMessageIds(
      cubit.currentUserId,
    );

    if (!context.mounted) return;

    final entries =
        cubit.cachedMessages
            .where((m) => starredIds.contains(m.id))
            .map(
              (m) => m.toStarredEntry(
                currentUserId: cubit.currentUserId,
                meName: cubit.currentUserName,
                receiverName: widget.receiverUser.name,
              ),
            )
            .toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => StarredMessagesView(
              entries: entries,
              onUnstar:
                  (messageId) => StarredMessagesStore.instance.toggleStar(
                    currentUserId: cubit.currentUserId,
                    messageId: messageId,
                  ),
              onTapEntry: (messageId) {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                final controller = widget.itemScrollController;
                if (controller != null) {
                  cubit.scrollToMessage(
                    messageId: messageId,
                    itemScrollController: controller,
                  );
                }
              },
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                CustomUserProfileImagesSection(
                  avatarUrl: widget.receiverUser.imageUrl,
                  heroTag: widget.receiverUser.id,
                  isProfileHeader: true,
                  profileUserId: widget.receiverUser.id,
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 18.0),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => safePop(context),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Gap(10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                Flexible(
                  child: Text(
                    widget.receiverUser.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: context.read<ChatDetailsCubit>().muteStatus,
                  builder:
                      (context, isMuted, _) =>
                          isMuted
                              ? const MutedBadgeIcon(size: 10)
                              : const SizedBox.shrink(),
                ),
              ],
            ),
            BlocBuilder<ChatDetailsCubit, ChatDetailsState>(
              builder: (context, state) {
                return ValueListenableBuilder<ChatActionType>(
                  valueListenable:
                      context.read<ChatDetailsCubit>().receiverAction,
                  builder: (context, action, _) {
                    if (action != ChatActionType.none) {
                      return AnimatedActivityText(
                        text:
                            action == ChatActionType.recording
                                ? 'recording audio...'
                                : 'typing...',
                        style: TextStyle(
                          color:
                              action == ChatActionType.recording
                                  ? Colors.red.shade700
                                  : Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                        ),
                      );
                    }

                    return Builder(
                      builder: (context) {
                        final presenceInfo = context
                            .select<PresenceCubit, PresenceInfo?>(
                              (cubit) => cubit.of(widget.receiverUser.id),
                            );
                        final isOnline =
                            presenceInfo?.isEffectivelyOnline ??
                            widget.receiverUser.isOnline;
                        final lastSeen =
                            presenceInfo?.lastSeen ??
                            widget.receiverUser.lastSeen;

                        if (isOnline) {
                          return const Text(
                            'Online',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          );
                        }

                        if (lastSeen != null) {
                          final lastSeenStr = FormattedDate.getLastSeen(
                            lastSeen,
                          );

                          if (lastSeenStr == 'Online' ||
                              lastSeenStr == 'just now') {
                            return const Text(
                              'Online',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            );
                          }

                          return Text(
                            "Last seen $lastSeenStr",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          );
                        }

                        return const SizedBox.shrink();
                      },
                    );
                  },
                );
              },
            ),

            const Gap(25),

            ValueListenableBuilder<ChatBlockStatus>(
              valueListenable: context.read<ChatDetailsCubit>().blockStatus,
              builder: (context, blockStatus, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildOptionItem(
                      context,
                      Icons.message_outlined,
                      "Message",
                      () => safePop(context),
                    ),
                    _buildOptionItem(
                      context,
                      Icons.call_outlined,
                      "Call",
                      () {},
                      isBlocked: blockStatus.isBlocked,
                    ),
                    _buildOptionItem(
                      context,
                      Icons.videocam_outlined,
                      "Video",
                      () {},
                      isBlocked: blockStatus.isBlocked,
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable:
                          context.read<ChatDetailsCubit>().muteStatus,
                      builder: (context, isMuted, _) {
                        return _buildOptionItem(
                          context,
                          isMuted
                              ? Icons.notifications_off
                              : Icons.notifications_off_outlined,
                          isMuted ? "Unmute" : "Mute",
                          () => context.read<ChatDetailsCubit>().toggleMute(
                            receiverId: widget.receiverUser.id,
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),

            const Gap(16),
            StarredMessagesRow(
              primary: Theme.of(context).primaryColor,
              onTap: () => _openStarredMessages(context),
            ),

            BlocBuilder<SharedMediaCubit, SharedMediaState>(
              bloc: _mediaCubit,
              builder: (context, mediaState) {
                final hasMedia =
                    mediaState.previewLoading || mediaState.preview.isNotEmpty;

                return BlocBuilder<SharedGroupsCubit, SharedGroupsState>(
                  bloc: _groupsCubit,
                  builder: (context, groupsState) {
                    final hasGroups =
                        groupsState is SharedGroupsLoading ||
                        groupsState is SharedGroupsInitial ||
                        (groupsState is SharedGroupsLoaded &&
                            groupsState.groups.isNotEmpty);
                    final hasAnyContent = hasMedia || hasGroups;

                    return Column(
                      children: [
                        Builder(
                          builder: (context) {
                            final chatCubit = context.read<ChatDetailsCubit>();
                            return SharedMediaPreviewSection(
                              mediaCubit: _mediaCubit,
                              onShowInChat: (sheetContext, messageId) {
                                Navigator.of(sheetContext).pop();
                                Navigator.of(sheetContext).pop();
                                final controller = widget.itemScrollController;
                                if (controller != null) {
                                  chatCubit.scrollToMessage(
                                    messageId: messageId,
                                    itemScrollController: controller,
                                  );
                                }
                              },
                            );
                          },
                        ),
                        if (hasMedia && hasGroups) const SizedBox(height: 14),
                        SharedGroupsSection(groupsCubit: _groupsCubit),
                        if (hasAnyContent) const SizedBox(height: 24),
                      ],
                    );
                  },
                );
              },
            ),

            ValueListenableBuilder<ChatBlockStatus>(
              valueListenable: context.read<ChatDetailsCubit>().blockStatus,
              builder: (context, status, _) {
                final isBlockedByMe = status.blockedByMe;
                final color = isBlockedByMe ? null : Colors.red;
                return InkWell(
                  onTap:
                      () => context.read<ChatDetailsCubit>().toggleBlock(
                        receiverId: widget.receiverUser.id,
                        otherUserName: widget.receiverUser.name,
                      ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isBlockedByMe
                              ? Icons.person_add_alt_1
                              : Icons.block_rounded,
                          color: color,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            isBlockedByMe
                                ? 'Unblock ${widget.receiverUser.name}'
                                : 'Block ${widget.receiverUser.name}',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isBlocked = false,
  }) {
    final buttonStyle = IconButton.styleFrom(
      backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      padding: const EdgeInsets.all(12),
    );

    final lowerLabel = label.toLowerCase();
    final isCallOrVideo = lowerLabel == 'call' || lowerLabel == 'video';

    Widget iconWidget;
    Widget labelWidget;

    if (isCallOrVideo) {
      iconWidget = CallIconButton(
        type: lowerLabel == 'call' ? CallType.audio : CallType.video,
        receiverId: widget.receiverUser.id,
        receiverName: widget.receiverUser.name,
        receiverAvatar: widget.receiverUser.imageUrl ?? '',
        isBlocked: isBlocked,
        style: buttonStyle,
      );
      labelWidget = BlocBuilder<ActiveCallSessionCubit, ActiveCallSessionData?>(
        builder: (context, activeSession) {
          final isDisabled = isBlocked || activeSession != null;
          return Text(
            label,
            style: TextStyle(
              color: isDisabled ? Colors.grey : Theme.of(context).primaryColor,
              fontSize: 12,
            ),
          );
        },
      );
    } else {
      iconWidget = IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: Theme.of(context).primaryColor),
        style: buttonStyle,
      );
      labelWidget = Text(
        label,
        style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12),
      );
    }

    return Column(children: [iconWidget, const Gap(4), labelWidget]);
  }
}
