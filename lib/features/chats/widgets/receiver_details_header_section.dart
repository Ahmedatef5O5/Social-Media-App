import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/features/chats/widgets/custom_icon_btn_widget.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../models/chat_user_model.dart';

class ReceiverDetailsHeaderSection extends StatelessWidget {
  final ChatUserModel receiverUser;
  const ReceiverDetailsHeaderSection({super.key, required this.receiverUser});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            child: Row(
              children: [
                const Icon(Icons.arrow_back_ios_new, size: 22),
                const Gap(8),
                Hero(
                  tag: receiverUser.id,
                  child: Container(
                    height: 42,
                    width: 42,
                    decoration: const BoxDecoration(
                      color: AppColors.bgColor2,
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl:
                            (receiverUser.imageUrl != null &&
                                    receiverUser.imageUrl!.isNotEmpty)
                                ? receiverUser.imageUrl!
                                : AppImages.defaultUserImg,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => const CustomLoadingIndicator(),
                        errorWidget:
                            (context, url, error) => const Icon(Icons.person),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Gap(12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  receiverUser.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Text(
                  'Online',
                  style: TextStyle(fontSize: 12, color: Colors.green),
                ),
              ],
            ),
          ),

          Row(
            children: [
              CustomIconBtnWidget(
                icon: Icons.call_outlined,
                onTap: () {},
                size: 24,
              ),
              const Gap(12),
              CustomIconBtnWidget(
                icon: Icons.videocam_outlined,
                onTap: () {},
                size: 24,
              ),
              const Gap(8),
              CustomIconBtnWidget(
                icon: Icons.more_vert_outlined,
                onTap: () {},
                size: 24,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
