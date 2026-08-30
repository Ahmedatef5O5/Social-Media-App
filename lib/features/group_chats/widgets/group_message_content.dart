import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../core/attachment/models/media_transfer_state.dart';
import '../../../core/attachment/widgets/media_state_overlay.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/themes/app_colors.dart';
import '../../chat_forwarding/widgets/forwarded_header.dart';
import '../../reactions/models/live_reaction.dart';
import '../../reactions/widgets/message_reactions_bottom_sheet.dart';
import '../cubits/group_details_cubit/group_details_cubit.dart';
import '../models/groupe_message_model.dart';
import 'group_call_message_content.dart';
import 'group_chat_reaction_overlay.dart';
import 'group_message_avatar.dart';
import 'group_reactions_row_widget.dart';
import 'group_regular_message_content.dart';

const double _kAvatarSlotWidth = 32;

class GroupMessageContent extends StatefulWidget {
  final GroupMessageModel message;
  final bool isMe;
  final bool isMember;
  final Function(GroupMessageModel) onReply;
  final Function(GroupMessageModel)? onEdit;
  final VoidCallback? onLongPress;
  final ItemScrollController itemScrollController;

  final bool showAvatar;

  const GroupMessageContent({
    super.key,
    required this.message,
    required this.isMe,
    required this.isMember,
    required this.onReply,
    this.onEdit,
    this.onLongPress,
    required this.itemScrollController,
    this.showAvatar = true,
  });

  @override
  State<GroupMessageContent> createState() => _GroupMessageContentState();
}

class _GroupMessageContentState extends State<GroupMessageContent> {
  final _anchorKey = GlobalKey();

  Map<String, LiveReaction> _mergeLiveReactions(GroupMessageModel message) => {
    for (final e in message.reactions.entries)
      e.key: LiveReaction(
        emoji: e.value,
        createdAt: message.reactionsCreatedAt?[e.key],
      ),
  };

  void _openReactionsSheet(BuildContext context, GroupDetailsCubit cubit) {
    MessageReactionsBottomSheet.show(
      context: context,
      messageId: widget.message.id,
      initialReactions: _mergeLiveReactions(widget.message),
      currentUserId: cubit.currentUserId,
      reactionsBuilder:
          (contentBuilder) => BlocBuilder<GroupDetailsCubit, GroupDetailsState>(
            bloc: cubit,
            buildWhen: (previous, current) => current is GroupDetailsLoaded,
            builder: (context, state) {
              final messages =
                  state is GroupDetailsLoaded
                      ? state.messages
                      : cubit.cachedMessages;
              final current = messages.firstWhere(
                (m) => m.id == widget.message.id,
                orElse: () => widget.message,
              );
              return contentBuilder(_mergeLiveReactions(current));
            },
          ),
      profileResolver: cubit.reactionProfileResolver,
      onRemoveReaction:
          (emoji) =>
              cubit.toggleReaction(messageId: widget.message.id, emoji: emoji),
      onOpenProfile:
          (userId) => Navigator.of(
            context,
            rootNavigator: true,
          ).pushNamed(AppRoutes.profileViewRoute, arguments: userId),
    );
  }

  void _handleLongPress(BuildContext context, GroupDetailsCubit cubit) {
    final isCall = widget.message.messageType == 'call';
    final alreadySelecting = cubit.isInSelectionMode;
    final primary = Theme.of(context).primaryColor;

    if (!alreadySelecting) {
      if (!isCall) {
        GroupChatReactionOverlay.show(
          context: context,
          anchorKey: _anchorKey,
          message: widget.message,
          onReply: widget.onReply,
          onEdit:
              (widget.isMe && widget.message.messageType == 'text' ||
                      widget.message.caption != null)
                  ? widget.onEdit
                  : null,
          primary: primary,
          isMe: widget.isMe,
        );
      }
      cubit.startSelection(widget.message.id);
    } else {
      cubit.toggleMessageSelection(widget.message.id);
    }
  }

