import 'package:flutter/material.dart';
import 'package:social_media_app/features/single_chats/widgets/user_chat_avatar_widget.dart';
import '../../../core/audio/helpers/pulsing_mic_dot.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/widgets/animated_activity_text.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

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
      padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8, top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8, bottom: 2),
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
              borderRadius: BorderRadiusDirectional.only(
                topStart: const Radius.circular(18),
                topEnd: const Radius.circular(18),
                bottomEnd: const Radius.circular(18),
                bottomStart: const Radius.circular(4),
              ).resolve(Directionality.of(context)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PulsingMicDot(),
                const SizedBox(width: 8),
                AnimatedActivityText(
                  text: context.l10n.recordingAudio2,
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
