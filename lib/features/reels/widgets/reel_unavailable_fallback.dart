import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/reel_model.dart';

class ReelUnavailableFallback extends StatelessWidget {
  final ReelModel reel;
  const ReelUnavailableFallback({super.key, required this.reel});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(imageUrl: reel.thumbnailUrl, fit: BoxFit.cover),
        Container(color: Colors.black54),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.white70, size: 40),
              const Gap(10),
              const Text(
                'Learn how to play this video',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
              const Gap(14),
              TextButton.icon(
                onPressed:
                    () => launchUrl(
                      Uri.parse(reel.youtubeWatchUrl),
                      mode: LaunchMode.externalApplication,
                    ),
                icon: const Icon(Icons.open_in_new, color: Colors.white),
                label: const Text(
                  'Open on YouTube',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
