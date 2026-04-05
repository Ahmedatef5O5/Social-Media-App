import 'package:flutter/material.dart';
import 'package:social_media_app/features/chats/widgets/full_screen_media_view.dart';

class VideoMessageWidget extends StatelessWidget {
  final String videoUrl;
  final String? caption;

  const VideoMessageWidget({super.key, required this.videoUrl, this.caption});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    FullScreenMediaView(videoUrl: videoUrl, caption: caption),
          ),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.videocam, color: Colors.white, size: 40),
          ),
          const CircleAvatar(
            backgroundColor: Colors.black54,
            child: Icon(Icons.play_arrow, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
