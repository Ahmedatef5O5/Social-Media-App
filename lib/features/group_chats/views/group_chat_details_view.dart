import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:social_media_app/core/mentions/widgets/mention_text_editing_controller.dart';
import '../../../core/services/active_screen_tracker.dart';
import '../../group_calls/cubit/group_call_cubit/group_call_cubit.dart';
import '../../group_calls/cubit/group_call_cubit/group_call_state.dart';
import '../cubit/group_details_cubit/group_details_cubit.dart';
import '../cubit/group_list_cubit/group_list_cubit.dart';
import '../helpers/group_chat_app_bar_switcher.dart';
import '../models/group_model.dart';
import '../../group_calls/services/group_call_signaling_service.dart';
import '../widgets/group_chat_input_bar_section.dart';
import '../widgets/group_chat_locked_banner.dart';
import '../widgets/group_messages_list.dart';

class GroupChatDetailsView extends StatelessWidget {
  final GroupModel group;
  const GroupChatDetailsView({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) =>
              GroupCallCubit(context.read<GroupCallSignalingService>())
                ..watchActiveCall(group.id),
      child: _GroupChatDetailsBody(group: group),
    );
  }
}

class _GroupChatDetailsBody extends StatefulWidget {
  final GroupModel group;
  const _GroupChatDetailsBody({required this.group});

  @override
  State<_GroupChatDetailsBody> createState() => _GroupChatDetailsBodyState();
}

class _GroupChatDetailsBodyState extends State<_GroupChatDetailsBody> {
  final _controller = MentionTextEditingController();

  final ItemScrollController _scrollController = ItemScrollController();
  final ItemPositionsListener _positionsListener =
      ItemPositionsListener.create();

  final ValueNotifier<bool> _showScrollButtonNotifier = ValueNotifier(false);

  final TextEditingController _searchTextController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  int? _lastMinIndex;
  double? _lastLeadingEdge;
  // ignore: unused_field
  bool _isCurrentlyAtBottom = true;
  late GroupListCubit _groupListCubit;
  late GroupDetailsCubit _groupDetailsCubit;

  @override
  void initState() {
    super.initState();

    _groupListCubit = context.read<GroupListCubit>();
    _groupDetailsCubit = context.read<GroupDetailsCubit>();
    context.read<GroupListCubit>().setActiveGroupId(widget.group.id);
    context.read<GroupDetailsCubit>().markRead();

    ActiveScreenTracker.setActiveGroupId(widget.group.id);
    _positionsListener.itemPositions.addListener(_scrollListener);
    _groupDetailsCubit.searchController.currentIndex.addListener(
      _onSearchMatchChanged,
    );
    _groupDetailsCubit.searchController.isActive.addListener(
      _onSearchActiveChanged,
    );
    _groupDetailsCubit.replyToMessage.addListener(_onReplyChanged);
  }

  void _onSearchMatchChanged() {
    final id = _groupDetailsCubit.searchController.currentMatchId;
    if (id == null || !_scrollController.isAttached) return;
    _groupDetailsCubit.scrollToMessage(
      messageId: id,
      itemScrollController: _scrollController,
    );
  }

  void _onReplyChanged() {
    if (_groupDetailsCubit.replyToMessage.value != null &&
        _groupDetailsCubit.searchController.isActive.value) {
      _groupDetailsCubit.searchController.deactivate();
    }
  }

  void _onSearchActiveChanged() {
    if (!_groupDetailsCubit.searchController.isActive.value) {
      _searchTextController.clear();
    }
  }

  void _exitSearch() {
    _groupDetailsCubit.searchController.deactivate();
  }

  void _markAsReadIfNeeded() {
    _groupDetailsCubit.markRead();
  }

  static const double _bottomEdgeTolerance = 0.05;

  bool _computeIsAtBottom(Iterable<ItemPosition> positions) {
    if (positions.isEmpty) return true;
    final minPosition = positions.reduce((a, b) => a.index < b.index ? a : b);
    return minPosition.index == 0 &&
        minPosition.itemLeadingEdge >= -_bottomEdgeTolerance;
  }

