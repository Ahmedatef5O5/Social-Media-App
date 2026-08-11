import 'package:flutter/material.dart';
import 'package:social_media_app/features/single_chats/widgets/user_chat_avatar_widget.dart';
import '../../../core/audio/helpers/pulsing_mic_dot.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/widgets/animated_activity_text.dart';

class RecordingBubbleWidget extends StatelessWidget {
  final String? receiverUserImgUrl;
  final String receiverUserId;

  const RecordingBubbleWidget({
    super.key,
    this.receiverUserImgUrl,
    required this.receiverUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 3, bottom: 8, top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 2),
            child: UserChatAvatar(
              userId: receiverUserId,
              userImgUrl: receiverUserImgUrl ?? AppImages.defaultUserImg,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red.shade200, width: 0.8),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PulsingMicDot(),
                const SizedBox(width: 8),
                AnimatedActivityText(
                  text: 'recording audio...',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
