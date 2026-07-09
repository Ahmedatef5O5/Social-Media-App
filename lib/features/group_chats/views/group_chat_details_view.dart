import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../core/services/active_screen_tracker.dart';
import '../../group_calls/cubit/group_call_cubit/group_call_cubit.dart';
import '../../group_calls/cubit/group_call_cubit/group_call_state.dart';
import '../cubit/group_details_cubit/group_details_cubit.dart';
import '../cubit/group_list_cubit/group_list_cubit.dart';
import '../models/group_model.dart';
import '../../group_calls/services/group_call_signaling_service.dart';
import '../widgets/group_chat_app_bar.dart';
import '../widgets/group_chat_input_bar_section.dart';
import '../widgets/messages_list.dart';

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
  final _controller = TextEditingController();

  final ItemScrollController _scrollController = ItemScrollController();
  final ItemPositionsListener _positionsListener =
      ItemPositionsListener.create();

  final ValueNotifier<bool> _showScrollButtonNotifier = ValueNotifier(false);
  final ValueNotifier<int> _unreadCountNotifier = ValueNotifier(0);

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
  }

  void _markAsReadIfNeeded() {
    _groupDetailsCubit.markRead();
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
    _unreadCountNotifier.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (!mounted) return;

    final positions = _positionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    final minPosition = positions.reduce((a, b) => a.index < b.index ? a : b);
    final int minIndex = minPosition.index;
    final double leadingEdge = minPosition.itemLeadingEdge;

    final bool isAtBottom = minIndex == 0;

    if (isAtBottom) {
      _isCurrentlyAtBottom = true;
      _showScrollButtonNotifier.value = false;
      _unreadCountNotifier.value = 0;
      _lastMinIndex = minIndex;
      _lastLeadingEdge = leadingEdge;

      // update unread count
      _markAsReadIfNeeded();
      _groupListCubit.resetGroupUnreadCount(widget.group.id);
      return;
    }

    _isCurrentlyAtBottom = false;

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
    final positions = _positionsListener.itemPositions.value;
    if (positions.isEmpty) return true;
    return positions.map((p) => p.index).reduce((a, b) => a < b ? a : b) == 0;
  }

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
              _unreadCountNotifier.value = 0;
              _lastMinIndex = 0;
              _lastLeadingEdge = null;
              _isCurrentlyAtBottom = true;

              _groupListCubit.resetGroupUnreadCount(widget.group.id);
              _markAsReadIfNeeded();
            }
          });
      _unreadCountNotifier.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GroupDetailsCubit>();

    return BlocListener<GroupCallCubit, GroupCallState>(
      listener: (context, state) {
        if (state is GroupCallEnded) {}
      },
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: GroupChatAppBar(group: widget.group),
          body: Column(
            children: [
              Expanded(
                child: GroupMessagesList(
                  scrollController: _scrollController,
                  positionsListener: _positionsListener,
                  showScrollButtonNotifier: _showScrollButtonNotifier,
                  unreadCountNotifier: _unreadCountNotifier,
                  scrollToBottom: _scrollToBottom,
                  isAtBottom: _isAtBottom,
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  top: false,
                  child: GroupChatInputBarSection(
                    controller: _controller,
                    onSend: (text) {
                      cubit.sendMessage(text: text);
                      _controller.clear();
                      _scrollToBottom();
                    },
                    onTyping: cubit.onTyping,
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
