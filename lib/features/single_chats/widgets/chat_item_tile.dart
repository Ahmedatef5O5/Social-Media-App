import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/helpers/chat_helper.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/presence/widgets/presence_avatar_widget.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../profile/widgets/user_preview_dialog.dart';
import '../models/chat_user_model.dart';
import 'typing_indicator_widget.dart';

class ChatItemTile extends StatelessWidget {
  final ChatUserModel user;
  const ChatItemTile({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _buildUserAvatar(context),
      title: _buildUserName(context),
      subtitle: _buildLastMessage(context),
      trailing: _buildTrailingSection(context),
      onTap:
          () => Navigator.of(
            context,
            rootNavigator: true,
          ).pushNamed(AppRoutes.chatDetailsViewRoute, arguments: user),
    );
  }

  Column _buildTrailingSection(context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (user.lastMessageTime != null) ...[
          const Gap(2),
          Text(
            FormattedDate.getChatTime(user.lastMessageTime!, isChatList: true),
            style: const TextStyle(color: Colors.grey, fontSize: 10),
          ),
        ],
        if (user.unreadCount > 0) ...[
          const Gap(4),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              user.unreadCount > 99 ? '99+' : '${user.unreadCount}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
      default:
        return (user.lastMessage == null || user.lastMessage!.isEmpty)
            ? 'Tap to start chatting'
            : user.lastMessage!;
    }
  }

  Widget _buildMessagePreview(BuildContext context) {
    final bool isUnread = user.unreadCount > 0;
    final textStyle = Theme.of(context).textTheme.labelSmall!.copyWith(
      fontWeight: isUnread ? FontWeight.w500 : FontWeight.w400,
      fontSize: 14,
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

      String label =
          isMissed
              ? (isAudio ? 'Missed voice call' : 'Missed video call')
              : (isAudio ? 'Voice call' : 'Video call');

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const Gap(4),
          Flexible(
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

    final normalText = _getNormalMessageText();
    return Text(
      normalText,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textDirection: ChatHelper.getTextDirection(normalText),
      style: textStyle,
    );
  }

  Widget _buildLastMessage(BuildContext context) {
    if (user.isTyping == true) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'typing',
            style: TextStyle(color: Colors.green, fontSize: 14),
          ),
          const SizedBox(width: 5),
          const TypingIndicatorWidget(dotSize: 2.8, color: Colors.green),
        ],
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (user.lastMessageIsMe) ...[
            Icon(
              user.lastMessageIsRead ? Icons.done_all : Icons.done,
              size: 16,
              color: user.lastMessageIsRead ? Colors.blue : Colors.grey,
            ),
            const Gap(4),
          ],
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildMessagePreview(context),
            ),
          ),
        ],
      );
    }
  }

  Text _buildUserName(BuildContext context) {
    return Text(
      user.name,
      style: Theme.of(context).textTheme.labelLarge!.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 17,
      ),
    );
  }

  Widget _buildUserAvatar(BuildContext context) {
    return PresenceAvatarWidget(
      userId: user.id,
      avatarSize: 52,
      showDot: true,
      showBorder: true,

      child: AppAvatar(
        imageUrl: user.imageUrl,
        size: 52,
        heroTag: user.id,
        onTap: () {
          showDialog(
            context: context,
            builder:
                (context) =>
                    UserPreviewDialog(user: user, showContactOptions: true),
          );
        },
      ),
    );
  }
}
