import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import '../../../core/chat_shared/cubits/conversation_selection_cubit/conversation_selection_cubit.dart';
import '../../../core/chat_shared/models/conversation_ref.dart';
import '../../../core/chat_shared/widgets/recording_indicator_widget.dart';
import '../../../core/design/tokens/typography.dart';
import '../../../core/helpers/bidi_text_helper.dart';
import '../../../core/helpers/emoji_helper.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/presence/widgets/presence_avatar_widget.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/animated_activity_text.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../profile/widgets/user_preview_dialog.dart';
import '../models/chat_user_model.dart';

class ChatItemTile extends StatelessWidget {
  final ChatUserModel user;
  final bool isPinned;
  final bool isFavorite;
  final bool isMuted;
  final bool enableHero;

  const ChatItemTile({
    super.key,
    required this.user,
    this.isPinned = false,
    this.isFavorite = false,
    this.isMuted = false,
    this.enableHero = true,
  });

  bool get _isSystemEventPreview =>
      user.lastMessageType == 'block_event' ||
      user.lastMessageType == 'unblock_event';

  @override
  Widget build(BuildContext context) {
    final ref = ConversationRef(type: ConversationType.single, id: user.id);

    return BlocBuilder<ConversationSelectionCubit, ConversationSelectionState>(
      builder: (context, selection) {
        final isSelecting = selection.isSelecting;
        final isSelected = selection.isSelected(ref);
        final primary = Theme.of(context).primaryColor;

        return Material(
          color:
              isSelected ? primary.withValues(alpha: 0.08) : Colors.transparent,
          child: InkWell(
            onLongPress:
                () => context.read<ConversationSelectionCubit>().toggle(ref),
            onTap: () {
              if (isSelecting) {
                context.read<ConversationSelectionCubit>().toggle(ref);
                return;
              }
              Navigator.of(
                context,
                rootNavigator: true,
              ).pushNamed(AppRoutes.chatDetailsViewRoute, arguments: user);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildUserAvatar(context, isSelecting, isSelected, primary),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: _buildUserName(context)),
                            const Gap(8),
                            if (user.lastMessageTime != null)
                              _buildTimeText(context, primary),
                          ],
                        ),
                        const Gap(4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: _buildLastMessage(context)),
                            const Gap(8),
                            _buildIconsSection(context, primary),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeText(BuildContext context, Color primary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUnread = user.unreadCount > 0;
    return Text(
      FormattedDate.getChatTime(user.lastMessageTime!, isChatList: true),
      style: TextStyle(
        color: isUnread ? primary : (isDark ? Colors.white38 : Colors.black38),
        fontSize: 11,
        fontWeight: isUnread ? FontWeight.w500 : FontWeight.w400,
      ),
    );
  }

  Widget _buildIconsSection(BuildContext context, Color primary) {
    final hasStatusRow =
        isFavorite || isPinned || isMuted || user.unreadCount > 0;

    if (!hasStatusRow) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (isFavorite) ...[
          Icon(Icons.star_rounded, size: 16, color: Colors.amber.shade600),
          const Gap(4),
        ],
        if (isPinned) ...[
          const Icon(Icons.push_pin_rounded, size: 15, color: Colors.grey),
          const Gap(4),
        ],
        if (isMuted) ...[
          const FaIcon(
            FontAwesomeIcons.bellSlash,
            size: 12,
            color: Colors.grey,
          ),
          if (user.unreadCount > 0) const Gap(4),
        ],
        if (user.unreadCount > 0)
          Container(
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                user.unreadCount > 99 ? '99+' : '${user.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _getNormalMessageText() {
    switch (user.lastMessageType) {
      case 'image':
        return '📷 Photo';
      case 'video':
        return '🎥 Video';
      case 'voice':
        return '🎤 Voice message';
      case 'gif':
        return '🎞️ GIF';
      case 'sticker':
        return '😊 Sticker';
      case 'file':
        return '📄 ${user.lastMessageType ?? 'File'}';
      case 'block_event':
        return user.lastMessageIsMe
            ? 'You blocked ${user.name}'
            : '${user.name} blocked you';
      case 'unblock_event':
        return user.lastMessageIsMe
            ? 'You unblocked ${user.name}'
            : '${user.name} unblocked you';
      default:
        return (user.lastMessage == null || user.lastMessage!.isEmpty)
            ? 'No messages yet'
            // ? 'Tap to start chatting'
            : user.lastMessage!;
    }
  }

  Widget _buildMessagePreview(BuildContext context) {
    final bool isUnread = user.unreadCount > 0;
    final textStyle =
        (Theme.of(context).textTheme.labelSmall ?? const TextStyle()).copyWith(
          fontWeight: isUnread ? FontWeight.w500 : FontWeight.w400,
          fontSize: 13,
          fontFamily: null,
          fontFamilyFallback: AppTypography.fontFallback,
          color:
              isUnread
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.grey.shade600,
        );

    if (user.lastMessageType == 'call') {
      Map<String, dynamic> callData = {};
      try {
        if (user.lastMessage != null) {
          callData = jsonDecode(user.lastMessage!) as Map<String, dynamic>;
        }
      } catch (_) {}

      final status = callData['status'] as String? ?? 'ended';
      final callType = callData['call_type'] as String? ?? 'audio';

      final bool isAudio = callType == 'audio';
      final bool isMissed = status == 'rejected' || status == 'missed';

      final IconData icon =
          isMissed
              ? (isAudio ? Icons.call_missed : Icons.missed_video_call)
              : (isAudio ? Icons.call : Icons.videocam);

      final Color iconColor =
          isMissed ? Colors.redAccent : Colors.grey.shade600;
      final String label =
          isMissed
              ? (isAudio ? 'Missed voice call' : 'Missed video call')
              : (isAudio ? 'Voice call' : 'Video call');

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const Gap(4),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle.copyWith(
                color: isMissed ? Colors.redAccent : textStyle.color,
              ),
            ),
          ),
        ],
      );
    }

    final normalText = EmojiHelper.normalize(_getNormalMessageText());
    final direction = BidiTextHelper.detectDirection(normalText);

    return Text(
      normalText,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textDirection: direction,
      textAlign: TextAlign.left,
      style: textStyle.copyWith(
        fontFamily: null,
        fontFamilyFallback: AppTypography.fontFallback,
      ),
    );
  }

