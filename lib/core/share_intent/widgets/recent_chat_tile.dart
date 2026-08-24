import 'package:flutter/material.dart';
import '../../chat_shared/models/conversation_item.dart';
import '../../widgets/app_avatar.dart';

class RecentChatTile extends StatelessWidget {
  final ConversationItem item;
  final VoidCallback onTap;
  const RecentChatTile({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isGroup = item.kind == ConversationKind.group;
    final name =
        isGroup ? (item.group!.title ?? item.group!.name) : item.chat!.name;
    final imageUrl = isGroup ? item.group!.avatarUrl : item.chat!.imageUrl;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: AppAvatar(imageUrl: imageUrl, size: 48),
        title: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        trailing:
            isGroup
                ? Icon(
                  Icons.groups_rounded,
                  size: 20,
                  color: Theme.of(context).primaryColor,
                )
                : null,
      ),
    );
  }
}
