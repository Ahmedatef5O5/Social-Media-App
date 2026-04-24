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
import '../../../core/router/app_router.dart';
import '../../../core/services/active_screen_tracker.dart';
import '../../../core/services/notification_services.dart';
import '../../../core/themes/app_colors.dart';
import '../models/presence_snapshot.dart';
import '../widgets/text_input_area_section.dart';
import '../widgets/typing_indicator_widget.dart';

class ChatDetailsView extends StatefulWidget {
  final ChatUserModel receiverUser;

  const ChatDetailsView({super.key, required this.receiverUser});

  @override
  State<ChatDetailsView> createState() => _ChatDetailsViewState();
}

class _ChatDetailsViewState extends State<ChatDetailsView>
    with WidgetsBindingObserver, RouteAware {
  late final TextEditingController _messageController;

  late bool _isOnlineCache;
  DateTime? _lastSeenCache;
  bool _isTypingCache = false;

  Timer? _lastSeenTimer;
  MessageModel? _replyTo;

  final ValueNotifier<bool> _showScrollButtonNotifier = ValueNotifier(false);
  final ValueNotifier<int> _unreadCountNotifier = ValueNotifier(0);

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  late final String _receiverId;

  @override
  void initState() {
    super.initState();
    _isOnlineCache = widget.receiverUser.isOnline;
    _lastSeenCache = widget.receiverUser.lastSeen;
    _receiverId = widget.receiverUser.id;
    _messageController = TextEditingController();

    WidgetsBinding.instance.addObserver(this);

    ActiveScreenTracker.setActiveChatReceiver(_receiverId);

    NotificationService.instance.cancelNotificationsForSender(_receiverId);

    _itemPositionsListener.itemPositions.addListener(_scrollListener);

    final cubit = context.read<ChatDetailsCubit>();

    cubit.watchReceiverPresence(
      _receiverId,
      initial: PresenceSnapshot(
        isOnline: widget.receiverUser.isOnline,
        lastSeen: widget.receiverUser.lastSeen,
      ),
    );
    cubit.getMessagesStream(receiverId: _receiverId);
    cubit.updateLastSeen();

    _lastSeenTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted) {
        _lastSeenTimer?.cancel();
        return;
      }

      try {
        final cubit = context.read<ChatDetailsCubit>();
        if (!cubit.isClosed) {
          cubit.updateLastSeen();
        } else {
          _lastSeenTimer?.cancel();
        }
      } catch (e) {
        _lastSeenTimer?.cancel();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPop() {
    if (mounted) {
      context.read<ChatDetailsCubit>().markAsRead(senderId: _receiverId);
    }
  }

  @override
  void didPopNext() {
    if (_isAtBottom()) {
      context.read<ChatDetailsCubit>().markAsRead(senderId: _receiverId);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      if (_isAtBottom()) {
        context.read<ChatDetailsCubit>().markAsRead(senderId: _receiverId);
      }
      context.read<ChatDetailsCubit>().updateLastSeen();
    }
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
        if (mounted) {
          context.read<ChatDetailsCubit>().markAsRead(senderId: _receiverId);
        }
      }

      context.read<ChatDetailsCubit>().setUserAtBottom(isAtBottom);
      _lastMinIndex = minIndex;
    });
  }

  bool _isAtBottom() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return true;

    final minIndex = positions
        .map((p) => p.index)
        .reduce((a, b) => a < b ? a : b);

    return minIndex == 0;
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
  @override
  void dispose() {
    _lastSeenTimer?.cancel();
    _lastSeenTimer = null;

    _itemPositionsListener.itemPositions.removeListener(_scrollListener);
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);

    ActiveScreenTracker.setActiveChatReceiver(null);
    _messageController.dispose();
    _showScrollButtonNotifier.dispose();
    _unreadCountNotifier.dispose();

    super.dispose();
  }

  Widget _buildStatusWidget(ChatDetailsState state) {
    if (state is ReceiverTypingState) {
      _isTypingCache = state.isTyping;
    } else if (state is ReceiverPresenceUpdated) {
      _isOnlineCache = state.isOnline;
      if (state.lastSeen != null) {
        _lastSeenCache = state.lastSeen;
      }
    } else if (state is LastSeenUpdated) {
      if (state.lastSeen != null) {
        _lastSeenCache = state.lastSeen;
      }
    }

    if (_isTypingCache) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('typing ', style: TextStyle(fontSize: 11, color: Colors.green)),
          TypingIndicatorWidget(color: Colors.green),
        ],
      );
    }

    String? lastSeenText;
    if (_lastSeenCache != null) {
      lastSeenText = FormattedDate.getLastSeen(_lastSeenCache!);
    }

    final isActuallyOnline =
        _isOnlineCache ||
        lastSeenText == 'Online' ||
        lastSeenText == 'just now';

    if (isActuallyOnline) {
      return const Text(
        'Online',
        style: TextStyle(
          fontSize: 12,
          color: Colors.green,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    if (lastSeenText != null && lastSeenText.isNotEmpty) {
      return Text(
        'last seen $lastSeenText',
        style: const TextStyle(fontSize: 11, color: Colors.grey),
      );
    }

    return const Text(
      'Offline',
      style: TextStyle(fontSize: 11, color: Colors.grey),
    );
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
                  onReply: (msg) {
                    if (mounted) setState(() => _replyTo = msg);
                  },
                  showScrollButtonNotifier: _showScrollButtonNotifier,
                  unreadCountNotifier: _unreadCountNotifier,
                  scrollToBottom: _scrollToBottom,
                ),
              ),
              TextInputAreaSection(
                receiverUser: widget.receiverUser,
                messageController: _messageController,
                replyTo: _replyTo,
                onCancelReply: () {
                  if (mounted) setState(() => _replyTo = null);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
