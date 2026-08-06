import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:social_media_app/core/helpers/formatted_date.dart';
import 'package:social_media_app/features/single_chats/models/chat_block_status.dart';
import 'package:social_media_app/features/single_chats/models/chat_user_model.dart';
import '../../../core/cache/services/starred_message_store.dart';
import '../../../core/chat_shared/views/starred_messages_view.dart';
import '../../../core/chat_shared/cubits/shared_media_cubit/shared_media_cubit.dart';
import '../../../core/chat_shared/widgets/shared_media_preview_section.dart';
import '../../../core/chat_shared/models/starred_message_entry.dart';
import '../../../core/chat_shared/widgets/starred_messages_row.dart';
import '../../../core/presence/cubit/presence_cubit/presence_cubit.dart';
import '../../../core/presence/model/presence_info.dart';
import '../../../core/chat_shared/services/shared_media_data_source.dart';
import '../../../core/widgets/calls/call_icon_button.dart';
import '../../../core/widgets/custom_user_profile_image_section.dart';
import '../../single_calls/model/call_model.dart';
import '../cubit/chat_details_cubit/chat_details_cubit.dart';
import '../helper/safe_pop.dart';
import '../services/chat_services.dart';

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

  @override
  void initState() {
    super.initState();
    final cubit = context.read<ChatDetailsCubit>();
    _mediaCubit = SharedMediaCubit(
      SingleChatMediaDataSource(
        services: context.read<ChatServices>(),
        currentUserId: cubit.currentUserId,
        currentUserName: cubit.currentUserName,
        currentUserAvatar: cubit.senderImageUrl,
        receiverUser: widget.receiverUser,
      ),
    );
  }

  @override
  void dispose() {
    _mediaCubit.close();
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
                // Pop StarredMessagesView, then this profile view, landing
                // back on the actual open chat, then scroll+highlight.
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
                    padding: const EdgeInsets.only(top: 12.0),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => safePop(context),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Gap(10),
            Text(
              widget.receiverUser.name,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            BlocBuilder<ChatDetailsCubit, ChatDetailsState>(
              builder: (context, state) {
                final isTyping = state is ReceiverTypingState && state.isTyping;
                if (isTyping) {
                  return const Text(
                    'typing...',
                    style: TextStyle(
                      color: Colors.green,
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
                        presenceInfo?.lastSeen ?? widget.receiverUser.lastSeen;

                    if (isOnline) {
                      return const Text(
                        'Online',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }

                    if (lastSeen != null) {
                      final lastSeenStr = FormattedDate.getLastSeen(lastSeen);

                      if (lastSeenStr == 'Online' ||
                          lastSeenStr == 'just now') {
                        return const Text(
                          'Online',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }

                      return Text(
                        "Last seen $lastSeenStr",
                        style: const TextStyle(color: Colors.grey),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                );
              },
            ),

            const Gap(25),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOptionItem(
                  context,
                  Icons.message_outlined,
                  "Message",
                  () => safePop(context),
                ),
                _buildOptionItem(context, Icons.call_outlined, "Call", () {}),
                _buildOptionItem(
                  context,
                  Icons.videocam_outlined,
                  "Video",
                  () {},
                ),
                _buildOptionItem(
                  context,
                  Icons.notifications_off_outlined,
                  "Mute",
                  () {},
                ),
              ],
            ),

            const Gap(16),
            StarredMessagesRow(
              primary: Theme.of(context).primaryColor,
              onTap: () => _openStarredMessages(context),
            ),

            const Divider(height: 40, thickness: 8, color: Color(0x00fff5f5)),

            SharedMediaPreviewSection(mediaCubit: _mediaCubit),

            const Divider(height: 24, thickness: 8, color: Color(0x00fff5f5)),

            ValueListenableBuilder<ChatBlockStatus>(
              valueListenable: context.read<ChatDetailsCubit>().blockStatus,
              builder: (context, status, _) {
                final isBlockedByMe = status.blockedByMe;
                return ListTile(
                  leading: Icon(
                    isBlockedByMe
                        ? Icons.person_add_alt_1
                        : Icons.block_rounded,
                    color: isBlockedByMe ? null : Colors.red,
                  ),
                  title: Text(
                    isBlockedByMe
                        ? 'Unblock ${widget.receiverUser.name}'
                        : 'Block ${widget.receiverUser.name}',
                    style: TextStyle(
                      color: isBlockedByMe ? null : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap:
                      () => context.read<ChatDetailsCubit>().toggleBlock(
                        receiverId: widget.receiverUser.id,
                        otherUserName: widget.receiverUser.name,
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
    VoidCallback onTap,
  ) {
    final buttonStyle = IconButton.styleFrom(
      backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      padding: const EdgeInsets.all(12),
    );

    final lowerLabel = label.toLowerCase();

    Widget iconWidget;

    if (lowerLabel == 'call' || lowerLabel == 'video') {
      iconWidget = CallIconButton(
        type: lowerLabel == 'call' ? CallType.audio : CallType.video,
        receiverId: widget.receiverUser.id,
        receiverName: widget.receiverUser.name,
        receiverAvatar: widget.receiverUser.imageUrl ?? '',
        style: buttonStyle,
      );
    } else {
      iconWidget = IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: Theme.of(context).primaryColor),
        style: buttonStyle,
      );
    }

    return Column(
      children: [
        iconWidget,
        const Gap(4),
        Text(
          label,
          style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12),
        ),
      ],
    );
  }
}
