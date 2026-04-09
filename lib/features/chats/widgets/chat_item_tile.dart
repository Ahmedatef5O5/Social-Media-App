import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/helpers/chat_helper.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
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

  String _getLastMessageText() {
    switch (user.lastMessageType) {
      case 'image':
        return '📷 Photo';
      case 'video':
        return '🎥 Video';
      case 'voice':
        return '🎤 Voice message';
      default:
        return (user.lastMessage == null || user.lastMessage!.isEmpty)
            ? 'Tap to start chatting'
            : user.lastMessage!;
    }
  }

  Widget _buildLastMessage(BuildContext context) {
    if (user.isTyping == true) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('typing', style: TextStyle(color: Colors.green, fontSize: 14)),
          const SizedBox(width: 5),
          TypingIndicatorWidget(dotSize: 2.8, color: Colors.green),
        ],
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (user.lastMessageIsMe) ...[
            Icon(
              user.lastMessageIsRead ? Icons.done_all : Icons.done,
              size: 15,
              color: user.lastMessageIsRead ? Colors.blue : Colors.grey,
            ),
            const Gap(4),
          ],
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _getLastMessageText(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: ChatHelper.getTextDirection(
                  _getLastMessageText(),
                ),
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  fontWeight:
                      user.unreadCount > 0 ? FontWeight.w400 : FontWeight.w300,
                  fontSize: 14,
                  height: 1.8,
                ),
              ),
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
        fontWeight: FontWeight.w500,
        fontSize: 18,
      ),
    );
  }

  Widget _buildUserAvatar(BuildContext context) {
    final lastSeenText =
        user.lastSeen != null
            ? FormattedDate.getLastSeen(user.lastSeen!)
            : null;
    final isOnline = user.lastSeen == null || lastSeenText == 'Online';

    return GestureDetector(
      onTap: () {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushNamed(AppRoutes.profileViewRoute, arguments: user.id);
      },
      child: Stack(
        children: [
          Hero(
            tag: user.id,
            child: Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border:
                    isOnline
                        ? Border.all(color: Colors.green, width: 2.2)
                        : null,
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl:
                      (user.imageUrl != null && user.imageUrl!.isNotEmpty)
                          ? user.imageUrl!
                          : AppImages.defaultUserImg,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const CustomLoadingIndicator(),
                  errorWidget:
                      (context, url, error) => const Icon(Icons.person),
                  maxWidthDiskCache: 200,
                  maxHeightDiskCache: 200,
                ),
              ),
            ),
          ),
          if (isOnline)
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