  void _handleTap(GroupDetailsCubit cubit) {
    cubit.toggleMessageSelection(widget.message.id);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GroupDetailsCubit>();

    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final currentUserId = SupabaseProvider.id;

    final isImage = widget.message.messageType == 'image';
    final isVideo = widget.message.messageType == 'video';
    final isVoice = widget.message.messageType == 'voice';
    final isFile = widget.message.messageType == 'file';

    final isCall = widget.message.messageType == 'call';
    final bool isStickerOrGif =
        widget.message.messageType == 'gif' ||
        widget.message.messageType == 'sticker';
    final bgColor =
        widget.isMe
            ? primary
            : (isDark
                ? Colors.white.withValues(alpha: 0.10)
                : AppColors.grey3.withValues(alpha: 0.35));
    final textColor =
        widget.isMe
            ? Colors.white
            : (isDark ? Colors.white : AppColors.black87);

    return BlocBuilder<GroupDetailsCubit, GroupDetailsState>(
      buildWhen: (prev, cur) {
        if (cur is GroupDetailsLoaded && prev is GroupDetailsLoaded) {
          final hadPrev = prev.uploadProgress.containsKey(widget.message.id);
          final hasCur = cur.uploadProgress.containsKey(widget.message.id);
          return hadPrev != hasCur ||
              prev.uploadProgress[widget.message.id] !=
                  cur.uploadProgress[widget.message.id];
        }
        return false;
      },
      builder: (context, state) {
        final double? uploadProgress =
            (state is GroupDetailsLoaded && widget.isMe)
                ? state.uploadProgress[widget.message.id]
                : null;
        final bool isUploading = uploadProgress != null;

        return ValueListenableBuilder<Set<String>>(
          valueListenable: cubit.selectedMessageIds,
          builder: (context, selectedIds, _) {
            final isSelectionMode = selectedIds.isNotEmpty;
            final isSelected = selectedIds.contains(widget.message.id);

            return ValueListenableBuilder<String?>(
              valueListenable: cubit.highlightedMessageId,
              builder: (context, highlightId, _) {
                final isHighlighted = highlightId == widget.message.id;
                final highlightColor = Theme.of(
                  context,
                ).primaryColor.withValues(alpha: widget.isMe ? 0.12 : 0.2);
                final selectionColor = Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.16);

                return GestureDetector(
                  onTap:
                      (isSelectionMode && widget.isMember)
                          ? () => _handleTap(cubit)
                          : null,
                  onLongPress:
                      (isCall || !widget.isMember)
                          ? null
                          : () => _handleLongPress(context, cubit),
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? selectionColor
                              : (isHighlighted
                                  ? highlightColor
                                  : Colors.transparent),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          widget.isMe
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AnimatedSize(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          child:
                              isSelectionMode
                                  ? Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Icon(
                                      isSelected
                                          ? Icons.check_circle_rounded
                                          : Icons.circle_outlined,
                                      size: 22,
                                      color:
                                          isSelected
                                              ? primary
                                              : AppColors.grey6,
                                    ),
                                  )
                                  : const SizedBox.shrink(),
                        ),
                        if (!widget.isMe) ...[
                          widget.showAvatar
                              ? GroupMessageAvatar(
                                message: widget.message,
                                primary: primary,
                              )
                              : const SizedBox(width: _kAvatarSlotWidth),
                          const Gap(8),
                        ],
                        Flexible(
                          child: AbsorbPointer(
                            absorbing: isSelectionMode,
                            child: KeyedSubtree(
                              key: _anchorKey,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  _buildBubble(
                                    context: context,
                                    primary: primary,
                                    isDark: isDark,
                                    bgColor: bgColor,
                                    textColor: textColor,
                                    isImage: isImage,
                                    isVideo: isVideo,
                                    isVoice: isVoice,
                                    isFile: isFile,
                                    isCall: isCall,
                                    isStickerOrGif: isStickerOrGif,
                                    isUploading: isUploading,
                                    uploadProgress: uploadProgress,
                                  ),
                                  if (widget.message.reactions.isNotEmpty)
                                    Positioned(
                                      bottom: -2.0,
                                      right: widget.isMe ? 4 : null,
                                      left: widget.isMe ? null : 4,
                                      child: GroupReactionsRow(
                                        reactions: widget.message.reactions,
                                        currentUserId: currentUserId,
                                        primary: primary,
                                        onTap:
                                            () => _openReactionsSheet(
                                              context,
                                              cubit,
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBubble({
    required BuildContext context,
    required Color primary,
    required bool isDark,
    required Color bgColor,
    required Color textColor,
    required bool isImage,
    required bool isVideo,
    required bool isVoice,
    required bool isFile,
    required bool isCall,
    required bool isStickerOrGif,
    required bool isUploading,
    double? uploadProgress,
  }) {
    final hasReaction = widget.message.reactions.isNotEmpty;

    final Widget content =
        isCall
            ? GroupCallMessageContent(
              message: widget.message,
              isMe: widget.isMe,
              primary: primary,
            )
            : GroupRegularMessageContent(
              message: widget.message,
              isMe: widget.isMe,
              isUploading: isUploading,
              textColor: textColor,
              primary: primary,
              itemScrollController: widget.itemScrollController,
            );

    final Widget innerContent = Padding(
      padding:
          isStickerOrGif
              ? EdgeInsets.zero
              : (isImage || isVideo)
              ? const EdgeInsets.all(3)
              : const EdgeInsets.only(left: 10, right: 10, bottom: 8, top: 6),
      child:
          widget.message.isForwarded
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ForwardedHeader(
                    name: widget.message.forwardedFromUserName ?? 'Unknown',
                    originalSenderId: widget.message.forwardedFromUserId ?? '',
                    avatarUrl: widget.message.forwardedFromUserAvatar,
                    onColoredBubble: widget.isMe && !isStickerOrGif,
                  ),
                  content,
                ],
              )
              : content,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenCap = MediaQuery.of(context).size.width * 0.70;
        final double maxBubbleWidth =
            constraints.maxWidth < screenCap ? constraints.maxWidth : screenCap;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Opacity(
              opacity: 1.0,
              child: Container(
                margin: EdgeInsets.only(top: 2, bottom: hasReaction ? 28 : 2),
                constraints: BoxConstraints(
                  maxWidth: maxBubbleWidth,
                  minWidth:
                      isVoice
                          ? (240 > maxBubbleWidth ? maxBubbleWidth : 240)
                          : (isImage || isVideo ? 200 : 50),
                ),
                decoration: BoxDecoration(
                  color:
                      isStickerOrGif
                          ? Colors.transparent
                          : (isImage || isVideo) &&
                              !isUploading &&
                              (widget.message.imageUrl == null &&
                                  widget.message.videoUrl == null)
                          ? Colors.transparent
                          : bgColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(widget.isMe ? 20 : 0),
                    bottomRight: Radius.circular(widget.isMe ? 0 : 20),
                  ),
                ),
                child:
                    isStickerOrGif
                        ? innerContent
                        : ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: Radius.circular(widget.isMe ? 20 : 0),
                            bottomRight: Radius.circular(widget.isMe ? 0 : 20),
                          ),
                          child: innerContent,
                        ),
              ),
            ),

            if (isUploading && !isVoice && !isFile)
              Positioned.fill(
                child: ValueListenableBuilder<double>(
                  valueListenable: context
                      .read<GroupDetailsCubit>()
                      .progressNotifierFor(widget.message.id),
                  builder: (context, progress, _) {
                    return MediaStateOverlay(
                      state: MediaTransferState.uploading(progress),
                      isVideo: isVideo,
                      durationSeconds: widget.message.durationSeconds,
                      fileSizeBytes: widget.message.fileSizeBytes,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(widget.isMe ? 18 : 4),
                        bottomRight: Radius.circular(widget.isMe ? 4 : 18),
                      ),
                      onCancelTap:
                          () => context.read<GroupDetailsCubit>().cancelUpload(
                            widget.message.id,
                          ),
                      child: const SizedBox.shrink(),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
