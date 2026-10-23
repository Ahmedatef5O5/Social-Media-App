import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:social_media_app/core/chat_shared/widgets/chat_search_app_bar.dart';
import 'package:social_media_app/core/toast/app_toast.dart';
import 'package:social_media_app/features/chat_forwarding/models/forward_target_selection.dart';
import 'package:social_media_app/features/chat_forwarding/models/forwardable_message.dart';
import 'package:social_media_app/features/chat_forwarding/services/forward_service.dart';
import 'package:social_media_app/features/chat_forwarding/views/forward_target_picker_view.dart';
import '../../../core/chat_shared/views/message_info_view.dart';
import '../../../core/chat_shared/widgets/message_selection_header_bar.dart';
import '../../ai_chat/views/ai_chat_view.dart';
import '../../single_chats/cubits/chats_cubit/chats_cubit.dart';
import '../cubits/group_details_cubit/group_details_cubit.dart';
import '../cubits/group_list_cubit/group_list_cubit.dart';
import '../models/group_model.dart';
import '../models/groupe_message_model.dart';
import '../widgets/group_chat_app_bar.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';
import 'package:social_media_app/core/localization/app_l10n.dart';

class GroupChatAppBarSwitcher extends StatelessWidget
    implements PreferredSizeWidget {
  final GroupModel group;
  final ItemScrollController itemScrollController;
  final TextEditingController searchTextController;
  final FocusNode searchFocusNode;
  final VoidCallback onExitSearch;

  const GroupChatAppBarSwitcher({
    super.key,
    required this.group,
    required this.itemScrollController,
    required this.searchTextController,
    required this.searchFocusNode,
    required this.onExitSearch,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

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

    if (result.toAi) {
      if (selectedMessages.length == 1) {
        final msg = selectedMessages.first;

        if (msg.messageType == 'image' && (msg.imageUrl?.isNotEmpty ?? false)) {
          if (context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (_) => AiChatView(
                      initialDraftImageRemoteUrl: msg.imageUrl,
                      initialDraftImageCaption: msg.caption,
                    ),
              ),
            );
          }
          return;
        }

        if (msg.messageType == 'file' && (msg.fileUrl?.isNotEmpty ?? false)) {
          if (context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (_) => AiChatView(
                      initialDraftFileRemoteUrl: msg.fileUrl,
                      initialDraftFileName: msg.fileName,
                      initialDraftFileCaption: msg.caption,
                    ),
              ),
            );
          }
          return;
        }
      }

      final draftText = selectedMessages
          .map((m) => m.text.trim())
          .where((t) => t.isNotEmpty)
          .join('\n\n');

      if (draftText.isEmpty) {
        if (context.mounted) {
          AppToast.info(context.l10n.syncraCantReadMedia);
        }
        return;
      }
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AiChatView(initialDraftText: draftText),
          ),
        );
      }
      return;
    }

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
        AppToast.info(AppL10n.current.forwardedToChatS(result.length));
        Future.delayed(const Duration(milliseconds: 400), () {
          if (context.mounted) {
            context.read<ChatsCubit>().getChats(isRefresh: true);
            context.read<GroupListCubit>().loadGroups(isRefresh: true);
          }
        });
      }
    } catch (e) {
      if (context.mounted) AppToast.info(context.l10n.failedToForwardTry);
    }
  }

  void _openMessageInfo(BuildContext context, GroupDetailsCubit cubit) {
    final selected = cubit.selectedMessages;
    if (selected.length != 1) return;
    final message = selected.first;
    cubit.clearSelection();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => MessageInfoView(
              args: MessageInfoArgs.fromGroupChat(
                message: message,
                group: group,
                currentUserId: cubit.currentUserId,
              ),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GroupDetailsCubit>();

    return ValueListenableBuilder<bool>(
      valueListenable: cubit.searchController.isActive,
      builder: (context, isSearching, _) {
        if (isSearching) {
          return ValueListenableBuilder<List<String>>(
            valueListenable: cubit.searchController.matchIds,
            builder: (context, matches, __) {
              return ChatSearchAppBar(
                controller: searchTextController,
                focusNode: searchFocusNode,
                onChanged: (q) => cubit.searchController.updateQuery(q),
                counterTextNotifier: cubit.searchController.counterTextNotifier,
                hasMatches: matches.isNotEmpty,
                onPrevious: () => cubit.searchController.previousMatch(),
                onNext: () => cubit.searchController.nextMatch(),
                onClose: onExitSearch,
              );
            },
          );
        }

        return ValueListenableBuilder<Set<String>>(
          valueListenable: cubit.selectedMessageIds,
          builder: (context, selectedIds, _) {
            if (selectedIds.isEmpty) {
              return GroupChatAppBar(
                group: group,
                itemScrollController: itemScrollController,
              );
            }

            return ValueListenableBuilder<bool>(
              valueListenable: cubit.starController.isSelectedStarred,
              builder: (context, isStarred, __) {
                return MessageSelectionHeaderBar(
                  selectedCount: selectedIds.length,
                  onCancel: cubit.clearSelection,
                  showStar: selectedIds.length == 1,
                  isStarred: isStarred,
                  onStarToggle: cubit.toggleStarSelected,
                  onInfoTap: () => _openMessageInfo(context, cubit),
                  onForwardTap:
                      () => _openForwardPicker(
                        context,
                        messageCount: selectedIds.length,
                      ),
                  showCopy: _canCopySelectedMessage(cubit.selectedMessages),
                  onCopyTap: () => _copySelectedMessage(context, cubit),
                  onDeleteTap: () => _showBulkDeleteMenu(context, cubit),
                );
              },
            );
          },
        );
      },
    );
  }

  bool _canCopySelectedMessage(List<GroupMessageModel> selected) =>
      selected.length == 1 && selected.first.messageType == 'text';

  Future<void> _copySelectedMessage(
    BuildContext context,
    GroupDetailsCubit cubit,
  ) async {
    final selected = cubit.selectedMessages;
    if (selected.length != 1) return;
    await Clipboard.setData(ClipboardData(text: selected.first.text));
    if (context.mounted) AppToast.success(context.l10n.copiedToClipboard);
    cubit.clearSelection();
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
                    context.l10n.deleteNMessages(count),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(context.l10n.deleteForMe),
                  onTap: () {
                    Navigator.pop(ctx);
                    cubit.deleteSelectedForMe();
                  },
                ),
                if (canDeleteForEveryone)
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: Text(
                      context.l10n.deleteForEveryone,
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
