import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:social_media_app/features/single_chats/cubits/chat_details_cubit/chat_details_cubit.dart';
import 'package:social_media_app/features/single_chats/widgets/message_reactions_row_widget.dart';
import '../../../core/attachment/models/media_transfer_state.dart';
import '../../../core/attachment/widgets/media_state_overlay.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/themes/app_colors.dart';
import '../../chat_forwarding/widgets/forwarded_header.dart';
import '../../reactions/models/live_reaction.dart';
import '../../reactions/services/reaction_profile_resolver.dart';
import '../../reactions/widgets/message_reactions_bottom_sheet.dart';
import '../models/chat_user_model.dart';
import '../models/message_model.dart';
import 'call_message_content.dart';
import 'regular_message_content.dart';

class MessageContentContainer extends StatefulWidget {
  final MessageModel message;
  final ChatUserModel receiverUser;
  final bool isMe;
  final double? uploadProgress;
  final ItemScrollController itemScrollController;
  const MessageContentContainer({
    super.key,
    required this.message,
    required this.receiverUser,
    required this.isMe,
    this.uploadProgress,
    required this.itemScrollController,
  });

  @override
  State<MessageContentContainer> createState() =>
      _MessageContentContainerState();
}

class _MessageContentContainerState extends State<MessageContentContainer> {
  Map<String, LiveReaction> _mergeLiveReactions(MessageModel message) => {
    for (final e in message.reactions.entries)
      e.key: LiveReaction(
        emoji: e.value,
        createdAt: message.reactionsCreatedAt?[e.key],
      ),
  };

  void _openReactionsSheet(BuildContext context) {
    final cubit = context.read<ChatDetailsCubit>();
    final partnerId =
        widget.message.senderId == cubit.currentUserId
            ? widget.message.receiverId
            : widget.message.senderId;

    MessageReactionsBottomSheet.show(
      context: context,
      messageId: widget.message.id,
      initialReactions: _mergeLiveReactions(widget.message),
      currentUserId: cubit.currentUserId,
      reactionsBuilder:
          (contentBuilder) => BlocBuilder<ChatDetailsCubit, ChatDetailsState>(
            bloc: cubit,
            buildWhen: (previous, current) => current is MessagesSuccessLoaded,
            builder: (context, state) {
              final messages =
                  state is MessagesSuccessLoaded
                      ? state.messages
                      : cubit.cachedMessages;
              final current = messages.firstWhere(
                (m) => m.id == widget.message.id,
                orElse: () => widget.message,
              );
              return contentBuilder(_mergeLiveReactions(current));
            },
          ),
      profileResolver: SingleChatReactionProfileResolver(
        currentUserId: cubit.currentUserId,
        currentUserName: cubit.currentUserName,
        currentUserImageUrl: cubit.senderImageUrl,
        receiver: widget.receiverUser,
      ),
      onRemoveReaction:
          (emoji) => cubit.toggleReaction(
            messageId: widget.message.id,
            receiverId: partnerId,
            emoji: emoji,
          ),
      onOpenProfile:
          (userId) => Navigator.of(
            context,
            rootNavigator: true,
          ).pushNamed(AppRoutes.profileViewRoute, arguments: userId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenCap = MediaQuery.of(context).size.width * 0.70;
        final double maxBubbleWidth =
            constraints.maxWidth < screenCap ? constraints.maxWidth : screenCap;

        return _buildContent(context, maxBubbleWidth);
      },
    );
  }

  Widget _buildContent(BuildContext context, double maxBubbleWidth) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final bool isUploading = widget.isMe && widget.uploadProgress != null;
    final bool isImage = widget.message.messageType == 'image';
    final bool isVideo = widget.message.messageType == 'video';
    final bool isGif = widget.message.messageType == 'gif';
    final bool isSticker = widget.message.messageType == 'sticker';
    final bool isVoice = widget.message.messageType == 'voice';
    final bool isFile = widget.message.messageType == 'file';
    final bool isCall = widget.message.messageType == 'call';

