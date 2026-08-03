import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:social_media_app/core/chat_shared/widgets/chat_search_app_bar.dart';
import 'package:social_media_app/core/themes/background_theme_widget.dart';
import 'package:social_media_app/features/chat_forwarding/models/forward_target_selection.dart';
import 'package:social_media_app/features/chat_forwarding/models/forwardable_message.dart';
import 'package:social_media_app/features/chat_forwarding/services/forward_service.dart';
import 'package:social_media_app/features/chat_forwarding/views/forward_target_picker_view.dart';
import 'package:social_media_app/features/single_chats/cubit/chat_details_cubit/chat_details_cubit.dart';
import 'package:social_media_app/features/single_chats/models/chat_user_model.dart';
import 'package:social_media_app/features/single_chats/models/message_model.dart';
import 'package:social_media_app/features/single_chats/services/chat_services.dart';
import 'package:social_media_app/features/single_chats/widgets/messages_list_view.dart';
import 'package:social_media_app/features/single_chats/widgets/receiver_details_header_section.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/active_screen_tracker.dart';
import '../../../core/services/notification_services.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/toast/app_toast.dart';
import '../../../core/widgets/multi_select_app_bar.dart';
import '../services/chat_permission_service.dart';
import '../widgets/text_input_area_section.dart';

class ChatDetailsView extends StatefulWidget {
  final ChatUserModel receiverUser;

  const ChatDetailsView({super.key, required this.receiverUser});

  @override
  State<ChatDetailsView> createState() => _ChatDetailsViewState();
}

