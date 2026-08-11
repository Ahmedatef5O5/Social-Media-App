import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../supabase/supabase_provider.dart';
import '../helpers/media_action_helper.dart' hide ShowInChatCallback;
import '../models/shared_media_item.dart';
import '../views/shared_media_view.dart';
import 'sectioned_media_grid.dart';
import 'shared_media_action_menu.dart';

class SharedImagesGrid extends StatelessWidget {
  final List<SharedMediaItem> items;
  final ShowInChatCallback? onShowInChat;
  const SharedImagesGrid({super.key, required this.items, this.onShowInChat});

  @override
  Widget build(BuildContext context) {
    return SectionedMediaGrid(
      items: items,
      tileBuilder: (context, item) {
        final isMe = item.senderId == SupabaseProvider.id;

        return GestureDetector(
          onTap:
              () => MediaActionHelper.openFullScreenMedia(context, items, item),
          onLongPressStart:
              (details) => showSharedMediaActionMenu(
                context: context,
                globalPosition: details.globalPosition,
                isMe: isMe,
                onShowInChat:
                    () => MediaActionHelper.handleShowInChat(
                      context,
                      item,
                      onShowInChat,
                    ),

                onConfirmedDelete:
                    () => MediaActionHelper.handleDelete(
                      context,
                      item,
                      forEveryone: isMe,
                    ),
                onOpen:
                    () => MediaActionHelper.openFullScreenMedia(
                      context,
                      items,
                      item,
                    ),
                openLabel: 'View photo',
                openIcon: Icons.image_outlined,
              ),
          child: CachedNetworkImage(
            imageUrl: item.imageUrl ?? '',
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}
