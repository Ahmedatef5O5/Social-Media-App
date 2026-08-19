import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import '../../../core/chat_shared/cubits/conversations_cubit/conversations_cubit.dart';
import '../../../core/widgets/custom_badge.dart';
import '../../group_chats/cubit/group_list_cubit/group_list_cubit.dart';
import '../cubit/chats_cubit/chats_cubit.dart';

class MessagesHeaderSection extends StatelessWidget {
  final bool isDark;
  final Color primary;
  final TabController tabController;

  const MessagesHeaderSection({
    super.key,
    required this.isDark,
    required this.primary,
    required this.tabController,
  });

  static const List<String> _tabTitles = [
    'All',
    'Chats',
    'Groups',
    'Favorites',
    'Unread',
  ];

  void _openArchivedChats(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pushNamed(
      AppRoutes.archivedChatsViewRoute,
      arguments: context.read<ConversationsCubit>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final archivedUnreadCount =
        context.watch<ConversationsCubit>().archivedUnreadCount;
    final hasArchivedConversations =
        context.watch<ConversationsCubit>().hasArchivedConversations;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Messages',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder:
                        (child, animation) => ScaleTransition(
                          scale: animation,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        ),
                    child:
                        hasArchivedConversations
                            ? CustomBadge(
                              count: archivedUnreadCount,
                              size: 15,
                              fontSize: 8.2,
                              top: 4.2,
                              right: 4.2,
                              child: IconButton(
                                icon: Icon(
                                  Icons.archive_outlined,
                                  color: Theme.of(context).primaryColor,
                                  size: 24,
                                ),
                                tooltip: 'Archived chats',
                                onPressed: () => _openArchivedChats(context),
                              ),
                            )
                            : const SizedBox.shrink(),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.smart_toy_rounded,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),

                    tooltip: 'Syncra AI',
                    onPressed: () {
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushNamed(AppRoutes.aiChatViewRoute);
                    },
                  ),
                  Gap(4),
                  AnimatedBuilder(
                    animation: tabController,
                    builder: (context, child) {
                      final tab = ConversationTab.values[tabController.index];
                      final showNewChat = tab != ConversationTab.groups;
                      final showCreateGroup = tab != ConversationTab.chats;
                      return PopupMenuButton<String>(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (value) async {
                          if (value == 'create_group') {
                            await Navigator.of(
                              context,
                              rootNavigator: true,
                            ).pushNamed(AppRoutes.createGroupRoute);

                            if (context.mounted) {
                              context.read<GroupListCubit>().loadGroups(
                                isRefresh: true,
                              );
                            }
                          } else if (value == 'new_chat') {
                            await Navigator.of(
                              context,
                              rootNavigator: true,
                            ).pushNamed(AppRoutes.newChatViewRoute);
                            if (context.mounted) {
                              context.read<ChatsCubit>().getChats(
                                isRefresh: true,
                              );
                              context.read<GroupListCubit>().loadGroups(
                                isRefresh: true,
                              );
                            }
                          }
                        },
                        itemBuilder:
                            (context) => [
                              if (showNewChat)
                                PopupMenuItem(
                                  value: 'new_chat',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.chat_bubble_outline,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('New Chat'),
                                    ],
                                  ),
                                ),
                              if (showCreateGroup)
                                PopupMenuItem(
                                  value: 'create_group',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.group_add,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Create Group'),
                                    ],
                                  ),
                                ),
                            ],
                        child: Icon(
                          Icons.more_vert_outlined,
                          color: Theme.of(context).primaryColor,
                          size: 26,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          TabBar(
            controller: tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: EdgeInsets.zero,
            indicator: const BoxDecoration(),
            dividerColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            splashBorderRadius: BorderRadius.circular(25),
            labelPadding: const EdgeInsets.only(right: 8),
            tabs: List.generate(
              _tabTitles.length,
              (i) => _TabItem(
                controller: tabController,
                title: _tabTitles[i],
                tab: ConversationTab.values[i],
                index: i,
                primary: primary,
                isDark: isDark,
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final TabController controller;
  final String title;
  final ConversationTab tab;
  final int index;
  final Color primary;
  final bool isDark;

  const _TabItem({
    required this.controller,
    required this.title,
    required this.tab,
    required this.index,
    required this.primary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.watch<ConversationsCubit>().unreadCountFor(tab);

    return AnimatedBuilder(
      animation: controller.animation ?? controller,
      builder: (context, _) {
        final double value =
            controller.animation?.value ?? controller.index.toDouble();
        final double distance = (value - index).abs();
        final double progress = (1.0 - distance).clamp(0.0, 1.0);

        final activeDecoration = BoxDecoration(
          gradient: LinearGradient(
            colors: [primary, primary.withValues(alpha: 0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.transparent, width: 1),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.35),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        );

        final inactiveDecoration = BoxDecoration(
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.035),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.08),
            width: 1,
          ),
        );

        final textColor = Color.lerp(
          isDark ? Colors.white60 : Colors.black54,
          Colors.white,
          progress,
        );

        final fontWeight = progress > 0.5 ? FontWeight.w700 : FontWeight.w500;

        return Container(
          height: 40,
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration.lerp(
            inactiveDecoration,
            activeDecoration,
            progress,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (unreadCount > 0)
                ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Opacity(
                      opacity: progress,
                      child: _TabUnreadBadge(
                        count: unreadCount,
                        activeColor: primary,
                      ),
                    ),
                  ),
                ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: fontWeight,
                  color: textColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TabUnreadBadge extends StatelessWidget {
  final int count;
  final Color activeColor;

  const _TabUnreadBadge({required this.count, required this.activeColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Container(
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Text(
          count > 99 ? '99+' : '$count',
          style: TextStyle(
            color: activeColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
