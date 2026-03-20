import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/themes/background_theme_widget.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import 'package:social_media_app/features/chats/cubit/chat_details_cubit/chat_details_cubit.dart';
import 'package:social_media_app/features/chats/models/chat_user_model.dart';
import 'package:social_media_app/features/chats/widgets/custom_icon_btn_widget.dart';
import 'package:social_media_app/features/chats/widgets/receiver_details_header_section.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/themes/app_colors.dart';
import '../widgets/chat_bubble.dart';

class ChatDetailsView extends StatefulWidget {
  final ChatUserModel receiverUser;

  const ChatDetailsView({super.key, required this.receiverUser});

  @override
  State<ChatDetailsView> createState() => _ChatDetailsViewState();
}

class _ChatDetailsViewState extends State<ChatDetailsView> {
  late final TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

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
              ReceiverDetailsHeaderSection(receiverUser: widget.receiverUser),
              Expanded(
                child: BlocBuilder<ChatDetailsCubit, ChatDetailsState>(
                  builder: (context, state) {
                    if (state is MessagesLoading) {
                      return const Center(child: CustomLoadingIndicator());
                    } else if (state is MessagesSuccessLoaded) {
                      final messages = state.messages;

                      if (messages.isEmpty) {
                        return const Center(
                          child: Text('No messages yet. Say hi! 🙋‍♂️'),
                        );
                      }
                      return ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        reverse: true,
                        itemCount: messages.length,
                        itemBuilder: (BuildContext context, int index) {
                          final msg = messages[index];
                          final bool isMe =
                              msg.senderId ==
                              Supabase.instance.client.auth.currentUser!.id;
                          return ChatBubble(message: msg.text, isMe: isMe);
                        },
                      );
                    } else if (state is MessagesError) {
                      return Center(child: Text(state.message));
                    } else {
                      return SizedBox.shrink();
                    }
                  },
                ),
              ),
              _buildMessageInput(context, _messageController),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput(
    BuildContext context,
    TextEditingController messageController,
  ) {
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
                      receiverId: widget.receiverUser.id,
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
