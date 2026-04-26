import 'dart:convert';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/helpers/modern_circle_progress.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/reaction_picker_overlay.dart';
import '../../chats/widgets/video_message_widget.dart';
import '../../chats/widgets/voice_message_bubble_widget.dart';
import '../cubit/group_details_cubit/group_details_cubit.dart';
import '../cubit/group_details_cubit/group_details_state.dart';
import '../models/groupe_message_model.dart';
import 'group_chat_reaction_overlay.dart';
import 'group_message_avatar.dart';
import 'group_message_reply_preview.dart';
import 'group_reactions_row_widget.dart';
import 'group_time_row.dart';

class GroupMessageBubble extends StatefulWidget {
  final GroupMessageModel message;
  final bool isMe;
  final Function(GroupMessageModel) onReply;

  const GroupMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.onReply,
  });

  @override
  State<GroupMessageBubble> createState() => _GroupMessageBubbleState();
}

class _GroupMessageBubbleState extends State<GroupMessageBubble> {
  OverlayEntry? _overlayEntry;
  final GlobalKey _bubbleKey = GlobalKey();

  @override
  void dispose() {
    _dismissPicker();
    super.dispose();
  }

  void _showPicker() {
    if (_overlayEntry != null) return;

    final currentUserId = Supabase.instance.client.auth.currentUser!.id;
    final myReaction = widget.message.reactions[currentUserId];

    final isCall = widget.message.messageType == 'call';
    if (isCall) return;

    try {
      _overlayEntry = ChatReactionOverlay.create(
        context: context,
        anchorKey: _bubbleKey,
        isMe: widget.isMe,
        selectedEmoji: myReaction,
        onSelect: (emoji) {
          _dismissPicker();
          HapticFeedback.selectionClick();
          context.read<GroupDetailsCubit>().toggleReaction(
            messageId: widget.message.id,
            emoji: emoji,
          );
        },
        onDismiss: _dismissPicker,
      );
      Overlay.of(context).insert(_overlayEntry!);
      setState(() {});
    } catch (_) {}
  }

  void _dismissPicker() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _bubbleKey,
      child: GroupMessageContent(
        message: widget.message,
        isMe: widget.isMe,
        onReply: widget.onReply,
        onLongPress: _showPicker,
      ),
    );
  }
}

class GroupMessageContent extends StatefulWidget {
  final GroupMessageModel message;
  final bool isMe;
  final Function(GroupMessageModel) onReply;
  final VoidCallback? onLongPress;

  const GroupMessageContent({
    super.key,
    required this.message,
    required this.isMe,
    required this.onReply,
    this.onLongPress,
  });

  @override
  State<GroupMessageContent> createState() => _GroupMessageContentState();
}

class _GroupMessageContentState extends State<GroupMessageContent> {
  final _anchorKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;

    final isImage = widget.message.messageType == 'image';
    final isVideo = widget.message.messageType == 'video';
    final isVoice = widget.message.messageType == 'voice';
    final isCall = widget.message.messageType == 'call';

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

