import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_images.dart';
import '../../chats/widgets/chat_loading_skeleton.dart';
import '../../chats/widgets/empty_placeholder_state.dart';
import '../cubit/group_details_cubit/group_details_cubit.dart';
import '../cubit/group_details_cubit/group_details_state.dart';
import 'message_builder.dart';

class GroupMessagesList extends StatefulWidget {
  final ItemScrollController scrollController;
  final ItemPositionsListener positionsListener;

  const GroupMessagesList({
    super.key,
    required this.scrollController,
    required this.positionsListener,
  });

  @override
  State<GroupMessagesList> createState() => _GroupMessagesListState();
}

class _GroupMessagesListState extends State<GroupMessagesList> {
  // ─── Audio ───────────────────────────────────────────
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static String? _lastPlayedMessageId;

  // ─── Scroll / Unread ─────────────────────────────────
  int _lastMessageCount = 0;
  bool _hasLoadedOnce = false;
  final ValueNotifier<int> _unreadCountNotifier = ValueNotifier(0);
  final ValueNotifier<bool> _showScrollButtonNotifier = ValueNotifier(false);

  // ─── Helpers ─────────────────────────────────────────
  Future<void> _playNotificationSound() async {
    try {
      await _audioPlayer.play(
        AssetSource('sounds/universfield-new-notification-07-210334.mp3'),
      );
    } catch (e) {
      debugPrint('[GroupChat] Error playing sound: $e');
    }
  }

  void _scrollToBottom() {
    if (widget.scrollController.isAttached) {
      widget.scrollController.jumpTo(index: 0);
    }
    _unreadCountNotifier.value = 0;
    _showScrollButtonNotifier.value = false;
  }

  void _handleNewMessages(BuildContext context, GroupDetailsState state) {
    if (state is! GroupDetailsLoaded || state.messages.isEmpty) return;

    _hasLoadedOnce = true;
    final messages = state.messages;
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;

    final bool isNewMessage = messages.length > _lastMessageCount;
    final int previousCount = _lastMessageCount;
    _lastMessageCount = messages.length;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final positions = widget.positionsListener.itemPositions.value;
      final isAtBottom = positions.any((p) => p.index == 0);

      _showScrollButtonNotifier.value = !isAtBottom;

      if (!isNewMessage || previousCount == 0) return;

      final lastMsg = messages.first;

      if (lastMsg.senderId != currentUserId &&
          _lastPlayedMessageId != lastMsg.id) {
        _lastPlayedMessageId = lastMsg.id;
        _playNotificationSound();
      }

      if (lastMsg.senderId == currentUserId) {
        _scrollToBottom();
      } else {
        if (isAtBottom) {
          _scrollToBottom();
        } else {
          _unreadCountNotifier.value++;
          _showScrollButtonNotifier.value = true;
        }
      }
    });
  }

  @override
  void dispose() {
    _unreadCountNotifier.dispose();
    _showScrollButtonNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GroupDetailsCubit, GroupDetailsState>(
      listener: _handleNewMessages,
      buildWhen:
          (prev, curr) =>
              curr is GroupDetailsLoaded ||
              curr is GroupDetailsLoading ||
              curr is GroupDetailsInitial ||
              curr is GroupDetailsError,
      builder: (context, state) {
        if (state is GroupDetailsLoading || state is GroupDetailsInitial) {
          return const ChatLoadingSkeleton();
        }
        if (state is GroupDetailsError) {
          return Center(child: Text(state.message));
        }
        if (state is GroupDetailsLoaded) {
          final messages = state.messages;
          final typing = state.typingUserIds;

          if (messages.isEmpty && typing.isEmpty) {
            return _groupEmptyState(context);
          }

          return Stack(
            children: [
              ScrollablePositionedList.separated(
                reverse: true,
                itemScrollController: widget.scrollController,
                itemPositionsListener: widget.positionsListener,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: messages.length + (typing.isNotEmpty ? 1 : 0),
                itemBuilder:
                    (_, index) => GroupMessageItemBuilder(
                      index: index,
                      messages: messages,
                      typing: typing,
                    ),
                separatorBuilder: (_, __) => const Gap(4),
              ),

              Positioned(
                bottom: 10,
                right: 14,
                child: _ScrollToBottomButton(
                  showNotifier: _showScrollButtonNotifier,
                  countNotifier: _unreadCountNotifier,
                  onTap: _scrollToBottom,
                ),
              ),
            ],
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _groupEmptyState(BuildContext context) {
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
}

class _ScrollToBottomButton extends StatelessWidget {
  final ValueNotifier<bool> showNotifier;
  final ValueNotifier<int> countNotifier;
  final VoidCallback onTap;

  const _ScrollToBottomButton({
    required this.showNotifier,
    required this.countNotifier,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return ValueListenableBuilder<bool>(
      valueListenable: showNotifier,
      builder: (context, showButton, _) {
        if (!showButton) return const SizedBox.shrink();

        return GestureDetector(
          onTap: onTap,
          child: ValueListenableBuilder<int>(
            valueListenable: countNotifier,
            builder: (context, count, _) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Material(
                    elevation: 4,
                    shape: const CircleBorder(),
                    color: primary,
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),

                  if (count > 0)
                    Positioned(
                      top: -6,
                      right: -4,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
