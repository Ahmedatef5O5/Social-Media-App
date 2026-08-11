import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../supabase/supabase_provider.dart';
import '../models/shared_media_item.dart';

class VoiceGridTile extends StatelessWidget {
  final SharedMediaItem item;

  const VoiceGridTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final isMe = item.senderId == SupabaseProvider.id;
    final hasAvatar = (item.senderAvatar ?? '').isNotEmpty;

    return Container(
      color: primary.withValues(alpha: 0.08),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: primary.withValues(alpha: 0.15),
                backgroundImage:
                    hasAvatar
                        ? CachedNetworkImageProvider(item.senderAvatar!)
                        : null,
                child:
                    !hasAvatar
                        ? Text(
                          item.senderName.isNotEmpty
                              ? item.senderName[0].toUpperCase()
                              : '?',
                          style: TextStyle(color: primary, fontSize: 14),
                        )
                        : null,
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary,
                    border: Border.all(
                      color: theme.scaffoldBackgroundColor,
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const Gap(6),
          Text(
            isMe ? 'You' : item.senderName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