  void _scrollListener() {
    if (!mounted) return;

    final positions = _positionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    final minPosition = positions.reduce((a, b) => a.index < b.index ? a : b);
    final int minIndex = minPosition.index;
    final double leadingEdge = minPosition.itemLeadingEdge;

    final bool isAtBottom = _computeIsAtBottom(positions);

    if (isAtBottom) {
      _isCurrentlyAtBottom = true;
      _showScrollButtonNotifier.value = false;
      _lastMinIndex = minIndex;
      _lastLeadingEdge = leadingEdge;

      if (!_groupDetailsCubit.isClosed) {
        _groupDetailsCubit.setUserAtBottom(true);
        _groupDetailsCubit.flushPendingMessages();
      }

      _markAsReadIfNeeded();
      _groupListCubit.resetGroupUnreadCount(widget.group.id);
      return;
    }

    _isCurrentlyAtBottom = false;
    if (!_groupDetailsCubit.isClosed) {
      _groupDetailsCubit.setUserAtBottom(false);
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
      if (_groupDetailsCubit.pendingNewCountNotifier.value == 0) {
        _showScrollButtonNotifier.value = false;
      }
    }

    _lastMinIndex = minIndex;
    _lastLeadingEdge = leadingEdge;
  }

  bool _isAtBottom() =>
      _computeIsAtBottom(_positionsListener.itemPositions.value);

  void _scrollToBottom() {
    if (_scrollController.isAttached) {
      _scrollController
          .scrollTo(
            index: 0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          )
          .then((_) {
            if (mounted) {
              _showScrollButtonNotifier.value = false;
              _lastMinIndex = 0;
              _lastLeadingEdge = null;
              _isCurrentlyAtBottom = true;

              if (!_groupDetailsCubit.isClosed) {
                _groupDetailsCubit.flushPendingMessages();
              }
              _groupListCubit.resetGroupUnreadCount(widget.group.id);
              _markAsReadIfNeeded();
            }
          });
    }
  }

  @override
  void dispose() {
    _groupDetailsCubit.markRead();
    _groupListCubit.resetGroupUnreadCount(widget.group.id);

    _groupListCubit.setActiveGroupId(null);
    ActiveScreenTracker.setActiveGroupId(null);

    _positionsListener.itemPositions.removeListener(_scrollListener);
    _controller.dispose();
    _showScrollButtonNotifier.dispose();
    if (!_groupDetailsCubit.isClosed) {
      _groupDetailsCubit.clearSelection();
      _groupDetailsCubit.searchController.currentIndex.removeListener(
        _onSearchMatchChanged,
      );
      _groupDetailsCubit.searchController.isActive.removeListener(
        _onSearchActiveChanged,
      );
      _groupDetailsCubit.replyToMessage.removeListener(_onReplyChanged);
    }
    _searchTextController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GroupDetailsCubit>();

    return BlocListener<GroupDetailsCubit, GroupDetailsState>(
      listenWhen: (previous, current) {
        final prevMember =
            previous is GroupDetailsLoaded ? previous.isMember : true;
        final currMember =
            current is GroupDetailsLoaded ? current.isMember : true;
        return prevMember && !currMember;
      },
      listener: (context, state) {
        FocusManager.instance.primaryFocus?.unfocus();
        cubit.clearSelection();
      },
      child: BlocListener<GroupCallCubit, GroupCallState>(
        listener: (context, state) {
          if (state is GroupCallEnded) {}
        },
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: GroupChatAppBarSwitcher(
              group: widget.group,
              itemScrollController: _scrollController,
              searchTextController: _searchTextController,
              searchFocusNode: _searchFocusNode,
              onExitSearch: _exitSearch,
            ),
            body: Column(
              children: [
                Expanded(
                  child: GroupMessagesList(
                    scrollController: _scrollController,
                    positionsListener: _positionsListener,
                    showScrollButtonNotifier: _showScrollButtonNotifier,
                    scrollToBottom: _scrollToBottom,
                    isAtBottom: _isAtBottom,
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    top: false,
                    child: BlocBuilder<GroupDetailsCubit, GroupDetailsState>(
                      buildWhen: (previous, current) {
                        final prevMember =
                            previous is GroupDetailsLoaded
                                ? previous.isMember
                                : true;
                        final currMember =
                            current is GroupDetailsLoaded
                                ? current.isMember
                                : true;
                        return prevMember != currMember;
                      },
                      builder: (context, state) {
                        final isMember =
                            state is GroupDetailsLoaded
                                ? state.isMember
                                : widget.group.isMember;

                        if (!isMember) {
                          return const GroupChatLockedBanner();
                        }

                        return GroupChatInputBarSection(
                          controller: _controller,
                          mentionCandidateIds:
                              widget.group.members
                                  .map((m) => m.userId)
                                  .toList(),
                          onSend: (text, mentions) {
                            cubit.sendMessage(text: text, mentions: mentions);
                            _scrollToBottom();
                          },
                          onTyping: cubit.onTyping,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
