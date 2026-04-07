import 'package:flutter/material.dart';
import 'package:social_media_app/features/chats/widgets/typing_indicator_widget.dart';
import 'package:social_media_app/features/chats/widgets/user_chat_avatar_widget.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/themes/app_colors.dart';

class TypingBubbleWidget extends StatelessWidget {
  final String? receiverUserImgUrl;
  const TypingBubbleWidget({super.key, this.receiverUserImgUrl});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(left: 0, bottom: 8, top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 2),
            child: UserChatAvatar(
              userImgUrl: receiverUserImgUrl ?? AppImages.defaultUserImg,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color:
                  isDarkMode
                      ? AppColors.white.withValues(alpha: 0.85)
                      : AppColors.grey.withValues(alpha: 0.25),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: TypingIndicatorWidget(
              color: isDarkMode ? AppColors.grey5 : AppColors.grey6,
              dotSize: 5,
            ),
          ),
        ],
      ),
    );
  }
}
