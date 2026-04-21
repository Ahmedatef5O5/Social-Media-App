import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../group_chat/cubit/group_list_cubit/group_list_cubit.dart';
import '../../group_chat/services/group_chat_services.dart';
import '../../group_chat/views/create_group_view.dart';

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
                  final isGroupsTab = tabController.index == 1;
                  return PopupMenuButton<String>(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) {
                      if (value == 'create_group') {
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                            builder:
                                (_) => BlocProvider(
                                  create:
                                      (_) =>
                                          GroupListCubit(GroupChatServices()),
                                  child: const CreateGroupView(),
                                ),
                          ),
                        );
                      } else if (value == 'new_chat') {}
                    },
                    itemBuilder: (context) {
                      if (isGroupsTab) {
                        return [
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
                        ];
                      } else {
                        return [
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
                        ];
                      }
                    },
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
            indicator: const BoxDecoration(),
            dividerColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            overlayColor: WidgetStatePropertyAll(Colors.transparent),
            splashBorderRadius: BorderRadius.circular(25),
            labelPadding: const EdgeInsets.symmetric(horizontal: 6),
            tabs: [
              _TabItem(
                controller: tabController,
                title: 'Chats',
                index: 0,
                primary: primary,
                isDark: isDark,
              ),
              _TabItem(
                controller: tabController,
                title: 'Groups',
                index: 1,
                primary: primary,
                isDark: isDark,
              ),
            ],
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
