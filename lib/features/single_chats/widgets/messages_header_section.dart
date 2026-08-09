import 'package:flutter/material.dart';
import 'package:social_media_app/core/router/app_routes.dart';

import '../../../core/chat_shared/cubits/conversations_cubit/conversations_cubit.dart';

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    onSelected: (value) {
                      if (value == 'create_group') {
                        Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pushNamed(AppRoutes.createGroupRoute);
                      } else if (value == 'new_chat') {}
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
          const SizedBox(height: 20),

          TabBar(
            controller: tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicator: const BoxDecoration(),
            dividerColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            splashBorderRadius: BorderRadius.circular(25),
            labelPadding: const EdgeInsets.symmetric(horizontal: 6),
            tabs: List.generate(
              _tabTitles.length,
              (i) => _TabItem(
                controller: tabController,
                title: _tabTitles[i],
                index: i,
                primary: primary,
                isDark: isDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final TabController controller;
  final String title;
  final int index;
  final Color primary;
  final bool isDark;

  const _TabItem({
    required this.controller,

    required this.title,
    required this.index,
    required this.primary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final isActive = controller.index == index;

        return Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:
                isActive ? primary.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color:
                  isActive
                      ? primary.withValues(alpha: 0.35)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.12)),
              width: 1,
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color:
                  isActive
                      ? primary
                      : (isDark ? Colors.white60 : Colors.black54),
            ),
          ),
        );
      },
    );
  }
}
