import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/themes/cubit/theme_cubit.dart';
import '../../chats/views/chats_list_skeleton.dart';
import '../cubit/group_list_cubit/group_list_cubit.dart';
import '../models/group_model.dart';

class GroupsListViewBody extends StatefulWidget {
  const GroupsListViewBody({super.key});

  @override
  State<GroupsListViewBody> createState() => _GroupsListViewBodyState();
}

class _GroupsListViewBodyState extends State<GroupsListViewBody>
    with WidgetsBindingObserver, RouteAware {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final currentState = context.read<GroupListCubit>().state;
    if (currentState is! GroupListLoaded && currentState is! GroupListLoading) {
      context.read<GroupListCubit>().loadGroups();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<GroupListCubit>().loadGroups(isRefresh: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GroupListCubit, GroupListState>(
      builder: (context, state) {
        if (state is GroupListLoaded) {
          if (state.groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.group_outlined,
                    size: 72,
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.3),
                  ),
                  const Gap(12),
                  Text(
                    'No groups yet.\nTap + to create one!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 6, bottom: 100),
            itemCount: state.groups.length,
            separatorBuilder:
                (_, __) =>
                    const Divider(color: Colors.black12, height: 1, indent: 76),
            itemBuilder: (context, index) {
              return _GroupListTile(group: state.groups[index]);
            },
          );
        } else if (state is GroupListLoading || state is GroupListInitial) {
          return const ChatsListSkeleton();
        } else if (state is GroupListError) {
          return Center(child: Text(state.message));
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}

class _GroupListTile extends StatelessWidget {
  final GroupModel group;
  const _GroupListTile({required this.group});

  String _buildSubtitle() {
    if (group.lastMessage == null || group.lastMessage!.isEmpty) {
      return 'No messages yet';
    }
    final type = group.lastMessageType ?? 'text';
    final text = group.lastMessage!;
    switch (type) {
      case 'image':
        return '📷 ${text.isNotEmpty ? text : "Photo"}';
      case 'video':
        return '🎥 ${text.isNotEmpty ? text : "Video"}';
      case 'voice':
        return '🎤 Voice message';
      case 'call':
        return '📞 Call';
      default:
        return text;
    }
  }

  String _buildTime() {
    final t = group.lastMessageAt;
    if (t == null) return '';
    return FormattedDate.getChatTime(t);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasAvatar = group.avatarUrl?.isNotEmpty == true;
    final subtitle = _buildSubtitle();
    final time = _buildTime();

    return BlocBuilder<ThemeCubit, ThemeState>(
      builder:
          (context, _) => InkWell(
            onTap:
                () => Navigator.of(
                  context,
                  rootNavigator: true,
                ).pushNamed(AppRoutes.groupChatRoute, arguments: group),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 27,
                        backgroundColor: primary.withValues(alpha: 0.1),
                        backgroundImage:
                            hasAvatar
                                ? CachedNetworkImageProvider(group.avatarUrl!)
                                : null,
                        child:
                            !hasAvatar
                                ? Icon(
                                  Icons.group_rounded,
                                  color: primary,
                                  size: 28,
                                )
                                : null,
                      ),
                    ],
                  ),

                  const Gap(12),

                  // Name + subtitle + time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row: name + time
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                group.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color:
                                      isDark ? Colors.white : AppColors.black87,
                                ),
                              ),
                            ),
                            if (time.isNotEmpty) ...[
                              const Gap(8),
                              Text(
                                time,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ],
                        ),

                        const Gap(3),

                        // Subtitle (last message)
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                isDark ? Colors.white54 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
