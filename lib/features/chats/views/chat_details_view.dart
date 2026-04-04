import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/helpers/formatted_date.dart';
import 'package:social_media_app/core/themes/background_theme_widget.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import 'package:social_media_app/features/chats/cubit/chat_details_cubit/chat_details_cubit.dart';
import 'package:social_media_app/features/chats/models/chat_user_model.dart';
import 'package:social_media_app/features/chats/models/message_model.dart';
import 'package:social_media_app/features/chats/widgets/receiver_details_header_section.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/themes/app_colors.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/date_separator_glassmorphism_widget.dart';
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
  Timer? _lastSeenTimer;
  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();

    context.read<ChatDetailsCubit>().watchReceiverLastSeen(
      widget.receiverUser.id,
    );
    context.read<ChatDetailsCubit>().getMessagesStream(
      receiverId: widget.receiverUser.id,
    );

    //
    context.read<ChatDetailsCubit>().updateLastSeen();
    _lastSeenTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => context.read<ChatDetailsCubit>().updateLastSeen(),
    );
  }

  @override
  void dispose() {
    _lastSeenTimer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundThemeWidget(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AppColors.transparent,

        body: Column(
          children: [
            ReceiverDetailsHeaderSection(receiverUser: widget.receiverUser),
            Expanded(
              child: BlocConsumer<ChatDetailsCubit, ChatDetailsState>(
                listener: (context, state) {
                  /// TODO : add scroll controller to jump new msgs
                },
                buildWhen:
                    (previous, current) =>
                        current is MessagesSuccessLoaded ||
                        current is MessagesSending ||
                        current is MessagesLoading,
                builder: (context, state) {
                  //
                  if (state is MessagesLoading) {
                    return const Center(child: CustomLoadingIndicator());
                  }

                  //
                  List<MessageModel> messages = [];
                  if (state is MessagesSuccessLoaded) {
                    messages = state.messages;
                  } else if (state is MessagesSending) {
                    messages = state.messages ?? [];
                  }
                  if (messages.isEmpty && state is MessagesSuccessLoaded) {
                    return EmptyPlaceholderState(
                      img: AppImages.blueSmileFaceLot,

                      imgHeight: MediaQuery.of(context).size.height * 0.2,
                      title: 'No messages yet.',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    );
                  }
                  if (messages.isEmpty && state is! MessagesLoading) {
                    return const CustomLoadingIndicator();
                  }
                  return Stack(
                    children: [
                      GestureDetector(
                        onTap: () => FocusScope.of(context).unfocus(),
                        onLongPress: () {},
                        onVerticalDragStart:
                            (_) => FocusScope.of(context).unfocus(),
                        child: ListView.separated(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          reverse: true,
                          itemCount: messages.length,
                          itemBuilder: (BuildContext context, int index) {
                            final msg = messages[index];
                            final bool isMe =
                                msg.senderId ==
                                Supabase.instance.client.auth.currentUser!.id;
                            bool showDateSeparator = false;
                            if (index == messages.length - 1) {
                              showDateSeparator = true;
                            } else {
                              final prevMsg = messages[index + 1];
                              if (msg.createdAt.day != prevMsg.createdAt.day) {
                                showDateSeparator = true;
                              }
                            }
                            return Column(
                              children: [
                                if (showDateSeparator)
                                  DateSeparatorGlassmorphismWidget(
                                    date: FormattedDate.getChatTime(
                                      msg.createdAt,
                                    ),
                                  ),
                                ChatBubble(
                                  userImgUrl:
                                      isMe
                                          ? null
                                          : widget.receiverUser.imageUrl,
                                  message: msg,
                                  isMe: isMe,
                                ),
                              ],
                            );
                          },
                          separatorBuilder: (BuildContext context, int index) {
                            final currMsg = messages[index];
                            final nxtMsg = messages[index + 1];
                            if (currMsg.senderId == nxtMsg.senderId) {
                              return Gap(nxtMsg.reaction != null ? 4 : 3);
                            } else {
                              return const Gap(16);
                            }
                          },
                        ),
                      ),

                      if (state is MessagesSending)
                        Positioned(
                          bottom: 8,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  ),
                                  Gap(8),
                                  Text(
                                    'Sending...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
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
    );
  }
}
