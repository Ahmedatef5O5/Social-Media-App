import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../core/helpers/modern_circle_progress.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/themes/app_colors.dart';
import '../cubit/group_details_cubit/group_details_cubit.dart';
import '../models/groupe_message_model.dart';
import 'group_call_message_content.dart';
import 'group_chat_reaction_overlay.dart';
import 'group_message_avatar.dart';
import 'group_reactions_row_widget.dart';
import 'group_regular_message_content.dart';

class GroupMessageContent extends StatefulWidget {
  final GroupMessageModel message;
  final bool isMe;
  final Function(GroupMessageModel) onReply;
  final Function(GroupMessageModel)? onEdit;
  final VoidCallback? onLongPress;
  final ItemScrollController itemScrollController;

  const GroupMessageContent({
    super.key,
    required this.message,
    required this.isMe,
    required this.onReply,
    this.onEdit,
    this.onLongPress,
    required this.itemScrollController,
  });

  @override
  State<GroupMessageContent> createState() => _GroupMessageContentState();
}

class _GroupMessageContentState extends State<GroupMessageContent> {
  final _anchorKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GroupDetailsCubit>();

    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final currentUserId = SupabaseProvider.id;

    final isImage = widget.message.messageType == 'image';
    final isVideo = widget.message.messageType == 'video';
    final isVoice = widget.message.messageType == 'voice';
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

        return ValueListenableBuilder<String?>(
          valueListenable: cubit.highlightedMessageId,
          builder: (context, highlightId, _) {
            final isHighlighted = highlightId == widget.message.id;
            final highlightColor = Theme.of(
              context,
            ).primaryColor.withValues(alpha: widget.isMe ? 0.12 : 0.2);

            return GestureDetector(
              onLongPress:
                  isCall
                      ? null
                      : () => GroupChatReactionOverlay.show(
                        context: context,
                        anchorKey: _anchorKey,
                        message: widget.message,
                        onReply: widget.onReply,
                        onEdit:
                            (widget.isMe &&
                                        widget.message.messageType == 'text' ||
                                    widget.message.caption != null)
                                ? widget.onEdit
                                : null,

                        primary: primary,
                        isMe: widget.isMe,
                      ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: isHighlighted ? highlightColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment:
                      widget.isMe
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!widget.isMe) ...[
                      GroupMessageAvatar(
                        message: widget.message,
                        primary: primary,
                      ),
                      const Gap(8),
                    ],
                    Flexible(
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
                                ),
                              ),
                          ],
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

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Opacity(
          opacity: isUploading ? 0.4 : 1.0,
          child: Container(
            margin: EdgeInsets.only(top: 2, bottom: hasReaction ? 28 : 2),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.70,
              minWidth: isVoice ? 240 : (isImage || isVideo ? 200 : 50),
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
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(widget.isMe ? 20 : 0),
                bottomRight: Radius.circular(widget.isMe ? 0 : 20),
              ),
              child: Padding(
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
                child: content,
              ),
            ),
          ),
        ),

        if (isUploading)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(widget.isMe ? 18 : 4),
                bottomRight: Radius.circular(widget.isMe ? 4 : 18),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.15),
                  child: Center(
                    child: ModernCircularProgress(
                      progress: uploadProgress ?? 0.0,
                      size: 90,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
