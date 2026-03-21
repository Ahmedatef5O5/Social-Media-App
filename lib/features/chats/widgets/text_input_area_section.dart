import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/chats/widgets/custom_icon_btn_widget.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/themes/app_colors.dart';
import '../cubit/chat_details_cubit/chat_details_cubit.dart';
import '../models/chat_user_model.dart';

class TextInputAreaSection extends StatelessWidget {
  final TextEditingController messageController;
  final ChatUserModel receiverUser;
  const TextInputAreaSection({
    super.key,
    required this.messageController,
    required this.receiverUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: AppColors.transparent),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: SafeArea(
          bottom: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconBtnWidget(
                icon: Icons.add,
                onTap: () {},
                size: 27,
                padding: EdgeInsets.only(bottom: 11, left: 3, right: 3),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.bgColor2.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    controller: messageController,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                      hoverColor: AppColors.white,
                      hintText: "Type a message...",
                      hintStyle: TextStyle(color: AppColors.black38),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                splashColor: AppColors.transparent,
                onTap: () {
                  final text = messageController.text.trim();
                  if (text.isNotEmpty) {
                    context.read<ChatDetailsCubit>().sendMessage(
                      receiverId: receiverUser.id,
                      messageText: text,
                    );
                    messageController.clear();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Image.asset(
                    AppImages.sendIcon,
                    color: AppColors.primaryColor.withValues(alpha: 0.95),
                    width: 28,
                    height: 28,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