        return GestureDetector(
          onLongPress:
              () => GroupChatReactionOverlay.show(
                context: context,
                anchorKey: _anchorKey,
                message: widget.message,
                onReply: widget.onReply,
                primary: primary,
                isMe: widget.isMe,
              ),
          // onLongPress ??
          // () => GroupMessageMenuSheet.show(
          //   context: context,
          //   message: message,
          //   onReply: onReply,
          //   primary: primary,
          // ),
          child: Row(
            mainAxisAlignment:
                widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!widget.isMe) ...[
                GroupMessageAvatar(
                  avatar: widget.message.senderAvatar,
                  name: widget.message.senderName,
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
                        isUploading: isUploading,
                        uploadProgress: uploadProgress,
                      ),

                      if (widget.message.reactions.isNotEmpty)
                        Positioned(
                          bottom: 12.0,
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
    required bool isUploading,
    double? uploadProgress,
  }) {
    final hasReaction = widget.message.reactions.isNotEmpty;
    final timeWidget = GroupTimeRow(message: widget.message, isMe: widget.isMe);

    Widget content;
    if (isCall) {
      content = _buildCallBubble(context, textColor, timeWidget, primary);
    } else if (isVoice) {
      content = _buildVoiceBubble(context, timeWidget);
    } else if (isImage) {
      content = _buildImageBubble(context, textColor, timeWidget);
    } else if (isVideo) {
      content = _buildVideoBubble(context, textColor, timeWidget);
    } else {
      content = _buildTextBubble(context, textColor, timeWidget, primary);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Opacity(
          opacity: isUploading ? 0.4 : 1.0,
          child: Container(
            margin: EdgeInsets.only(
              top: 2,
              bottom: hasReaction ? 28 : 2,
            ), // ← 28 بدل 18 زي single chat
            constraints: BoxConstraints(
              maxWidth:
                  MediaQuery.of(context).size.width * 0.70, // ← 0.70 بدل 0.68
              minWidth: isVoice ? 240 : (isImage || isVideo ? 200 : 50),
            ),
            decoration: BoxDecoration(
              color:
                  (isImage || isVideo) &&
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
                    (isImage || isVideo)
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
        // Upload progress overlay
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

  Widget _buildTextBubble(
    BuildContext context,
    Color textColor,
    Widget timeWidget,
    Color primary,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.isMe)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                widget.message.senderName,
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          if (widget.message.replyToMessageId != null)
            GroupMessageReplyPreview(
              message: widget.message,
              isMe: widget.isMe,
              primary: primary,
            ),
          if (widget.message.text.isNotEmpty)
            Text(
              widget.message.text,
              style: TextStyle(color: textColor, fontSize: 15, height: 1.3),
            ),
          const Gap(2),
          Align(alignment: Alignment.bottomRight, child: timeWidget),
        ],
      ),
    );
  }

  Widget _buildImageBubble(
    BuildContext context,
    Color textColor,
    Widget timeWidget,
  ) {
    if (widget.message.imageUrl == null) {
      return Container(
        width: 200,
        height: 200,
        color: Colors.grey.shade800,
        child: const Center(
          child: Icon(Icons.image, color: Colors.white54, size: 48),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _openFullscreenImage(context, widget.message.imageUrl!),
          child: CachedNetworkImage(
            imageUrl: widget.message.imageUrl!,
            width: 260,
            height: 260,
            fit: BoxFit.cover,
            placeholder:
                (_, __) => Container(
                  width: 260,
                  height: 260,
                  color: Colors.grey.shade300,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            errorWidget:
                (_, __, ___) => Container(
                  width: 260,
                  height: 260,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.broken_image, size: 48),
                ),
          ),
        ),
        if (widget.message.caption?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
            child: Text(
              widget.message.caption!,
              style: TextStyle(color: textColor, fontSize: 13),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
          child: Align(alignment: Alignment.bottomRight, child: timeWidget),
        ),
      ],
    );
  }

  void _openFullscreenImage(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(backgroundColor: Colors.black),
              body: Center(
                child: InteractiveViewer(
                  child: CachedNetworkImage(imageUrl: url),
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildVideoBubble(
    BuildContext context,
    Color textColor,
    Widget timeWidget,
  ) {
    if (widget.message.videoUrl == null) {
      return Container(
        width: 200,
        height: 150,
        color: Colors.grey.shade800,
        child: const Center(
          child: Icon(Icons.videocam, color: Colors.white54, size: 48),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 200,
          width: 260,
          child: VideoMessageWidget(
            videoUrl: widget.message.videoUrl!,
            caption: widget.message.caption,
            isMe: widget.isMe,
          ),
        ),
        if (widget.message.caption?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
            child: Text(
              widget.message.caption!,
              style: TextStyle(color: textColor, fontSize: 13),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
          child: Align(alignment: Alignment.bottomRight, child: timeWidget),
        ),
      ],
    );
  }

  Widget _buildVoiceBubble(BuildContext context, Widget timeWidget) {
    if (widget.message.voiceUrl == null) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          '🎤 Voice message',
          style: TextStyle(color: Colors.white60),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.isMe)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                widget.message.senderName,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          VoiceMessageBubbleWidget(
            voiceUrl: widget.message.voiceUrl!,
            isMe: widget.isMe,
            timestamp: widget.message.createdAt,
            isRead: false,
          ),
        ],
      ),
    );
  }

  Widget _buildCallBubble(
    BuildContext context,
    Color textColor,
    Widget timeWidget,
    Color primary,
  ) {
    Map<String, dynamic> callData = {};
    try {
      callData = jsonDecode(widget.message.text) as Map<String, dynamic>;
    } catch (_) {}

    final status = callData['status'] as String? ?? 'ended';
    final callType = callData['call_type'] as String? ?? 'audio';
    final duration = callData['duration'] as String? ?? '';
    final isAudio = callType == 'audio';
    final isMissed = status == 'rejected' || status == 'missed';

    final IconData icon =
        isMissed
            ? (isAudio ? Icons.call_missed : Icons.missed_video_call)
            : (isAudio ? Icons.call : Icons.videocam);
    final Color iconColor =
        isMissed ? Colors.redAccent.shade100 : Colors.greenAccent.shade100;
    String label =
        isMissed
            ? (isAudio ? 'Missed voice call' : 'Missed video call')
            : (isAudio ? 'Voice call' : 'Video call');
    if (duration.isNotEmpty && !isMissed) label += ' • $duration';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.isMe)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                widget.message.senderName,
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: 20),
              const Gap(8),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Gap(4),
          Align(alignment: Alignment.bottomRight, child: timeWidget),
        ],
      ),
    );
  }
}
