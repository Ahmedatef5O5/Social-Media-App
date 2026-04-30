import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../profile/widgets/user_preview_dialog.dart';
import '../../chats/models/chat_user_model.dart';
import '../models/groupe_message_model.dart';

class GroupMessageAvatar extends StatelessWidget {
  final GroupMessageModel message;
  final Color primary;

  const GroupMessageAvatar({
    super.key,
    required this.message,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvatar =
        message.senderAvatar != null && message.senderAvatar!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        final user = ChatUserModel(
          id: message.senderId,
          name: message.senderName,
          imageUrl: message.senderAvatar,
        );

        showDialog(
          context: context,
          barrierColor: Colors.black54,
          builder:
              (_) => UserPreviewDialog(user: user, showContactOptions: true),
        );
      },
      child: CircleAvatar(
        radius: 16,
        backgroundColor: primary.withValues(alpha: 0.12),
        backgroundImage:
            hasAvatar
                ? CachedNetworkImageProvider(message.senderAvatar!)
                : null,
        child:
            !hasAvatar
                ? Text(
                  message.senderName.isNotEmpty
                      ? message.senderName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                )
                : null,
      ),
    );
  }
}
