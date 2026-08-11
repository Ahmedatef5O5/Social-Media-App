import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../cache/utils/cloudinary_url_extensions.dart';
import '../../supabase/supabase_provider.dart';
import '../helpers/media_action_helper.dart' hide ShowInChatCallback;
import '../models/shared_media_item.dart';
import '../views/shared_media_view.dart';
import 'sectioned_media_grid.dart';
import 'shared_media_action_menu.dart';

class VideoThumbnailGrid extends StatelessWidget {
  final List<SharedMediaItem> items;
  final ShowInChatCallback? onShowInChat;
  const VideoThumbnailGrid({super.key, required this.items, this.onShowInChat});

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
                openLabel: 'Play video',
                openIcon: Icons.play_circle_outline_rounded,
              ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl:
                    item.videoUrl?.cloudinaryVideoThumbnailUrl ??
                    item.videoUrl ??
                    '',
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.black12),

                errorWidget: (_, __, ___) => Container(color: Colors.black12),
              ),
              const Center(
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
