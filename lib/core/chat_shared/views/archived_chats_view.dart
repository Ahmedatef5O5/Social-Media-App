import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../constants/app_images.dart';
import '../../themes/app_colors.dart';
import '../../widgets/custom_loading_indicator.dart';
import '../cubits/conversation_selection_cubit/conversation_selection_cubit.dart';
import '../cubits/conversations_cubit/conversations_cubit.dart';
import '../helpers/conversation_delete_confirmation.dart';
import '../models/conversation_item.dart';
import '../../../features/group_chats/widgets/group_tile_item_widget.dart';
import '../../../features/single_chats/widgets/chat_item_tile.dart';
import '../../../features/single_chats/widgets/empty_placeholder_state.dart';
import '../widgets/archived_selection_header_bar.dart';

class ArchivedChatsView extends StatefulWidget {
  const ArchivedChatsView({super.key});

  @override
  State<ArchivedChatsView> createState() => _ArchivedChatsViewState();
}

class _ArchivedChatsViewState extends State<ArchivedChatsView> {
  late final ConversationSelectionCubit _selectionCubit;

  @override
  void initState() {
    super.initState();
    _selectionCubit = ConversationSelectionCubit();
  }

  @override
  void dispose() {
    _selectionCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _selectionCubit,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: BlocBuilder<
            ConversationSelectionCubit,
            ConversationSelectionState
          >(
            builder: (context, selection) {
              final refs = selection.selectedRefs;

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final slide = Tween<Offset>(
                    begin: const Offset(0, -0.2),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: slide, child: child),
                  );
                },
                child:
                    selection.isSelecting
                        ? ArchivedSelectionHeaderBar(
                          key: const ValueKey('archive_selection'),
                          selectedRefs: refs,
                          onCancel:
                              () =>
                                  context
                                      .read<ConversationSelectionCubit>()
                                      .clear(),
                          onDelete:
                              () =>
                                  confirmAndDeleteConversations(context, refs),
                        )
                        : AppBar(
                          key: const ValueKey('archive_normal'),
                          title: const Text('Archived Chats'),
                        ),
              );
            },
          ),
        ),
        body: BlocBuilder<ConversationsCubit, ConversationsState>(
          builder: (context, state) {
            if (state is! ConversationsLoaded) {
              return const CustomLoadingIndicator();
            }

            final items = state.archivedItems;

            if (items.isEmpty) {
              return EmptyPlaceholderState(
                img: AppImages.blueSmileFaceLot,
                imgHeight: MediaQuery.of(context).size.height * 0.2,
                title: 'No archived chats.',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 8),

              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return item.kind == ConversationKind.single
                    ? ChatItemTile(
                      user: item.chat!,
                      isPinned: item.flags.isPinnedInArchive,
                      isFavorite: item.isFavorite,
                      isMuted: item.isMuted,
                      enableHero: false,
                    )
                    : GroupTileItem(
                      group: item.group!,
                      isPinned: item.flags.isPinnedInArchive,
                      isFavorite: item.isFavorite,
                    );
              },
              separatorBuilder:
                  (_, __) => const Divider(color: AppColors.black12),
            );
          },
        ),
      ),
    );
  }
}
