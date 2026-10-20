import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../features/group_chats/cubits/group_list_cubit/group_list_cubit.dart';
import '../../../features/single_chats/cubits/chats_cubit/chats_cubit.dart';
import '../cubits/conversation_selection_cubit/conversation_selection_cubit.dart';
import '../models/conversation_ref.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

Future<void> confirmAndDeleteConversations(
  BuildContext context,
  Set<ConversationRef> refs,
) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder:
        (dialogContext) => AlertDialog(
          title: Text(context.l10n.deleteNChats(refs.length)),
          content: Text(context.l10n.thisClearsTheChat),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                context.l10n.delete,
                style: TextStyle(color: Colors.red),
              ),
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
