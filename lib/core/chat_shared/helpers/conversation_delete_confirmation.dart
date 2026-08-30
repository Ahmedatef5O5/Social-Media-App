import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../features/group_chats/cubits/group_list_cubit/group_list_cubit.dart';
import '../../../features/single_chats/cubits/chats_cubit/chats_cubit.dart';
import '../cubits/conversation_selection_cubit/conversation_selection_cubit.dart';
import '../models/conversation_ref.dart';

Future<void> confirmAndDeleteConversations(
  BuildContext context,
  Set<ConversationRef> refs,
) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder:
        (dialogContext) => AlertDialog(
          title: Text(
            'Delete ${refs.length} chat${refs.length > 1 ? 's' : ''}?',
          ),
          content: const Text(
            'This clears the chat history on this device only. '
            'Other participants keep their own copy.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
  );

  if (confirm != true) return;
  if (!context.mounted) return;

  final singleIds =
      refs
          .where((r) => r.type == ConversationType.single)
          .map((r) => r.id)
          .toSet();
  final groupIds =
      refs
          .where((r) => r.type == ConversationType.group)
          .map((r) => r.id)
          .toSet();

  if (singleIds.isNotEmpty) {
    await context.read<ChatsCubit>().clearChatsLocally(singleIds);
  }
  if (groupIds.isNotEmpty) {
    await context.read<GroupListCubit>().clearChatsLocally(groupIds);
  }
  if (context.mounted) {
    context.read<ConversationSelectionCubit>().clear();
  }
}
