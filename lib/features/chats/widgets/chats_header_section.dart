import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/custom_header_widget.dart';

class ChatsHeaderSection extends StatelessWidget {
  const ChatsHeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomHeader(
      title: 'Chats',
      actions: const Icon(
        Icons.more_vert_outlined,
        color: AppColors.black54,
        size: 26,
      ),
    );
  }
}
