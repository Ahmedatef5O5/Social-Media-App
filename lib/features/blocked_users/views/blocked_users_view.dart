import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/router/app_routes.dart';
import '../../settings/widgets/settings_detail_sliver_app_bar.dart';
import '../../single_chats/models/chat_user_model.dart';
import '../cubits/blocked_users_cubit/blocked_users_cubit.dart';
import '../models/blocked_user_item_model.dart';
import '../widgets/blocked_user_tile.dart';
import '../widgets/blocked_users_empty_state.dart';
import '../widgets/blocked_users_skeleton.dart';

class BlockedUsersView extends StatefulWidget {
  const BlockedUsersView({super.key});

  @override
  State<BlockedUsersView> createState() => _BlockedUsersViewState();
}

class _BlockedUsersViewState extends State<BlockedUsersView> {
  @override
  void initState() {
    super.initState();
    context.read<BlockedUsersCubit>().fetchBlockedUsers();
  }

  void _openChat(BlockedUserItemModel item) {
    Navigator.of(context, rootNavigator: true).pushNamed(
      AppRoutes.chatDetailsViewRoute,
      arguments: ChatUserModel.fromEntity(item.user),
    );
  }

  Future<void> _confirmUnblock(BlockedUserItemModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Unblock User'),
            content: Text(
              'Unblock ${item.user.name}? They will be able to message you again.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Unblock',
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ),
            ],
          ),
    );
    if (confirmed == true && mounted) {
      context.read<BlockedUsersCubit>().unblockUser(item.user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocBuilder<BlockedUsersCubit, BlockedUsersState>(
        builder: (context, state) {
          return CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              const SettingsDetailSliverAppBar(
                icon: Icons.block_outlined,
                title: 'Blocked Users',
                subtitle: "Manage the accounts you've blocked",
              ),
              if (state is BlockedUsersLoading || state is BlockedUsersInitial)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: BlockedUsersSkeleton(),
                  ),
                )
              else if (state is BlockedUsersError)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text(state.message)),
                )
              else if (state is BlockedUsersLoaded)
                state.items.isEmpty
                    ? const SliverFillRemaining(
                      hasScrollBody: false,
                      child: BlockedUsersEmptyState(),
                    )
                    : SliverPadding(
                      padding: const EdgeInsets.only(bottom: 100),
                      sliver: SliverList.builder(
                        itemCount: state.items.length,
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          return BlockedUserTile(
                            item: item,
                            onTap: () => _openChat(item),
                            onUnblock: () => _confirmUnblock(item),
                          );
                        },
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }
}
