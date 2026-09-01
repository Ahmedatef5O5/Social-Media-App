import 'package:flutter/material.dart';
import '../../../core/presence/widgets/presence_avatar_widget.dart';
import '../../../core/presence/widgets/presence_status_text.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/router/app_routes.dart';
import '../../../features/auth/data/models/user_data.dart';

class NewChatContactTile extends StatelessWidget {
  final UserData user;
  final VoidCallback onTap;
  final bool isBlocked;
  final String searchQuery;

  const NewChatContactTile({
    super.key,
    required this.user,
    required this.onTap,
    this.isBlocked = false,
    this.searchQuery = '',
  });

  bool get _hasRealImage => user.imageUrl != null && user.imageUrl!.isNotEmpty;

  void _openFullScreenAvatar(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pushNamed(
      AppRoutes.fullScreenImageViewRoute,
      arguments: {
        'url': user.imageUrl!,
        'tag': 'new_chat_avatar_${user.id}',
        'isAsset': false,
      },
    );
  }

  bool get _hasTitle => user.title != null && user.title!.trim().isNotEmpty;

  Widget _buildHighlightedText(
    BuildContext context,
    String text,
    TextStyle baseStyle,
  ) {
    if (searchQuery.isEmpty) {
      return Text(
        text,
        style: baseStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = searchQuery.toLowerCase();
    final matchIndex = lowerText.indexOf(lowerQuery);

    if (matchIndex == -1) {
      return Text(
        text,
        style: baseStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final beforeMatch = text.substring(0, matchIndex);
    final matchText = text.substring(
      matchIndex,
      matchIndex + searchQuery.length,
    );
    final afterMatch = text.substring(matchIndex + searchQuery.length);

    final highlightColor = Theme.of(
      context,
    ).primaryColor.withValues(alpha: 0.25);

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: beforeMatch),
          TextSpan(
            text: matchText,
            style: baseStyle.copyWith(backgroundColor: highlightColor),
          ),
          TextSpan(text: afterMatch),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    final tile = ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
      leading: PresenceAvatarWidget(
        userId: user.id,
        avatarSize: 48,
        showDot: true,
        showBorder: true,
        child: AppAvatar(
          imageUrl: user.imageUrl,
          size: 48,
          heroTag: 'new_chat_avatar_${user.id}',
          onTap: _hasRealImage ? () => _openFullScreenAvatar(context) : null,
        ),
      ),
      title: _buildHighlightedText(
        context,
        user.name,
        TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
      ),
      subtitle:
          isBlocked
              ? null
              : _hasTitle
              ? Text(
                user.title!,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
              : PresenceStatusText(
                userId: user.id,
                fallbackLastSeen: user.lastSeen,
                presencePrivacy: user.presencePrivacy,
              ),
    );

    return isBlocked ? Opacity(opacity: 0.5, child: tile) : tile;
  }
}
