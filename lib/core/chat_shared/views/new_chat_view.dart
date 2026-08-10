import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/router/app_routes.dart';
import '../../../features/group_chats/cubit/group_list_cubit/group_list_cubit.dart';
import '../../../features/single_chats/cubit/chats_cubit/chats_cubit.dart';
import '../helpers/avatar_stack.dart';
import '../../../features/home/cubits/home_cubit/home_cubit.dart';
import '../../../features/search/utils/chat_tile_skeleton_list.dart';
import '../../../features/single_chats/models/chat_user_model.dart';
import '../cubits/new_chat_cubit/new_chat_cubit.dart';
import '../models/new_chat_list_item.dart';
import '../models/new_chat_row.dart';
import '../widgets/new_chat_contact_tile.dart';
import '../widgets/new_chat_group_tile.dart';

class NewChatView extends StatefulWidget {
  const NewChatView({super.key});

  @override
  State<NewChatView> createState() => _NewChatViewState();
}

class _NewChatViewState extends State<NewChatView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openChat(BuildContext context, NewChatListItem item) async {
    if (item.isGroup) {
      await Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamed(AppRoutes.groupChatRoute, arguments: item.group);

      if (context.mounted) {
        context.read<GroupListCubit>().loadGroups(isRefresh: true);
      }
    } else {
      final chatUser = ChatUserModel.fromEntity(item.person!);
      await Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamed(AppRoutes.chatDetailsViewRoute, arguments: chatUser);

      if (context.mounted) {
        context.read<ChatsCubit>().getChats(isRefresh: true);
      }
    }
  }

  Widget _buildPremiumEmptyState(BuildContext context) {
    final query = _searchController.text.trim();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (query.isNotEmpty) {
      return Center(
        child: Text(
          'No results found for "$query"',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey,
            fontSize: 15,
          ),
        ),
      );
    }

    final dummyAvatars = List.generate(
      28,
      (index) => 'https://i.pravatar.cc/150?img=${(index % 70) + 12}',
    );

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
              child: Icon(
                Icons.people_alt_rounded,
                size: 65,
                color: theme.primaryColor.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Grow Your Network',
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
                'You haven\'t added any connections yet.\nDiscover people nearby or explore suggested profiles to start chatting.',
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
                  onTap: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    final navController =
                        context.read<HomeCubit>().navController;
                    if (navController != null) {
                      navController.jumpToTab(1);
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
                            imageUrls: dummyAvatars,
                            maxVisible: 7,
                            avatarSize: 30,
                            overlapOffset: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Discover People',
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
                            Icons.person_search_rounded,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          shadowColor: Colors.transparent,
          title: const Text('New Chat'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: TextField(
                controller: _searchController,
                onChanged: (q) => context.read<NewChatCubit>().search(q),
                decoration: InputDecoration(
                  hintText: 'Search friends & groups...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(
                    CupertinoIcons.search,
                    color: Colors.grey,
                  ),
                  filled: true,
                  fillColor:
                      theme.brightness == Brightness.dark
                          ? Colors.grey.shade900
                          : Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              size: 18,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              context.read<NewChatCubit>().search('');
                              setState(() {});
                            },
                          )
                          : null,
                ),
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
              ),
            ),
            Expanded(
              child: BlocBuilder<NewChatCubit, NewChatState>(
                builder: (context, state) {
                  return switch (state) {
                    NewChatInitial() || NewChatLoading() => const Center(
                      child: ChatTileSkeletonList(),
                    ),
                    NewChatError(:final message) => Center(
                      child: Text(message),
                    ),
                    NewChatLoaded(:final rows) =>
                      rows.isEmpty
                          ? _buildPremiumEmptyState(context)
                          : ListView.builder(
                            itemCount: rows.length,
                            itemBuilder: (context, index) {
                              final row = rows[index];

                              if (row is NewChatSectionHeaderRow) {
                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    16,
                                    16,
                                    6,
                                  ),
                                  child: Text(
                                    row.title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).hintColor,
                                    ),
                                  ),
                                );
                              }

                              final itemRow = row as NewChatItemRow;
                              final item = itemRow.item;

                              return item.isGroup
                                  ? NewChatGroupTile(
                                    key: ValueKey('g_${item.id}'),
                                    group: item.group!,
                                    isBlocked: itemRow.isBlocked,
                                    onTap: () => _openChat(context, item),
                                  )
                                  : NewChatContactTile(
                                    key: ValueKey('p_${item.id}'),
                                    user: item.person!,
                                    isBlocked: itemRow.isBlocked,
                                    onTap: () => _openChat(context, item),
                                  );
                            },
                          ),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
