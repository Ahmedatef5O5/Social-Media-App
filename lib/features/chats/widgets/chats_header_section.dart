import 'package:flutter/material.dart';
import '../../../core/widgets/custom_header_widget.dart';

class ChatsHeaderSection extends StatelessWidget {
  const ChatsHeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomHeader(
      title: 'Chats',
      actions: Icon(
        Icons.more_vert_outlined,
        color: Theme.of(context).primaryColor,
        size: 26,
      ),
    );
  }
}
