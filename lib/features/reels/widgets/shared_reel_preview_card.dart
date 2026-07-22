import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../model/reel_model.dart';
import '../views/reels_full_screen_view.dart';

class SharedReelPreviewCard extends StatelessWidget {
  final ReelModel reel;

  const SharedReelPreviewCard({super.key, required this.reel});

  void _openReel(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => ReelsFullScreenView(reels: [reel], initialIndex: 0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openReel(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: 9 / 14,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: reel.thumbnailUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, error) => Container(color: Colors.black26),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                    stops: [0.55, 1],
                  ),
                ),
              ),
              const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 46,
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.white24,
                          backgroundImage:
                              reel.channel.channelAvatarUrl != null
                                  ? CachedNetworkImageProvider(
                                    reel.channel.channelAvatarUrl!,
                                  )
                                  : null,
                          child:
                              reel.channel.channelAvatarUrl == null
                                  ? const Icon(
                                    Icons.person,
                                    size: 11,
                                    color: Colors.white,
                                  )
                                  : null,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            reel.channel.channelName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reel.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
