import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/core/cache/utils/cloudinary_url_extensions.dart';
import '../models/shared_media_item.dart';
import '../views/full_screen_media_pager.dart';
import 'voice_grid_tile.dart';

class MediaPreviewTile extends StatelessWidget {
  final SharedMediaItem item;
  final List<SharedMediaItem> items;
  const MediaPreviewTile({super.key, required this.item, required this.items});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFullScreenMedia(context, items, item),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: switch (item.messageType) {
          'image' => CachedNetworkImage(
            imageUrl: item.imageUrl ?? '',
            fit: BoxFit.cover,
          ),
          'video' => Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl:
                    item.videoUrl?.cloudinaryVideoThumbnailUrl ??
                    item.videoUrl ??
                    '',
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(color: Colors.black26),
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
          _ => VoiceGridTile(item: item),
        },
      ),
    );
  }

  void _openFullScreenMedia(
    BuildContext context,
    List<SharedMediaItem> tabItems,
    SharedMediaItem tappedItem,
  ) {
    final playable =
        tabItems
            .where(
              (i) =>
                  i.messageType == 'image' ||
                  i.messageType == 'video' ||
                  (i.voiceUrl ?? '').isNotEmpty,
            )
            .toList();
    final initialIndex = playable.indexWhere((i) => i.id == tappedItem.id);

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder:
            (_, __, ___) => FullScreenMediaPager(
              items: playable,
              initialIndex: initialIndex < 0 ? 0 : initialIndex,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}
