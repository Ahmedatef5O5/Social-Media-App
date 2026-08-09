import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../features/group_chats/widgets/group_tile_item_widget.dart';
import '../../../features/single_chats/widgets/chat_item_tile.dart';
import '../../../features/single_chats/widgets/empty_placeholder_state.dart';
import '../../constants/app_images.dart';
import '../../themes/app_colors.dart';
import '../../widgets/custom_loading_indicator.dart';
import '../cubits/conversations_cubit/conversations_cubit.dart';
import '../models/conversation_item.dart';

class ConversationsTabBody extends StatefulWidget {
  final ConversationTab tab;
  const ConversationsTabBody({super.key, required this.tab});

  @override
  State<ConversationsTabBody> createState() => _ConversationsTabBodyState();
}

class _ConversationsTabBodyState extends State<ConversationsTabBody>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _emptyMessageFor(ConversationTab tab) {
    switch (tab) {
      case ConversationTab.all:
        return 'No conversations yet.';
      case ConversationTab.chats:
        return 'No chats yet.';
      case ConversationTab.groups:
        return 'No groups yet.';
      case ConversationTab.favorites:
        return 'No favorite chats yet.';
      case ConversationTab.unread:
        return 'No unread chats.';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: BlocBuilder<ConversationsCubit, ConversationsState>(
        builder: (context, state) {
          if (state is! ConversationsLoaded) {
            return const CustomLoadingIndicator();
          }

          final items = context.read<ConversationsCubit>().filtered(widget.tab);

          if (items.isEmpty) {
            return EmptyPlaceholderState(
              img: AppImages.blueSmileFaceLot,
              imgHeight: MediaQuery.of(context).size.height * 0.2,
              title: _emptyMessageFor(widget.tab),
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 100),
            physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return item.kind == ConversationKind.single
                  ? ChatItemTile(
                    user: item.chat!,
                    isPinned: item.isPinned,
                    isFavorite: item.isFavorite,
                    isMuted: item.isMuted,
                  )
                  : GroupTileItem(
                    group: item.group!,
                    isPinned: item.isPinned,
                    isFavorite: item.isFavorite,
                  );
            },
            separatorBuilder:
                (_, __) => const Divider(color: AppColors.black12),
          );
        },
      ),
    );
  }
}
