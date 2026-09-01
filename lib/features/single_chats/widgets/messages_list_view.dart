import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:social_media_app/features/single_chats/widgets/chat_bubble.dart';
import 'package:social_media_app/features/single_chats/widgets/chat_loading_skeleton.dart';
import 'package:social_media_app/features/single_chats/widgets/date_separator_glassmorphism_widget.dart';
import 'package:social_media_app/features/single_chats/widgets/empty_placeholder_state.dart';
import 'package:social_media_app/features/single_chats/widgets/typing_bubble_widget.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/messaging/message_reconciler.dart';
import '../../../core/presence/models/chat_action_type.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../cubits/chat_details_cubit/chat_details_cubit.dart';
import '../helpers/chat_date_separator_helper.dart';
import '../helpers/chat_system_event_separator.dart';
import '../helpers/chat_system_event_text_builder.dart';
import '../models/chat_user_model.dart';
import '../models/message_model.dart';
import 'recording_bubble_widget.dart';

class MessagesListView extends StatefulWidget {
  final ChatUserModel receiverUser;
  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;
  final Function(MessageModel) onReply;
  final Function(MessageModel) onEdit;
  final ValueNotifier<bool> showScrollButtonNotifier;
  final VoidCallback scrollToBottom;
  const MessagesListView({
    super.key,
    required this.receiverUser,
    required this.itemScrollController,
    required this.itemPositionsListener,
    required this.onReply,
    required this.onEdit,
    required this.showScrollButtonNotifier,
    required this.scrollToBottom,
  });

  @override
  State<MessagesListView> createState() => _MessagesListViewState();
}

class _MessagesListViewState extends State<MessagesListView> {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static String? _lastPlayedMessageId;

  int _lastMessageCount = 0;
  String? _lastAutoScrolledSendingId;
  bool _wasSyncConfirmed = false;