  Widget _buildLastMessage(BuildContext context) {
    if (user.isRecording) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const RecordingIndicatorWidget(size: 14),
          const SizedBox(width: 6),
          AnimatedActivityText(
            text: 'recording audio...',
            style: TextStyle(color: Colors.red.shade600, fontSize: 14),
          ),
        ],
      );
    }
    if (user.isTyping == true) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          AnimatedActivityText(
            text: 'typing',
            style: TextStyle(color: Colors.green, fontSize: 14),
          ),
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (user.lastMessageIsMe && !_isSystemEventPreview) ...[
            Icon(
              user.lastMessageIsRead ? Icons.done_all : Icons.done,
              size: 16,
              color: user.lastMessageIsRead ? Colors.blue : Colors.grey,
            ),
            const Gap(4),
          ],
          Expanded(child: _buildMessagePreview(context)),
        ],
      );
    }
  }

  Text _buildUserName(BuildContext context) {
    return Text(
      user.name,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
    );
  }

  Widget _buildUserAvatar(
    BuildContext context,
    bool isSelecting,
    bool isSelected,
    Color primary,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        PresenceAvatarWidget(
          userId: user.id,
          avatarSize: 52,
          showDot: true,
          showBorder: true,

          child: AppAvatar(
            imageUrl: user.imageUrl,
            size: 52,
            heroTag: enableHero ? user.id : null,
            onTap:
                isSelecting
                    ? null
                    : () {
                      showDialog(
                        context: context,
                        builder:
                            (context) => UserPreviewDialog(
                              user: user,
                              showContactOptions: true,
                            ),
                      );
                    },
          ),
        ),
        if (isSelecting)
          Positioned(
            right: -2,
            bottom: -2,
            child: _ChatSelectionBadge(
              isSelected: isSelected,
              primary: primary,
            ),
          ),
      ],
    );
  }
}

class _ChatSelectionBadge extends StatelessWidget {
  final bool isSelected;
  final Color primary;
  const _ChatSelectionBadge({required this.isSelected, required this.primary});

  @override
  Widget build(BuildContext context) {
    final ringColor = Theme.of(context).scaffoldBackgroundColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 22,
      height: 22,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(shape: BoxShape.circle, color: ringColor),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? primary : Colors.transparent,
          border: Border.all(
            color: isSelected ? primary : Colors.grey.shade400,
            width: 1.5,
          ),
        ),
        child:
            isSelected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 13)
                : null,
      ),
    );
  }
}