class _ChatDetailsViewState extends State<ChatDetailsView>
    with WidgetsBindingObserver, RouteAware {
  late final TextEditingController _messageController;
  late final ChatDetailsCubit _chatCubit;

  MessageModel? _replyTo;

  final ValueNotifier<bool> _showScrollButtonNotifier = ValueNotifier(false);
  final ValueNotifier<int> _unreadCountNotifier = ValueNotifier(0);

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  late final String _receiverId;

  MessageModel? _editingMessage;

  final TextEditingController _searchTextController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _receiverId = widget.receiverUser.id;
    _messageController = TextEditingController();

    WidgetsBinding.instance.addObserver(this);
    ActiveScreenTracker.setActiveChatReceiver(_receiverId);
    NotificationService.instance.cancelNotificationsForSender(_receiverId);

    _itemPositionsListener.itemPositions.addListener(_scrollListener);

    _chatCubit = context.read<ChatDetailsCubit>();
    _chatCubit.resolveChatPermission(_receiverId);
    _chatCubit.getMessagesStream(receiverId: _receiverId);
    _chatCubit.watchReceiverTyping(_receiverId);
    _chatCubit.searchController.currentIndex.addListener(_onSearchMatchChanged);
    _chatCubit.searchController.isActive.addListener(_onSearchActiveChanged);
  }

  void _onSearchMatchChanged() {
    final id = _chatCubit.searchController.currentMatchId;
    if (id == null || !_itemScrollController.isAttached) return;
    _chatCubit.scrollToMessage(
      messageId: id,
      itemScrollController: _itemScrollController,
    );
  }

  void _onSearchActiveChanged() {
    if (!_chatCubit.searchController.isActive.value) {
      _searchTextController.clear();
    }
  }

  void _exitSearch() {
    _chatCubit.searchController.deactivate();
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
    if (mounted && !_chatCubit.isClosed) {
      _chatCubit.markAsRead(senderId: _receiverId);
    }
  }

  @override
  void didPopNext() {
    if (_isAtBottom() && !_chatCubit.isClosed) {
      _chatCubit.markAsRead(senderId: _receiverId);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || _chatCubit.isClosed) return;
    if (state == AppLifecycleState.resumed) {
      if (_isAtBottom()) {
        _chatCubit.markAsRead(senderId: _receiverId);
      }
    }
  }

  int? _lastMinIndex;
  double? _lastLeadingEdge;
  // ignore: unused_field
  bool _isCurrentlyAtBottom = true;

  void _scrollListener() {
    if (!mounted) return;

    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    final minPosition = positions.reduce((a, b) => a.index < b.index ? a : b);
    final int minIndex = minPosition.index;
    final double leadingEdge = minPosition.itemLeadingEdge;

    final bool isAtBottom = minIndex == 0;

    if (isAtBottom) {
      _isCurrentlyAtBottom = true;
      _showScrollButtonNotifier.value = false;
      _unreadCountNotifier.value = 0;
      if (!_chatCubit.isClosed) {
        _chatCubit.markAsRead(senderId: _receiverId);
        _chatCubit.setUserAtBottom(true);
      }
      _lastMinIndex = minIndex;
      _lastLeadingEdge = leadingEdge;
      return;
    }

    _isCurrentlyAtBottom = false;
    if (!_chatCubit.isClosed) {
      _chatCubit.setUserAtBottom(false);
    }

    if (_lastMinIndex == null || _lastLeadingEdge == null) {
      _lastMinIndex = minIndex;
      _lastLeadingEdge = leadingEdge;
      return;
    }

    bool goingTowardNewer = false;
    bool goingTowardOlder = false;

    if (minIndex < _lastMinIndex!) {
      goingTowardNewer = true;
    } else if (minIndex > _lastMinIndex!) {
      goingTowardOlder = true;
    } else {
      if (leadingEdge > _lastLeadingEdge! + 0.01) {
        goingTowardNewer = true;
      } else if (leadingEdge < _lastLeadingEdge! - 0.01) {
        goingTowardOlder = true;
      }
    }

    if (goingTowardNewer) {
      _showScrollButtonNotifier.value = true;
    } else if (goingTowardOlder) {
      if (_unreadCountNotifier.value == 0) {
        _showScrollButtonNotifier.value = false;
      }
    }

    _lastMinIndex = minIndex;
    _lastLeadingEdge = leadingEdge;
  }

  bool _isAtBottom() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return true;
    return positions.map((p) => p.index).reduce((a, b) => a < b ? a : b) == 0;
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
              _lastMinIndex = 0;
              _lastLeadingEdge = null;
              _isCurrentlyAtBottom = true;
            }
          });
      _unreadCountNotifier.value = 0;
    }
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_scrollListener);
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);

    ActiveScreenTracker.setActiveChatReceiver(null);
    _messageController.dispose();
    _showScrollButtonNotifier.dispose();
    _unreadCountNotifier.dispose();
    if (!_chatCubit.isClosed) {
      _chatCubit.clearSelection();
      _chatCubit.searchController.currentIndex.removeListener(
        _onSearchMatchChanged,
      );
      _chatCubit.searchController.isActive.removeListener(
        _onSearchActiveChanged,
      );
    }
    _searchTextController.dispose();
    _searchFocusNode.dispose();

    super.dispose();
  }

  void _showBulkDeleteMenu(BuildContext context, ChatDetailsCubit cubit) {
    final canDeleteForEveryone = cubit.canDeleteSelectedForEveryone;
    final count = cubit.selectedMessageIds.value.length;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      builder:
          (ctx) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Delete $count message${count > 1 ? 's' : ''}?',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Delete for me'),
                  onTap: () {
                    Navigator.pop(ctx);
                    cubit.deleteSelectedForMe();
                  },
                ),
                if (canDeleteForEveryone)
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: Text(
                      'Delete for everyone',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium!.copyWith(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      cubit.deleteSelectedForEveryone();
                    },
                  ),
              ],
            ),
          ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    AppToast.info('$feature is coming soon');
  }

  Future<void> _openForwardPicker(
    BuildContext context, {
    required int messageCount,
  }) async {
    final result = await Navigator.of(context).push<ForwardTargetSelection>(
      MaterialPageRoute(
        builder: (_) => ForwardTargetPickerView(messageCount: messageCount),
      ),
    );
    if (result == null || result.isEmpty) return;

    final selectedMessages = _chatCubit.selectedMessages;
    final currentUserId = _chatCubit.currentUserId;
    _chatCubit.clearSelection();

    final currentUserInfo = await ChatServices().getCurrentUserInfo(
      currentUserId,
    );

    final forwardableMessages =
        selectedMessages
            .map(
              (m) => ForwardableMessage.fromSingleChatMessage(
                m,
                currentUserId: currentUserId,
                currentUserName: currentUserInfo['name'] ?? 'You',
                currentUserAvatar: currentUserInfo['imageUrl'],
                otherUserName: widget.receiverUser.name,
                otherUserAvatar: widget.receiverUser.imageUrl,
              ),
            )
            .toList();

    try {
      await ForwardService().forwardMessages(
        messages: forwardableMessages,
        targets: result,
        currentUserId: currentUserId,
      );
      if (context.mounted) {
        AppToast.info('Forwarded to ${result.length} chat(s)');
      }
    } catch (e) {
      if (context.mounted) AppToast.info('Failed to forward. Try again.');
    }
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
              ValueListenableBuilder<bool>(
                valueListenable: _chatCubit.searchController.isActive,
                builder: (context, isSearching, _) {
                  if (isSearching) {
                    return ValueListenableBuilder<List<String>>(
                      valueListenable: _chatCubit.searchController.matchIds,
                      builder: (context, matches, __) {
                        return ChatSearchAppBar(
                          controller: _searchTextController,
                          focusNode: _searchFocusNode,
                          onChanged:
                              (q) => _chatCubit.searchController.updateQuery(q),
                          counterTextNotifier:
                              _chatCubit.searchController.counterTextNotifier,
                          hasMatches: matches.isNotEmpty,
                          onPrevious:
                              () => _chatCubit.searchController.previousMatch(),
                          onNext: () => _chatCubit.searchController.nextMatch(),
                          onClose: _exitSearch,
                        );
                      },
                    );
                  }

                  return ValueListenableBuilder<Set<String>>(
                    valueListenable: _chatCubit.selectedMessageIds,
                    builder: (context, selectedIds, _) {
                      if (selectedIds.isEmpty) {
                        return ReceiverDetailsHeaderSection(
                          receiverUser: widget.receiverUser,
                          itemScrollController: _itemScrollController,
                        );
                      }
                      return ValueListenableBuilder<bool>(
                        valueListenable:
                            _chatCubit.starController.isSelectedStarred,
                        builder: (context, isStarred, __) {
                          return MultiSelectChatAppBar(
                            selectedCount: selectedIds.length,
                            onCancel: _chatCubit.clearSelection,
                            actions: [
                              if (selectedIds.length == 1)
                                MultiSelectAction(
                                  icon:
                                      isStarred
                                          ? Icons.star_rounded
                                          : Icons.star_border_rounded,
                                  color: isStarred ? Colors.amber : null,
                                  tooltip: isStarred ? 'Unstar' : 'Star',
                                  onPressed: _chatCubit.toggleStarSelected,
                                ),
                              MultiSelectAction(
                                icon: Icons.info_outline,
                                tooltip: 'Info',
                                onPressed:
                                    () => _showComingSoon(context, 'Info'),
                              ),
                              MultiSelectAction(
                                icon: Icons.forward_rounded,
                                tooltip: 'Forward',
                                onPressed:
                                    () => _openForwardPicker(
                                      context,
                                      messageCount: selectedIds.length,
                                    ),
                              ),
                              MultiSelectAction(
                                icon: Icons.delete_outline,
                                color: Colors.red,
                                tooltip: 'Delete',
                                onPressed:
                                    () => _showBulkDeleteMenu(
                                      context,
                                      _chatCubit,
                                    ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
              Expanded(
                child: MessagesListView(
                  receiverUser: widget.receiverUser,
                  itemScrollController: _itemScrollController,
                  itemPositionsListener: _itemPositionsListener,
                  onReply: (msg) {
                    if (mounted) {
                      setState(() {
                        _replyTo = msg;
                        if (_editingMessage != null) {
                          _editingMessage = null;
                          _messageController.clear();
                        }
                      });
                      // Auto-dismiss search mode (swipe/menu reply both
                      // funnel through this same callback).
                      if (_chatCubit.searchController.isActive.value) {
                        _exitSearch();
                      }
                    }
                  },
                  onEdit: (msg) {
                    setState(() {
                      _editingMessage = msg;
                      _replyTo = null;
                      _messageController.text = msg.caption ?? msg.text;
                      _messageController.selection = TextSelection.collapsed(
                        offset: _messageController.text.length,
                      );
                    });
                  },
                  showScrollButtonNotifier: _showScrollButtonNotifier,
                  unreadCountNotifier: _unreadCountNotifier,
                  scrollToBottom: _scrollToBottom,
                ),
              ),

              ValueListenableBuilder<ChatPermissionResult>(
                valueListenable: _chatCubit.chatPermission,
                builder: (context, result, _) {
                  if (result.permission == ChatPermission.allowed) {
                    return const SizedBox.shrink();
                  }
                  final isAwaitingMe =
                      result.permission == ChatPermission.awaitingMyResponse;
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAwaitingMe
                              ? '${widget.receiverUser} sent you a message request. Reply to accept, or decline.'
                              : 'You are not friends or followers. Sending a message will send a message request.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (isAwaitingMe) ...[
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () async {
                                await _chatCubit.declineMessageRequest();
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                              child: const Text('Decline'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              TextInputAreaSection(
                receiverUser: widget.receiverUser,
                messageController: _messageController,
                replyTo: _replyTo,
                editingMessage: _editingMessage,
                onCancelReply: () {
                  if (mounted) setState(() => _replyTo = null);
                },
                onEditCancelled: () {
                  if (mounted) {
                    setState(() => _editingMessage = null);
                    _messageController.clear();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