  Future<void> _playNotificationSound() async {
    try {
      await _audioPlayer.play(
        AssetSource('sounds/universfield-new-notification-07-210334.mp3'),
      );
    } catch (e) {
      debugPrint("Error playing sound: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ChatDetailsCubit>();
    return ValueListenableBuilder<ChatActionType>(
      valueListenable: cubit.listVisibleAction,
      builder: (context, action, _) {
        final hasBubble = action != ChatActionType.none;

        return BlocConsumer<ChatDetailsCubit, ChatDetailsState>(
          listener: _handleMessagesLogic,
          buildWhen:
              (prev, curr) =>
                  curr is MessagesSuccessLoaded ||
                  curr is MessagesSending ||
                  curr is ChatDetailsInitial,
          builder: (context, state) {
            final cubit = context.read<ChatDetailsCubit>();
            final messages = cubit.cachedMessages;

            if (messages.isEmpty) {
              if (state is MessagesError) {
                return Center(child: Text(state.message));
              }
              if (!cubit.hasConfirmedInitialLoad) {
                return const ChatLoadingSkeleton();
              }
              return _buildEmptyState(context);
            }

            return Stack(
              children: [
                ScrollablePositionedList.separated(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemScrollController: widget.itemScrollController,
                  itemPositionsListener: widget.itemPositionsListener,
                  reverse: true,

                  itemCount: messages.length + (hasBubble ? 1 : 0),

                  itemBuilder: (BuildContext context, int index) {
                    final cubit = context.read<ChatDetailsCubit>();

                    if (hasBubble && index == 0) {
                      return action == ChatActionType.recording
                          ? RecordingBubbleWidget(
                            receiverUserId: widget.receiverUser.id,
                            receiverUserImgUrl: widget.receiverUser.imageUrl,
                          )
                          : TypingBubbleWidget(
                            receiverUserId: widget.receiverUser.id,
                            receiverUserImgUrl: widget.receiverUser.imageUrl,
                          );
                    }
                    final msgIndex = hasBubble ? index - 1 : index;
                    if (msgIndex < 0 || msgIndex >= messages.length) {
                      return const SizedBox.shrink();
                    }

                    final msg = messages[msgIndex];
                    final bool isMe = msg.senderId == SupabaseProvider.id;
                    final double? currentProgress =
                        cubit.uploadProgressMap[msg.id];

                    final showDateSeparator =
                        ChatDateSeparatorHelper.shouldShowDate<MessageModel>(
                          messages: messages,
                          index: msgIndex,
                          getCreatedAt: (m) => m.createdAt,
                        );

                    if (msg.isSystemEvent) {
                      final stableKey = correlationKeyFor(
                        id: msg.id,
                        clientMessageId: msg.clientMessageId,
                      );
                      return Column(
                        key: ValueKey('item_$stableKey'),
                        children: [
                          if (showDateSeparator)
                            DateSeparatorGlassmorphismWidget(
                              key: ValueKey('date_$stableKey'),
                              date: FormattedDate.getChatTime(msg.createdAt),
                            ),
                          ChatSystemEventSeparator(
                            text: ChatSystemEventTextBuilder.build(
                              message: msg,
                              currentUserId: SupabaseProvider.id,
                              otherUserName: widget.receiverUser.name,
                            ),
                          ),
                        ],
                      );
                    }

                    final showAvatar =
                        ChatDateSeparatorHelper.isLastInSenderCluster<
                          MessageModel
                        >(
                          messages: messages,
                          index: msgIndex,
                          getSenderId: (m) => m.senderId,
                          getCreatedAt: (m) => m.createdAt,
                        );

                    final stableKey = correlationKeyFor(
                      id: msg.id,
                      clientMessageId: msg.clientMessageId,
                    );
                    return Column(
                      key: ValueKey('item_$stableKey'),
                      children: [
                        if (showDateSeparator)
                          DateSeparatorGlassmorphismWidget(
                            key: ValueKey('date_$stableKey'),
                            date: FormattedDate.getChatTime(msg.createdAt),
                          ),
                        ChatBubble(
                          userImgUrl:
                              isMe ? null : widget.receiverUser.imageUrl,
                          receiverUser: widget.receiverUser,
                          message: msg,
                          onReply: widget.onReply,
                          onEdit: widget.onEdit,
                          itemScrollController: widget.itemScrollController,
                          isMe: isMe,
                          uploadProgress: currentProgress,
                          showAvatar: showAvatar,
                        ),
                      ],
                    );
                  },
                  separatorBuilder:
                      (context, index) =>
                          __buildSeparator(index, messages, hasBubble),
                ),
                _buildScrollToBottomButton(context),
              ],
            );
          },
        );
      },
    );
  }

  void _handleMessagesLogic(BuildContext context, ChatDetailsState state) {
    if (state is MessagesSending &&
        state.messages != null &&
        state.messages!.isNotEmpty) {
      final currentUserId = SupabaseProvider.id;
      final lastMsg = state.messages!.first;
      if (lastMsg.senderId == currentUserId &&
          _lastAutoScrolledSendingId != lastMsg.id) {
        _lastAutoScrolledSendingId = lastMsg.id;
        widget.scrollToBottom();
      }
      return;
    }

    if (state is MessagesSuccessLoaded && state.messages.isNotEmpty) {
      final messages = state.messages;
      final currentUserId = SupabaseProvider.id;
      final cubit = context.read<ChatDetailsCubit>();

      final bool isNewMessage = messages.length > _lastMessageCount;
      final int previousCount = _lastMessageCount;
      _lastMessageCount = messages.length;

      final bool isSyncConfirmedNow = cubit.hasConfirmedInitialLoad;
      final bool justCrossedSyncBaseline =
          isSyncConfirmedNow && !_wasSyncConfirmed;
      _wasSyncConfirmed = isSyncConfirmedNow;

      if (!isSyncConfirmedNow || justCrossedSyncBaseline) return;

      if (!isNewMessage || previousCount == 0) return;

      // final isAtBottom = cubit.isUserAtBottom;
      final lastMsg = messages.first;

      if (lastMsg.senderId != currentUserId &&
          _lastPlayedMessageId != lastMsg.id) {
        _lastPlayedMessageId = lastMsg.id;
        _playNotificationSound();
      }

      widget.scrollToBottom();
    }
  }

  Widget _buildEmptyState(BuildContext context) {
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

  Widget __buildSeparator(
    int index,
    List<MessageModel> messages,
    bool isTyping,
  ) {
    if (isTyping && index == 0) {
      return const Gap(8);
    }
    final i = isTyping ? index - 1 : index;
    if (i < 0 || i + 1 >= messages.length) {
      return const Gap(8);
    }

    final currMsg = messages[i];
    final nxtMsg = messages[i + 1];
    if (currMsg.senderId == nxtMsg.senderId) {
      return Gap(nxtMsg.reactions.isNotEmpty ? 4 : 3);
    } else {
      return const Gap(16);
    }
  }

  Widget _buildScrollToBottomButton(BuildContext context) {
    final cubit = context.read<ChatDetailsCubit>();

    return ValueListenableBuilder<bool>(
      valueListenable: widget.showScrollButtonNotifier,
      builder: (context, showButton, _) {
        return ValueListenableBuilder<int>(
          valueListenable: cubit.pendingNewCountNotifier,
          builder: (context, unreadCount, _) {
            final visible = showButton || unreadCount > 0;

            return AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              left: 16,
              bottom: visible ? 20 : -80,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: visible ? 1.0 : 0.0,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 400),
                  scale: visible ? 1.0 : 0.5,
                  curve: Curves.easeOutBack,
                  child: GestureDetector(
                    onTap: widget.scrollToBottom,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                            size: 25,
                          ),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            top: -10,
                            right: -10,
                            child: TweenAnimationBuilder(
                              duration: const Duration(milliseconds: 300),
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: child,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    width: 1.2,
                                  ),
                                ),

                                child: Text(
                                  unreadCount > 99 ? '99' : '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
