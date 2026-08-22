import 'package:flutter/material.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../features/group_chats/models/group_model.dart';
import '../../constants/app_images.dart';

class NewChatGroupTile extends StatelessWidget {
  final GroupModel group;
  final VoidCallback onTap;
  final bool isBlocked;
  final String searchQuery;

  const NewChatGroupTile({
    super.key,
    required this.group,
    required this.onTap,
    this.isBlocked = false,
    this.searchQuery = '',
  });

  bool get _hasRealImage =>
      group.avatarUrl != null && group.avatarUrl!.isNotEmpty;

  void _openFullScreenAvatar(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pushNamed(
      AppRoutes.fullScreenImageViewRoute,

      arguments: {
        'url': group.avatarUrl ?? AppImages.defaultGroupImg,
        'tag': 'new_chat_group_avatar_${group.id}',
        'isAsset': _hasRealImage ? false : true,
      },
    );
  }

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
      leading:
          _hasRealImage
              ? AppAvatar(
                imageUrl: group.avatarUrl,
                size: 48,
                heroTag: 'new_chat_group_avatar_${group.id}',
                onTap: () => _openFullScreenAvatar(context),
              )
              : GestureDetector(
                onTap: () => _openFullScreenAvatar(context),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: AssetImage(AppImages.defaultGroupImg),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
      title: _buildHighlightedText(
        context,
        group.name,
        TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
      ),
      subtitle: const Text(
        'Group',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      ),
    );

    return isBlocked ? Opacity(opacity: 0.5, child: tile) : tile;
  }
}
