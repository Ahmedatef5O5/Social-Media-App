import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/themes/background_theme_widget.dart';
import 'package:social_media_app/features/chats/models/chat_user_model.dart';
import 'package:social_media_app/features/chats/widgets/custom_icon_btn_widget.dart';
import 'package:social_media_app/features/chats/widgets/receiver_details_header_section.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/themes/app_colors.dart';
import '../widgets/chat_bubble.dart';

class ChatDetailsView extends StatelessWidget {
  final ChatUserModel receiverUser;

  const ChatDetailsView({super.key, required this.receiverUser});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),

      child: BackgroundThemeWidget(
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: AppColors.transparent,

          body: Column(
            children: [
              ReceiverDetailsHeaderSection(receiverUser: receiverUser),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.all(20),
                  children: [
                    // const Center(child: Text('Messages will appear here...')),
                    const Gap(12),
                    ChatBubble(message: "Hi there!", isMe: false),
                    const Gap(8),
                    ChatBubble(
                      message:
                          "Hello! How are you doing today? I hope everything is going well with your Flutter project.",
                      isMe: true,
                    ),
                    const Gap(8),
                    ChatBubble(
                      message:
                          "I'm doing great! Just working on the chat system now.",
                      isMe: false,
                    ),
                    ChatBubble(message: "Hi there!", isMe: false),
                    const Gap(8),
                    ChatBubble(
                      message:
                          "Hello! How are you doing today? I hope everything is going well with your Flutter project.",
                      isMe: true,
                    ),
                    const Gap(8),
                    ChatBubble(
                      message:
                          "I'm doing great! Just working on the chat system now.",
                      isMe: false,
                    ),
                    ChatBubble(message: "Hi there!", isMe: false),
                    const Gap(8),
                    ChatBubble(
                      message:
                          "Hello! How are you doing today? I hope everything is going well with your Flutter project.",
                      isMe: true,
                    ),
                    const Gap(8),
                    ChatBubble(
                      message:
                          "I'm doing great! Just working on the chat system now.",
                      isMe: false,
                    ),
                  ],
                ),
              ),
              _buildMessageInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
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
                  child: const TextField(
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
                onTap: () {},
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
