import 'dart:convert';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/helpers/formatted_date.dart';
import '../../../core/helpers/modern_circle_progress.dart';
import '../../../core/themes/app_colors.dart';
import '../../chats/widgets/video_message_widget.dart';
import '../../chats/widgets/voice_message_bubble_widget.dart';
import '../cubit/group_details_cubit/group_details_cubit.dart';
import '../cubit/group_details_cubit/group_details_state.dart';
import '../models/groupe_message_model.dart';
import 'group_message_avatar.dart';
import 'group_message_menu_sheet.dart';
import 'group_message_reply_preview.dart';
import 'group_reactions_row_widget.dart';

class GroupMessageBubble extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GroupMessageContent(message: message, isMe: isMe, onReply: onReply);
  }
}

// ─── Full message content (with all types + progress) ────────────────────────

class GroupMessageContent extends StatelessWidget {
  final GroupMessageModel message;
  final bool isMe;
  final Function(GroupMessageModel) onReply;

  const GroupMessageContent({
    super.key,
    required this.message,
    required this.isMe,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;

    final isImage = message.messageType == 'image';
    final isVideo = message.messageType == 'video';
    final isVoice = message.messageType == 'voice';
    final isCall = message.messageType == 'call';

    final bgColor =
        isMe
            ? primary
            : (isDark
                ? Colors.white.withValues(alpha: 0.10)
                : AppColors.grey3.withValues(alpha: 0.35));

    final textColor =
        isMe ? Colors.white : (isDark ? Colors.white : AppColors.black87);

    // ── Upload progress from cubit state ──────────────────────────
    return BlocBuilder<GroupDetailsCubit, GroupDetailsState>(
      buildWhen: (prev, cur) {
        if (cur is GroupDetailsLoaded && prev is GroupDetailsLoaded) {
          final hadPrev = prev.uploadProgress.containsKey(message.id);
          final hasCur = cur.uploadProgress.containsKey(message.id);
          return hadPrev != hasCur ||
              prev.uploadProgress[message.id] != cur.uploadProgress[message.id];
        }
        return false;
      },
      builder: (context, state) {
        final double? uploadProgress =
            (state is GroupDetailsLoaded && isMe)
                ? state.uploadProgress[message.id]
                : null;
        final bool isUploading = uploadProgress != null;

        return GestureDetector(
          onLongPress:
              () => GroupMessageMenuSheet.show(
                context: context,
                message: message,
                onReply: onReply,
                primary: primary,
              ),
          child: Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Avatar for others
              if (!isMe) ...[
                GroupMessageAvatar(
                  avatar: message.senderAvatar,
                  name: message.senderName,
                  primary: primary,
                ),
                const Gap(8),
              ],

              // Bubble
              Flexible(
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

                    // Reactions row
                    if (message.reactions.isNotEmpty)
                      Positioned(
                        bottom: -14,
                        right: isMe ? 4 : null,
                        left: isMe ? null : 4,
                        child: GroupReactionsRow(
                          reactions: message.reactions,
                          currentUserId: currentUserId,
                          primary: primary,
                        ),
                      ),
                  ],
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
    final hasReaction = message.reactions.isNotEmpty;
    final timeWidget = _TimeRow(message: message, isMe: isMe);

    Widget content;

    if (isCall) {
      content = _buildCallBubble(context, textColor, timeWidget);
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
            margin: EdgeInsets.only(top: 2, bottom: hasReaction ? 20 : 2),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.68,
              minWidth: isVoice ? 240 : (isImage || isVideo ? 160 : 50),
            ),
            decoration: BoxDecoration(
              color:
                  (isImage || isVideo) &&
                          !isUploading &&
                          (message.imageUrl == null && message.videoUrl == null)
                      ? Colors.transparent
                      : bgColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
              child: content,
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
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
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

  // ── Text bubble ──────────────────────────────────────────────────

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
          // Sender name (only for others)
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                message.senderName,
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),

          // Reply preview
          if (message.replyToMessageId != null)
            GroupMessageReplyPreview(
              message: message,
              isMe: isMe,
              primary: primary,
            ),

          // Message text
          if (message.text.isNotEmpty)
            Text(
              message.text,
              style: TextStyle(color: textColor, fontSize: 15, height: 1.3),
            ),

          const Gap(2),
          Align(alignment: Alignment.bottomRight, child: timeWidget),
        ],
      ),
    );
  }

  // ── Image bubble ─────────────────────────────────────────────────

  Widget _buildImageBubble(
    BuildContext context,
    Color textColor,
    Widget timeWidget,
  ) {
    if (message.imageUrl == null) {
      // Still uploading — placeholder
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
          onTap: () => _openFullscreenImage(context, message.imageUrl!),
          child: CachedNetworkImage(
            imageUrl: message.imageUrl!,
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
        if (message.caption?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
            child: Text(
              message.caption!,
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

  // ── Video bubble ─────────────────────────────────────────────────

  Widget _buildVideoBubble(
    BuildContext context,
    Color textColor,
    Widget timeWidget,
  ) {
    if (message.videoUrl == null) {
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
            videoUrl: message.videoUrl!,
            caption: message.caption,
            isMe: isMe,
          ),
        ),
        if (message.caption?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
            child: Text(
              message.caption!,
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

  // ── Voice bubble ─────────────────────────────────────────────────

  Widget _buildVoiceBubble(BuildContext context, Widget timeWidget) {
    if (message.voiceUrl == null) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          '🎤 Voice message',
          style: TextStyle(color: Colors.white60),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(6),
      child: VoiceMessageBubbleWidget(
        voiceUrl: message.voiceUrl!,
        isMe: isMe,
        timestamp: message.createdAt,
        isRead: false,
      ),
    );
  }

  // ── Call bubble ──────────────────────────────────────────────────

  Widget _buildCallBubble(
    BuildContext context,
    Color textColor,
    Widget timeWidget,
  ) {
    Map<String, dynamic> callData = {};
    try {
      callData = jsonDecode(message.text) as Map<String, dynamic>;
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

    final Color iconColor = isMissed ? Colors.redAccent : Colors.greenAccent;

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
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                message.senderName,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
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

// ── Time + read indicator ─────────────────────────────────────────────────────

class _TimeRow extends StatelessWidget {
  final GroupMessageModel message;
  final bool isMe;
  const _TimeRow({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Text(
      FormattedDate.getMessageTime(message.createdAt),
      style: TextStyle(
        fontSize: 10,
        color: isMe ? Colors.white60 : AppColors.black38,
      ),
    );
  }
}
