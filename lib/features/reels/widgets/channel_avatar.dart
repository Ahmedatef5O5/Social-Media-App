import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ChannelAvatar extends StatelessWidget {
  final String? avatarUrl;
  const ChannelAvatar({super.key, required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    const double size = 36;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child:
            avatarUrl != null
                ? CachedNetworkImage(
                  imageUrl: avatarUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const _ChannelAvatarFallback(),
                  errorWidget: (_, __, ___) => const _ChannelAvatarFallback(),
                )
                : const _ChannelAvatarFallback(),
      ),
    );
  }
}

class _ChannelAvatarFallback extends StatelessWidget {
  const _ChannelAvatarFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.white24,
      child: Icon(Icons.person, color: Colors.white, size: 18),
    );
  }
}
