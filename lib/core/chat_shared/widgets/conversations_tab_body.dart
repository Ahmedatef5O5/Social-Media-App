import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import '../../../core/router/app_routes.dart';
import '../../../features/group_chats/cubits/group_list_cubit/group_list_cubit.dart';
import '../../../features/single_chats/cubits/chats_cubit/chats_cubit.dart';
import '../helpers/avatar_stack.dart';
import '../../../features/group_chats/widgets/group_tile_item_widget.dart';
import '../../../features/single_chats/widgets/chat_item_tile.dart';
import '../../constants/app_images.dart';
import '../../themes/app_colors.dart';
import '../../widgets/custom_loading_indicator.dart';
import '../cubits/conversations_cubit/conversations_cubit.dart';
import '../models/conversation_item.dart';

class ConversationsTabBody extends StatefulWidget {
  final ConversationTab tab;
  final TabController tabController;

  const ConversationsTabBody({
    super.key,
    required this.tab,
    required this.tabController,
  });

  @override
  State<ConversationsTabBody> createState() => _ConversationsTabBodyState();
}

class _ConversationsTabBodyState extends State<ConversationsTabBody>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final int _tabIndex = ConversationTab.values.indexOf(widget.tab);

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
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: BlocBuilder<ConversationsCubit, ConversationsState>(
        builder: (context, state) {
          if (state is! ConversationsLoaded) {
            return const CustomLoadingIndicator();
          }

          final items = context.read<ConversationsCubit>().filtered(widget.tab);

          if (items.isEmpty) {
            final dummyAvatars = List.generate(
              32,
              (index) => 'https://i.pravatar.cc/150?img=${(index % 70) + 1}',
            );

            return _InteractiveEmptyState(
              title: _emptyMessageFor(widget.tab),
              avatarUrls: dummyAvatars,
              tab: widget.tab,
            );
          }

          return AnimatedBuilder(
            animation: widget.tabController,
            builder: (context, _) {
              final isActiveTab = widget.tabController.index == _tabIndex;

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
                        enableHero: isActiveTab,
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
          );
        },
      ),
    );
  }
}

class _InteractiveEmptyState extends StatelessWidget {
  final String title;
  final List<String> avatarUrls;
  final ConversationTab tab;

  const _InteractiveEmptyState({
    required this.title,
    required this.avatarUrls,
    required this.tab,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isGroupTab = tab == ConversationTab.groups;

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primaryColor.withValues(alpha: 0.04),
              ),
              child: RepaintBoundary(
                child: Lottie.asset(
                  AppImages.blueSmileFaceLot,
                  height: MediaQuery.of(context).size.height * 0.13,
                  repeat: true,
                  delegates: LottieDelegates(
                    values: [
                      ValueDelegate.colorFilter(
                        ['**'],
                        value: ColorFilter.mode(
                          Theme.of(context).primaryColor,
                          BlendMode.srcIn,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              title,
              style: theme.textTheme.headlineSmall!.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 44),
              child: Text(
                isGroupTab
                    ? 'Bring your friends together.\nCreate a space to share moments.'
                    : 'Your inbox is waiting.\nStart a conversation and explore new connections.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontSize: 14.5,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 40),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    if (isGroupTab) {
                      await Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushNamed(AppRoutes.createGroupRoute);
                      if (context.mounted) {
                        context.read<GroupListCubit>().loadGroups(
                          isRefresh: true,
                        );
                      }
                    } else {
                      await Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushNamed(AppRoutes.newChatViewRoute);
                      if (context.mounted) {
                        context.read<ChatsCubit>().getChats(isRefresh: true);
                        context.read<GroupListCubit>().loadGroups(
                          isRefresh: true,
                        );
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(100),
                  highlightColor: theme.primaryColor.withValues(alpha: 0.05),
                  splashColor: theme.primaryColor.withValues(alpha: 0.1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color:
                            isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.05),
                        width: 1,
                      ),
                      boxShadow:
                          isDark
                              ? null
                              : [
                                BoxShadow(
                                  color: theme.primaryColor.withValues(
                                    alpha: 0.08,
                                  ),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: AvatarStack(
                            imageUrls: avatarUrls,
                            maxVisible: 7,
                            avatarSize: 30,
                            overlapOffset: 18,
                          ),
                        ),
                        const SizedBox(width: 12),

                        Text(
                          isGroupTab ? 'Create Group' : 'Start Chat',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 16),

                        Container(
                          height: 36,
                          width: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.primaryColor,
                            boxShadow: [
                              BoxShadow(
                                color: theme.primaryColor.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 4,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
