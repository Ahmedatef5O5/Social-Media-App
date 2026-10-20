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
import 'package:social_media_app/core/localization/l10n_extension.dart';

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
            title: Text(context.l10n.unblockUser),
            content: Text(context.l10n.unblockTheyWillBe(item.user.name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  context.l10n.unblock,
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
              SettingsDetailSliverAppBar(
                icon: Icons.block_outlined,
                title: context.l10n.settingsBlockedUsers,
                subtitle: context.l10n.manageTheAccountsYouve,
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
