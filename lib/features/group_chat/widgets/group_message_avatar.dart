import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class GroupMessageAvatar extends StatelessWidget {
  final String? avatar;
  final String name;
  final Color primary;

  const GroupMessageAvatar({
    super.key,
    required this.avatar,
    required this.name,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: primary.withValues(alpha: 0.12),
      backgroundImage:
          (avatar?.isNotEmpty == true)
              ? CachedNetworkImageProvider(avatar!)
              : null,
      child:
          (avatar?.isEmpty ?? true)
              ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              )
              : null,
    );
  }
}
