import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/toast/app_toast.dart';
import 'package:social_media_app/features/chat_forwarding/models/forward_target_selection.dart';
import 'package:social_media_app/features/chat_forwarding/models/forwardable_message.dart';
import 'package:social_media_app/features/chat_forwarding/services/forward_service.dart';
import 'package:social_media_app/features/chat_forwarding/views/forward_target_picker_view.dart';
import '../../../core/widgets/multi_select_app_bar.dart';
import '../cubit/group_details_cubit/group_details_cubit.dart';
import '../models/group_model.dart';
import '../widgets/group_chat_app_bar.dart';

class GroupChatAppBarSwitcher extends StatelessWidget
    implements PreferredSizeWidget {
  final GroupModel group;

  const GroupChatAppBarSwitcher({super.key, required this.group});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _showComingSoon(String feature) {
    AppToast.info('$feature is coming soon');
  }

  Future<void> _openForwardPicker(
    BuildContext context, {
    required int messageCount,
  }) async {
    final cubit = context.read<GroupDetailsCubit>();

    final result = await Navigator.of(context).push<ForwardTargetSelection>(
      MaterialPageRoute(
        builder: (_) => ForwardTargetPickerView(messageCount: messageCount),
      ),
    );
    if (result == null || result.isEmpty) return;

    final selectedMessages = cubit.selectedMessages;
    final currentUserId = cubit.currentUserId;
    cubit.clearSelection();

    final forwardableMessages =
        selectedMessages
            .map((m) => ForwardableMessage.fromGroupMessage(m))
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
    final cubit = context.read<GroupDetailsCubit>();

    return ValueListenableBuilder<Set<String>>(
      valueListenable: cubit.selectedMessageIds,
      builder: (context, selectedIds, _) {
        if (selectedIds.isEmpty) {
          return GroupChatAppBar(group: group);
        }

        return ValueListenableBuilder<bool>(
          valueListenable: cubit.starController.isSelectedStarred,
          builder: (context, isStarred, __) {
            return MultiSelectChatAppBar(
              selectedCount: selectedIds.length,
              onCancel: cubit.clearSelection,
              actions: [
                if (selectedIds.length == 1)
                  MultiSelectAction(
                    icon:
                        isStarred
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                    color: isStarred ? Colors.amber : null,
                    tooltip: isStarred ? 'Unstar' : 'Star',
                    onPressed: cubit.toggleStarSelected,
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
                  onPressed: () => _showBulkDeleteMenu(context, cubit),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBulkDeleteMenu(BuildContext context, GroupDetailsCubit cubit) {
    final canDeleteForEveryone = cubit.canDeleteSelectedForEveryone;
    final count = cubit.selectedMessageIds.value.length;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
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
}
