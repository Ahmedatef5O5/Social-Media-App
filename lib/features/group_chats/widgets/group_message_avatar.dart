import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/presence/widgets/presence_avatar_widget.dart';
import '../../profile/widgets/user_preview_dialog.dart';
import '../../single_chats/models/chat_user_model.dart';
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
    final user = ChatUserModel(
      id: message.senderId,
      name: message.senderName,
      imageUrl: message.senderAvatar,
    );
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          barrierColor: Colors.black54,
          builder:
              (_) => UserPreviewDialog(user: user, showContactOptions: true),
        );
      },
      child: PresenceAvatarWidget(
        userId: user.id,
        avatarSize: 32,
        showBorder: false,
        child: CircleAvatar(
          radius: 16,
          backgroundColor: primary.withValues(alpha: 0.12),
          backgroundImage:
              hasAvatar
                  ? CachedNetworkImageProvider(message.senderAvatar!)
                  : null,
          child:
              !hasAvatar
                  ? ClipOval(
                    child: Image.asset(
                      AppImages.defaultUserImg,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  )
                  : null,
        ),
      ),
    );
  }
}
