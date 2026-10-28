import 'package:flutter/material.dart';
import 'package:social_media_app/features/single_chats/widgets/typing_indicator_widget.dart';
import 'package:social_media_app/features/single_chats/widgets/user_chat_avatar_widget.dart';
import '../../../core/constants/app_images.dart';
import '../helpers/chat_bubble_colors.dart';

class TypingBubbleWidget extends StatelessWidget {
  final String? receiverUserImgUrl;
  final String receiverUserId;
  const TypingBubbleWidget({
    super.key,
    this.receiverUserImgUrl,
    required this.receiverUserId,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = getReceiverBubbleColor(context);

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
              color: getReceiverBubbleColor(context),
              borderRadius: BorderRadiusDirectional.only(
                topStart: const Radius.circular(18),
                topEnd: const Radius.circular(18),
                bottomEnd: const Radius.circular(18),
                bottomStart: const Radius.circular(4),
              ).resolve(Directionality.of(context)),
            ),
            child: TypingIndicatorWidget(
              color:
                  ThemeData.estimateBrightnessForColor(bubbleColor) ==
                          Brightness.dark
                      ? Colors.white70
                      : Colors.black54,
              dotSize: 5,
            ),
          ),
        ],
      ),
    );
  }
}
