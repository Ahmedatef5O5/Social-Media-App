import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/widgets/app_network_image.dart';
import '../models/reel_model.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class ReelUnavailableFallback extends StatelessWidget {
  final ReelModel reel;
  const ReelUnavailableFallback({super.key, required this.reel});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AppNetworkImage(imageUrl: reel.thumbnailUrl, fit: BoxFit.cover),
        Container(color: Colors.black54),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.white70, size: 40),
              const Gap(10),
              Text(
                context.l10n.learnHowToPlay,
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
                label: Text(
                  context.l10n.openOnYoutube,
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