    final bool hasReaction = widget.message.reactions.isNotEmpty;
    final bool isStickerOrGif =
        widget.message.messageType == 'gif' ||
        widget.message.messageType == 'sticker';

    if (isCall) {
      return CallMessageContent(
        message: widget.message,
        isMe: widget.isMe,
        hasReaction: hasReaction,
        maxBubbleWidth: maxBubbleWidth,
      );
    }

    final regularContent = RegularMessageContent(
      message: widget.message,
      isMe: widget.isMe,
      isImage: isImage,
      isVideo: isVideo,
      isGif: isGif,
      isSticker: isSticker,
      itemScrollController: widget.itemScrollController,
      isUploading: isUploading,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: EdgeInsets.only(
            top: 2,
            left: 0,
            right: 0,
            bottom: hasReaction ? 28 : 2,
          ),
          padding:
              isStickerOrGif
                  ? EdgeInsets.zero
                  : (isImage || isVideo)
                  ? const EdgeInsets.all(3)
                  : const EdgeInsets.only(
                    left: 10,
                    right: 10,
                    bottom: 8,
                    top: 6,
                  ),
          constraints: BoxConstraints(
            maxWidth: maxBubbleWidth,
            minWidth:
                isVoice
                    ? (280 > maxBubbleWidth ? maxBubbleWidth : 280)
                    : (isImage || isVideo ? 200 : 40),
          ),
          decoration: BoxDecoration(
            color:
                isStickerOrGif
                    ? Colors.transparent
                    : (isImage || isVideo) &&
                        (widget.message.imageUrl == null &&
                            widget.message.videoUrl == null)
                    ? AppColors.transparent
                    : (widget.isMe
                        ? Theme.of(context).primaryColor
                        : (isDarkMode
                            ? Theme.of(context).colorScheme.surfaceContainerHigh
                            : Colors.grey.shade200)),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(widget.isMe ? 20 : 0),
              bottomRight: Radius.circular(widget.isMe ? 0 : 20),
            ),
            boxShadow:
                (isUploading && !isFile) || isStickerOrGif
                    ? []
                    : [
                      BoxShadow(color: AppColors.grey1.withValues(alpha: 0.8)),
                    ],
          ),
          child: Opacity(
            opacity: 1,
            child:
                widget.message.isForwarded
                    ? IntrinsicWidth(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ForwardedHeader(
                            name:
                                widget.message.forwardedFromUserName ??
                                'Unknown',
                            avatarUrl: widget.message.forwardedFromUserAvatar,
                            originalSenderId:
                                widget.message.forwardedFromUserId ?? '',
                            onColoredBubble: widget.isMe && !isStickerOrGif,
                          ),
                          regularContent,
                        ],
                      ),
                    )
                    : regularContent,
          ),
        ),

        if (isUploading && !isVoice && !isFile)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(widget.isMe ? 20 : 0),
                bottomRight: Radius.circular(widget.isMe ? 0 : 20),
              ),
              child: ValueListenableBuilder<double>(
                valueListenable: context
                    .read<ChatDetailsCubit>()
                    .progressNotifierFor(widget.message.id),
                builder: (
                  BuildContext context,
                  double progress,
                  Widget? child,
                ) {
                  return MediaStateOverlay(
                    state: MediaTransferState.uploading(progress),
                    isVideo: widget.message.messageType == 'video',
                    durationSeconds: widget.message.durationSeconds,
                    fileSizeBytes: widget.message.fileSizeBytes,
                    onCancelTap:
                        () => context.read<ChatDetailsCubit>().cancelUpload(
                          widget.message.id,
                        ),
                    child: const SizedBox.shrink(),
                  );
                },
              ),
            ),
          ),

        if (hasReaction)
          Positioned(
            bottom: -2.5,
            right: widget.isMe ? 8 : null,
            left: widget.isMe ? null : 8,
            child: MessageReactionsRow(
              reactions: widget.message.reactions,
              currentUserId: context.read<ChatDetailsCubit>().currentUserId,
              primary: Theme.of(context).primaryColor,
              onTap: () => _openReactionsSheet(context),
            ),
          ),
      ],
    );
  }
}
