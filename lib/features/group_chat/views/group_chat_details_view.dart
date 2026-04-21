import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../cubit/group_details_cubit/group_details_cubit.dart';
import '../models/group_model.dart';
import '../widgets/group_chat_app_bar.dart';
import '../widgets/group_chat_input_bar_section.dart';
import '../widgets/messages_list.dart';

class GroupChatDetailsView extends StatefulWidget {
  final GroupModel group;
  const GroupChatDetailsView({super.key, required this.group});

  @override
  State<GroupChatDetailsView> createState() => _GroupChatDetailsViewState();
}

class _GroupChatDetailsViewState extends State<GroupChatDetailsView> {
  final _controller = TextEditingController();
  final _scrollController = ItemScrollController();
  final _positionsListener = ItemPositionsListener.create();

  void _scrollToBottom() {
    if (_scrollController.isAttached) {
      _scrollController.jumpTo(index: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GroupDetailsCubit>();

    return GestureDetector(
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
              ),
            ),

            GroupChatInputBarSection(
              controller: _controller,
              onSend: (text) {
                cubit.sendMessage(text: text);
                _controller.clear();
                _scrollToBottom();
              },
              onTyping: cubit.onTyping,
            ),
          ],
        ),
      ),
    );
  }
}
