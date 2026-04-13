import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:social_media_app/core/helpers/formatted_date.dart';
import 'package:social_media_app/core/themes/background_theme_widget.dart';
import 'package:social_media_app/features/chats/cubit/chat_details_cubit/chat_details_cubit.dart';
import 'package:social_media_app/features/chats/models/chat_user_model.dart';
import 'package:social_media_app/features/chats/models/message_model.dart';
import 'package:social_media_app/features/chats/widgets/messages_list_view.dart';
import 'package:social_media_app/features/chats/widgets/receiver_details_header_section.dart';
import '../../../core/services/active_screen_tracker.dart';
import '../../../core/services/notification_services.dart';
import '../../../core/themes/app_colors.dart';
import '../widgets/text_input_area_section.dart';
import '../widgets/typing_indicator_widget.dart';

class ChatDetailsView extends StatefulWidget {
  final ChatUserModel receiverUser;

  const ChatDetailsView({super.key, required this.receiverUser});

  @override
  State<ChatDetailsView> createState() => _ChatDetailsViewState();
}

class _ChatDetailsViewState extends State<ChatDetailsView> {
  late final TextEditingController _messageController;

  Timer? _lastSeenTimer;
  MessageModel? _replyTo;

  final ValueNotifier<bool> _showScrollButtonNotifier = ValueNotifier(false);
  final ValueNotifier<int> _unreadCountNotifier = ValueNotifier(0);

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();

    ActiveScreenTracker.setActiveChatReceiver(widget.receiverUser.id);

    NotificationService.instance.cancelNotificationsForSender(
      widget.receiverUser.id,
    );

    _itemPositionsListener.itemPositions.addListener(_scrollListener);

    final cubit = context.read<ChatDetailsCubit>();

    cubit.watchReceiverLastSeen(
      widget.receiverUser.id,
      initialLastSeen: widget.receiverUser.lastSeen,
    );
    cubit.watchReceiverTyping(widget.receiverUser.id);
    cubit.getMessagesStream(receiverId: widget.receiverUser.id);
    cubit.updateLastSeen();

    _lastSeenTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) {
        if (!cubit.isClosed) {
          cubit.updateLastSeen();
        } else {
          _lastSeenTimer?.cancel();
        }
      }
    });
  }

  int _lastMinIndex = 0;
  void _scrollListener() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final positions = _itemPositionsListener.itemPositions.value;
      if (positions.isEmpty) return;

      final minIndex = positions
          .map((p) => p.index)
          .reduce((a, b) => a < b ? a : b);

      final bool isAtBottom = minIndex == 0;

      final bool isScrollingDown = minIndex < _lastMinIndex;
      final bool isScrollingUp = minIndex > _lastMinIndex;

      if (isScrollingDown && !isAtBottom) {
        _showScrollButtonNotifier.value = true;
      } else if (isScrollingUp && _unreadCountNotifier.value == 0) {
        _showScrollButtonNotifier.value = false;
      } else if (isAtBottom) {
        _showScrollButtonNotifier.value = false;
        _unreadCountNotifier.value = 0;
        context.read<ChatDetailsCubit>().markAsRead(
          senderId: widget.receiverUser.id,
        );
      }

      context.read<ChatDetailsCubit>().setUserAtBottom(isAtBottom);
      _lastMinIndex = minIndex;
    });
  }

  void _scrollToBottom() {
    if (_itemScrollController.isAttached) {
      _itemScrollController
          .scrollTo(
            index: 0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          )
          .then((_) {
            if (mounted) {
              _showScrollButtonNotifier.value = false;
              _unreadCountNotifier.value = 0;

              _itemScrollController.jumpTo(index: 0);
            }
          });
      _unreadCountNotifier.value = 0;
    }
  }

  @override
  void dispose() {
    ActiveScreenTracker.setActiveChatReceiver(null);
    _lastSeenTimer?.cancel();
    _itemPositionsListener.itemPositions.removeListener(_scrollListener);
    _messageController.dispose();
    super.dispose();
  }

  Widget _buildStatusWidget(ChatDetailsState state) {
    if (state is ReceiverTypingState && state.isTyping) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text('typing ', style: TextStyle(fontSize: 11, color: Colors.green)),
          TypingIndicatorWidget(color: Colors.green),
        ],
      );
    }
    final lastSeen =
        state is LastSeenUpdated
            ? state.lastSeen
            : widget.receiverUser.lastSeen;
    if (lastSeen != null) {
      final text = FormattedDate.getLastSeen(lastSeen);
      if (text == 'Online') {
        return const Text(
          'Online',
          style: TextStyle(
            fontSize: 12,
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        );
      }
      return Text(
        'last seen $text',
        style: const TextStyle(fontSize: 11, color: Colors.grey),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundThemeWidget(
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: AppColors.transparent,

          body: Column(
            children: [
              ReceiverDetailsHeaderSection(
                receiverUser: widget.receiverUser,
                statusBuilder: (state) => _buildStatusWidget(state),
              ),
              Expanded(
                child: MessagesListView(
                  receiverUser: widget.receiverUser,
                  itemScrollController: _itemScrollController,
                  itemPositionsListener: _itemPositionsListener,
                  onReply: (msg) => setState(() => _replyTo = msg),
                  showScrollButtonNotifier: _showScrollButtonNotifier,
                  unreadCountNotifier: _unreadCountNotifier,
                  scrollToBottom: _scrollToBottom,
                ),
              ),
              TextInputAreaSection(
                receiverUser: widget.receiverUser,
                messageController: _messageController,
                replyTo: _replyTo,
                onCancelReply: () => setState(() => _replyTo = null),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
