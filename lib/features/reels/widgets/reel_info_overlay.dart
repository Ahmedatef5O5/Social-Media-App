import 'package:flutter/material.dart';
import '../model/reel_model.dart';
import 'channel_avatar.dart';

class ReelInfoOverlay extends StatelessWidget {
  final ReelModel reel;
  const ReelInfoOverlay({super.key, required this.reel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            ChannelAvatar(avatarUrl: reel.channel.channelAvatarUrl),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                reel.channel.channelName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            (reel.description?.isNotEmpty ?? false)
                ? reel.description!
                : reel.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
