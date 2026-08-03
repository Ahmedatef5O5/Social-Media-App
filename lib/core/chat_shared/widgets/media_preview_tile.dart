import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../features/single_chats/widgets/full_screen_media_view.dart';
import '../models/shared_media_item.dart';

class MediaPreviewTile extends StatelessWidget {
  final SharedMediaItem item;
  const MediaPreviewTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: () => _openMedia(context),
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
                imageUrl: item.videoUrl ?? '',
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(color: Colors.black26),
              ),
              const Center(
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ],
          ),
          _ => Container(
            color: primary.withValues(alpha: 0.12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mic_rounded, color: primary),
                const Gap(4),
                Text('Voice', style: TextStyle(color: primary, fontSize: 11)),
              ],
            ),
          ),
        },
      ),
    );
  }

  void _openMedia(BuildContext context) {
    if (item.messageType == 'image' && item.imageUrl != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FullScreenMediaView(imageUrl: item.imageUrl!),
        ),
      );
    } else if (item.messageType == 'video' && item.videoUrl != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FullScreenMediaView(videoUrl: item.videoUrl!),
        ),
      );
    }
  }
}
