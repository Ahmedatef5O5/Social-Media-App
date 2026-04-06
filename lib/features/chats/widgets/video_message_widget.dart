import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/features/chats/widgets/full_screen_media_view.dart';
import '../../../core/themes/app_colors.dart';

class VideoMessageWidget extends StatelessWidget {
  final String videoUrl;
  final String? caption;
  final bool isMe;

  const VideoMessageWidget({
    super.key,
    required this.videoUrl,
    this.caption,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(15),
      topRight: const Radius.circular(15),
      bottomRight: Radius.circular(isMe ? 0 : 15),
      bottomLeft: Radius.circular(isMe ? 15 : 0),
    );
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
      child: Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(
            color:
                isDarkMode
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppColors.grey.withValues(alpha: 0.12),
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  isDarkMode
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black12.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Theme.of(context).colorScheme.onSecondary.withValues(
                      alpha: isDarkMode ? 0.5 : 0.25,
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 10,
                right: 10,
                child: Icon(
                  CupertinoIcons.video_camera,
                  // Icons.video_chat_outlined,
                  color: Colors.white.withValues(alpha: isDarkMode ? 0.9 : 0.7),
                  size: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(
                    context,
                  ).scaffoldBackgroundColor.withValues(alpha: 0.3),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),

                child: Icon(
                  Icons.play_arrow_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
