import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/helpers/formatted_date.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import '../cubit/group_list_cubit/group_list_cubit.dart';
import '../models/group_model.dart';

class GroupsListView extends StatefulWidget {
  const GroupsListView({super.key});

  @override
  State<GroupsListView> createState() => _GroupsListViewState();
}

class _GroupsListViewState extends State<GroupsListView> {
  @override
  void initState() {
    super.initState();
    context.read<GroupListCubit>().monitorGroups();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<GroupListCubit, GroupListState>(
      builder: (context, state) {
        if (state is GroupListLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is GroupListError) {
          return Center(child: Text(state.message));
        }
        if (state is GroupListLoaded) {
          if (state.groups.isEmpty) {
            return _buildEmptyState(context, primary);
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            itemCount: state.groups.length,
            separatorBuilder:
                (_, __) => Divider(
                  height: 1,
                  indent: 80,
                  color:
                      isDark
                          ? Colors.white12
                          : Colors.black.withValues(alpha: 0.06),
                ),
            itemBuilder: (_, index) => _GroupTile(group: state.groups[index]),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, Color primary) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.group_rounded,
            size: 80,
            color: primary.withValues(alpha: 0.3),
          ),
          const Gap(16),
          Text(
            'No groups yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: primary.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(8),
          Text(
            'Tap + to create your first group',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  final GroupModel group;
  const _GroupTile({required this.group});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasAvatar = group.avatarUrl != null && group.avatarUrl!.isNotEmpty;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: primary.withValues(alpha: 0.12),
        backgroundImage:
            hasAvatar ? CachedNetworkImageProvider(group.avatarUrl!) : null,
        child:
            hasAvatar
                ? null
                : Text(
                  group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
      ),
      title: Text(
        group.name,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle:
          group.lastMessage != null
              ? Text(
                _buildLastMessagePreview(group),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 13,
                ),
              )
              : Text(
                'Tap to open group chat',
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 13,
                ),
              ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (group.lastMessageAt != null)
            Text(
              FormattedDate.getMessageTime(group.lastMessageAt!),
              style: TextStyle(
                color:
                    group.unreadCount > 0
                        ? primary
                        : (isDark ? Colors.white38 : Colors.black38),
                fontSize: 11,
              ),
            ),
          if (group.unreadCount > 0) ...[
            const Gap(4),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
              child: Text(
                group.unreadCount > 99 ? '99+' : '${group.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: () {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushNamed(AppRoutes.groupChatRoute, arguments: group);
      },
    );
  }

  String _buildLastMessagePreview(GroupModel group) {
    final type = group.lastMessageType ?? 'text';
    final text = group.lastMessage ?? '';
    switch (type) {
      case 'image':
        return '📷 Photo';
      case 'video':
        return '🎬 Video';
      case 'voice':
        return '🎤 Voice message';
      case 'call':
        return '📞 Call';
      default:
        return text;
    }
  }
}
