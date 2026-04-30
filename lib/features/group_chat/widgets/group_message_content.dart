import 'dart:convert';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/features/group_chat/widgets/group_voice_message_bubble.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/helpers/modern_circle_progress.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/reaction_picker_overlay.dart';
import '../../calls/views/zego_group_call_view.dart';
import '../../chats/widgets/image_message_widget.dart';
import '../../chats/widgets/video_message_widget.dart';
import '../cubit/group_details_cubit/group_details_cubit.dart';
import '../cubit/group_details_cubit/group_details_state.dart';
import '../models/group_call_model.dart';
import '../models/groupe_message_model.dart';
import '../services/group_call_signaling_service.dart';
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
    if (widget.message.messageType == 'call') return;

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
          child: Row(
            mainAxisAlignment:
                widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!widget.isMe) ...[
                GroupMessageAvatar(message: widget.message, primary: primary),
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
    final hasReactions =
        widget.message.reactions != null && widget.message.reactions.isNotEmpty;

    final timeWidget = GroupTimeRow(message: widget.message, isMe: widget.isMe);
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;
    final displayText = widget.message.caption ?? widget.message.text;

    double minBubbleWidth = 0;
    if (hasReactions) {
      final uniqueEmojis = widget.message.reactions.values.toSet().length;

      minBubbleWidth = (uniqueEmojis * 36.0) + 24.0;

      final maxWidth = MediaQuery.of(context).size.width * 0.75;
      minBubbleWidth = minBubbleWidth.clamp(0.0, maxWidth);
    }

    Widget content;

    if (isCall) {
      content = _buildCallBubble(context, textColor, timeWidget, primary);
    } else {
      content = IntrinsicWidth(
        child: Container(
          constraints: BoxConstraints(minWidth: minBubbleWidth),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.message.replyToMessageId != null)
                GestureDetector(
                  onTap: () {
                    // _navigateToOriginalMessage(
                    //   context,
                    //   widget.message.replyToMessageId!,
                    // );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: GroupReplyBubblePreview(
                      message: widget.message,
                      isMe: widget.isMe,
                      currentUserId: currentUserId,
                    ),
                  ),
                ),

              if (!widget.isMe)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    widget.message.senderName,
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),

              if (isImage)
                SizedBox(
                  width: 305,
                  height: 320,
                  child:
                      widget.message.imageUrl != null
                          ? ImageMessageWidget(
                            imageUrl: widget.message.imageUrl!,
                            caption: widget.message.caption,
                            isMe: widget.isMe,
                          )
                          : const SizedBox.shrink(),
                ),

              if (isVideo)
                SizedBox(
                  height: 200,
                  width: 280,
                  child:
                      widget.message.videoUrl != null
                          ? VideoMessageWidget(
                            videoUrl: widget.message.videoUrl!,
                            caption: widget.message.caption,
                            isMe: widget.isMe,
                          )
                          : const SizedBox.shrink(),
                ),

              if (isVoice)
                GroupVoiceMessageBubbleWidget(
                  voiceUrl: widget.message.voiceUrl ?? '',
                  isMe: widget.isMe,
                  timestamp: widget.message.createdAt,
                  isUploading: isUploading,
                ),

              if (displayText.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: (isImage || isVideo) ? 8 : 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayText,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          height: 1.3,
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: timeWidget,
                      ),
                    ],
                  ),
                ),

              if (displayText.isEmpty && (isImage || isVideo))
                Align(alignment: Alignment.bottomRight, child: timeWidget),
            ],
          ),
        ),
      );
    }

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

  Widget _buildCallBubble(
    BuildContext context,
    Color textColor,
    Widget timeWidget,
    Color primary,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Map<String, dynamic> initialData = {};
    try {
      final txt = widget.message.text.trim();
      if (txt.startsWith('{')) {
        initialData = jsonDecode(txt) as Map<String, dynamic>;
      }
    } catch (_) {}

    final isTemp = widget.message.id.startsWith('temp_');
    if (isTemp) {
      return _buildCallBubbleContent(
        context,
        initialData,
        textColor,
        timeWidget,
        primary,
        isDark,
      );
    }

    return StreamBuilder<Map<String, dynamic>?>(
      stream: _watchCallData(),
      initialData: initialData.isNotEmpty ? initialData : null,
      builder: (context, snapshot) {
        final callData =
            snapshot.data ?? (initialData.isNotEmpty ? initialData : {});

        return _buildCallBubbleContent(
          context,
          callData,
          textColor,
          timeWidget,
          primary,
          isDark,
        );
      },
    );
  }

  Stream<Map<String, dynamic>?> _watchCallData() {
    return Supabase.instance.client
        .from('group_messages')
        .stream(primaryKey: ['id'])
        .eq('id', widget.message.id)
        .map((list) {
          if (list.isEmpty) return null;
          try {
            final msgText = list.first['message_text'] as String? ?? '';
            if (msgText.trim().startsWith('{')) {
              return jsonDecode(msgText) as Map<String, dynamic>;
            }
          } catch (_) {}
          return null;
        });
  }

  Widget _buildCallBubbleContent(
    BuildContext context,
    Map<String, dynamic> callData,
    Color textColor,
    Widget timeWidget,
    Color primary,
    bool isDark,
  ) {
    final status = callData['status'] as String? ?? 'ended';
    final callType = callData['call_type'] as String? ?? 'audio';

    final rawDuration = callData['duration'];
    final duration =
        (rawDuration is String && rawDuration.isNotEmpty) ? rawDuration : '';

    final callId = callData['call_id'] as String? ?? '';
    final groupId = callData['group_id'] as String? ?? '';
    final initiatorAvatar = callData['initiator_avatar'] as String?;
    final initiatorName = callData['initiator_name'] as String?;
    final groupAvatarUrl = callData['group_avatar_url'] as String?;

    final isAudio = callType == 'audio';
    final isMissed = status == 'missed';
    final isEnded = status == 'ended';
    final isOngoing =
        status == 'ringing' || status == 'accepted' || status == 'ongoing';

    final bubbleBg =
        widget.isMe
            ? primary
            : (isDark
                ? Colors.white.withOpacity(0.09)
                : primary.withOpacity(0.08));

    final labelColor =
        widget.isMe ? Colors.white : (isDark ? Colors.white70 : Colors.black87);
    final subColor =
        widget.isMe
            ? Colors.white70
            : (isDark ? Colors.white54 : Colors.black45);
    final iconColor = isMissed ? Colors.redAccent.shade100 : Colors.greenAccent;

    final IconData callIcon =
        isMissed
            ? (isAudio
                ? Icons.call_missed_rounded
                : Icons.missed_video_call_rounded)
            : (isAudio ? Icons.call_rounded : Icons.videocam_rounded);

    final String callLabel =
        isMissed
            ? (isAudio ? 'Missed voice call' : 'Missed video call')
            : (isAudio ? 'Group voice call' : 'Group video call');

    return Container(
      constraints: const BoxConstraints(minWidth: 210, maxWidth: 270),
      decoration: BoxDecoration(
        color: bubbleBg,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(widget.isMe ? 18 : 4),
          bottomRight: Radius.circular(widget.isMe ? 4 : 18),
        ),
        border:
            !widget.isMe
                ? Border.all(
                  color: primary.withOpacity(isDark ? 0.2 : 0.12),
                  width: 1,
                )
                : null,
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.isMe)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildGroupAvatar(groupAvatarUrl, primary),
              const SizedBox(width: 10),

              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(callIcon, color: iconColor, size: 17),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            callLabel,
                            style: TextStyle(
                              color: labelColor,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (isEnded && duration.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_outlined, size: 11, color: subColor),
                          const SizedBox(width: 4),
                          Text(
                            duration,
                            style: TextStyle(color: subColor, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ] else if (isOngoing) ...[
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Ongoing',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          if (isOngoing && groupId.isNotEmpty && callId.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildJoinButton(context, callId, groupId, callType, primary),
          ],

          const SizedBox(height: 4),
          Align(
            alignment: Alignment.bottomRight,
            child: _buildLocalTimeWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupAvatar(String? groupAvatarUrl, Color primary) {
    const double size = 40;
    final hasAvatar = groupAvatarUrl != null && groupAvatarUrl.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: primary.withOpacity(0.15),
        border: Border.all(color: primary.withOpacity(0.35), width: 1.5),
      ),
      child: ClipOval(
        child:
            hasAvatar
                ? CachedNetworkImage(
                  imageUrl: groupAvatarUrl,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorWidget:
                      (_, __, ___) => _groupAvatarFallback(primary, size),
                )
                : _groupAvatarFallback(primary, size),
      ),
    );
  }

  Widget _groupAvatarFallback(Color primary, double size) {
    return Container(
      width: size,
      height: size,
      color: primary.withOpacity(0.12),
      child: Center(
        child: Icon(Icons.group_rounded, color: primary, size: size * 0.55),
      ),
    );
  }

  Widget _buildLocalTimeWidget() {
    final localTime = widget.message.createdAt.toLocal();
    final hour = localTime.hour.toString().padLeft(2, '0');
    final minute = localTime.minute.toString().padLeft(2, '0');
    return Text(
      '$hour:$minute',
      style: TextStyle(
        fontSize: 10,
        color: widget.isMe ? Colors.white60 : Colors.black38,
      ),
    );
  }

  Widget _buildJoinButton(
    BuildContext context,
    String callId,
    String groupId,
    String callType,
    Color primary,
  ) {
    return StreamBuilder<GroupCallModel?>(
      stream: GroupCallSignalingService().activeCallStream(groupId),
      builder: (context, snapshot) {
        final activeCall = snapshot.data;
        if (activeCall == null) return const SizedBox.shrink();
        if (activeCall.callId != callId) return const SizedBox.shrink();

        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        if (activeCall.initiatorId == currentUserId) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () async {
            final signaling = GroupCallSignalingService();
            final joined = await signaling.acceptCall(activeCall.callId);
            final user = Supabase.instance.client.auth.currentUser!;
            final profile =
                await Supabase.instance.client
                    .from('users')
                    .select('name')
                    .eq('id', user.id)
                    .maybeSingle();
            final userName = (profile?['name'] as String?) ?? 'Me';
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => ZegoGroupCallView(
                        call: joined,
                        currentUserId: user.id,
                        currentUserName: userName,
                      ),
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.green.shade500,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  callType == 'video'
                      ? Icons.videocam_rounded
                      : Icons.call_rounded,
                  color: Colors.white,
                  size: 15,
                ),
                const SizedBox(width: 5),
                const Text(
                  'Tap to Join',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
