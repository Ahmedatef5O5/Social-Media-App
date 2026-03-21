import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/themes/background_theme_widget.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import 'package:social_media_app/features/chats/cubit/chat_details_cubit/chat_details_cubit.dart';
import 'package:social_media_app/features/chats/models/chat_user_model.dart';
import 'package:social_media_app/features/chats/widgets/receiver_details_header_section.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/themes/app_colors.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/empty_placeholder_state.dart';
import '../widgets/text_input_area_section.dart';

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
                        return EmptyPlaceholderState(
                          img: AppImages.blueSmileFaceLot,
                          title: 'No messages yet.',
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
              TextInputAreaSection(
                receiverUser: widget.receiverUser,
                messageController: _messageController,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
