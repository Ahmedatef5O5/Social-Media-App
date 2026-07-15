import 'package:flutter/material.dart';
import '../../../core/mentions/widgets/mention_text_editing_controller.dart';
import '../cubit/group_details_cubit/group_details_cubit.dart';
import '../models/groupe_message_model.dart';
import 'group_edit_preview_bar_widget.dart';

class GroupEditPreviewSection extends StatelessWidget {
  final GroupDetailsCubit cubit;
  final MentionTextEditingController controller;

  const GroupEditPreviewSection({
    super.key,
    required this.cubit,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GroupMessageModel?>(
      valueListenable: cubit.editingMessage,
      builder: (_, editing, __) {
        if (editing == null) return const SizedBox();
        return GroupEditPreviewBar(
          message: editing,
          onDismiss: () {
            cubit.editingMessage.value = null;
            controller.clear();
          },
        );
      },
    );
  }
}
