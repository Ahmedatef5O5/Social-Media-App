import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../cubit/group_details_cubit/group_details_cubit.dart';
import '../models/groupe_message_model.dart';

class GroupMessageMenuSheet {
  static void show({
    required BuildContext context,
    required GroupMessageModel message,
    required Function(GroupMessageModel) onReply,
    required Color primary,
  }) {
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;
    final cubit = context.read<GroupDetailsCubit>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children:
                    ['👍', '❤️', '😂', '😮', '😢', '😡'].map((emoji) {
                      final myReaction = message.reactions[currentUserId];
                      final isSelected = myReaction == emoji;

                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          cubit.toggleReaction(
                            messageId: message.id,
                            emoji: emoji,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? primary.withValues(alpha: 0.2)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border:
                                isSelected
                                    ? Border.all(color: primary, width: 1.5)
                                    : null,
                          ),
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                      );
                    }).toList(),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.reply_all_outlined),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(ctx);
                  onReply(message);
                },
              ),
              if (message.senderId == currentUserId)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    cubit.deleteMessage(message.id);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
