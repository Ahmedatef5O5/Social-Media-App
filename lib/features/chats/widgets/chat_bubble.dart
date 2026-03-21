import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/helpers/formatted_date.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/custom_loading_indicator.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final DateTime time;
  final String? userImgUrl;
  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.time,
    this.userImgUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMe) ...[
          Container(
            height: 28,
            width: 28,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl:
                    (userImgUrl != null && userImgUrl!.isNotEmpty)
                        ? userImgUrl!
                        : AppImages.defaultUserImg,
                fit: BoxFit.cover,
                placeholder: (context, url) => const CustomLoadingIndicator(),
                errorWidget: (context, url, error) => const Icon(Icons.person),
                maxWidthDiskCache: 200,
                maxHeightDiskCache: 200,
              ),
            ),
          ),
          const Gap(8),
        ],
        Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color:
                isMe
                    ? AppColors.primaryColor
                    : AppColors.grey3.withValues(alpha: 0.3),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isMe ? 20 : 0),
              bottomRight: Radius.circular(isMe ? 0 : 20),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.grey.withValues(alpha: 0.18),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: isMe ? AppColors.white : AppColors.black87,
                  fontSize: 15,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                FormattedDate.getMessageTime(time),
                style: TextStyle(
                  color: isMe ? AppColors.white70 : AppColors.black54,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
