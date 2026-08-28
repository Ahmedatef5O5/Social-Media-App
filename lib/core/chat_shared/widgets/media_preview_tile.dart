import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/cache/utils/cloudinary_url_extensions.dart';
import '../../../features/home/cubits/home_cubit/home_cubit.dart';
import '../models/shared_media_item.dart';
import '../views/full_screen_media_pager.dart';
import 'voice_grid_tile.dart';

class MediaPreviewTile extends StatelessWidget {
  final SharedMediaItem item;
  final List<SharedMediaItem> items;
  const MediaPreviewTile({super.key, required this.item, required this.items});

  @override
  Widget build(BuildContext context) {
    final currentUserAvatar =
        context.read<HomeCubit>().currentUserData?.imageUrl;
    return GestureDetector(
      onTap:
          () => _openFullScreenMedia(context, items, item, currentUserAvatar),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: switch (item.messageType) {
          'image' => CachedNetworkImage(
            imageUrl: item.imageUrl ?? '',
            fit: BoxFit.cover,
            errorWidget:
                (context, url, error) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 28,
                  ),
                ),
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
                errorWidget:
                    (context, url, error) => Container(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.video_file_rounded,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 28,
                      ),
                    ),
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
          _ => VoiceGridTile(item: item, currentUserAvatar: currentUserAvatar),
        },
      ),
    );
  }

  void _openFullScreenMedia(
    BuildContext context,
    List<SharedMediaItem> tabItems,
    SharedMediaItem tappedItem,
    String? currentUserAvatar,
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

    final currentUserAvatar =
        context.read<HomeCubit>().currentUserData?.imageUrl;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder:
            (_, __, ___) => FullScreenMediaPager(
              items: playable,
              initialIndex: initialIndex < 0 ? 0 : initialIndex,
              currentUserAvatar: currentUserAvatar,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}
