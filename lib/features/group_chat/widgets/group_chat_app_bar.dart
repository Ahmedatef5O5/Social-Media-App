import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/features/group_chat/cubit/group_list_cubit/group_list_cubit.dart';
import '../models/group_model.dart';
import '../views/group_info_view.dart';

class GroupChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final GroupModel group;

  const GroupChatAppBar({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    final hasAvatar = group.avatarUrl?.isNotEmpty == true;

    return BlocBuilder<GroupListCubit, GroupListState>(
      builder: (context, state) {
        return AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,

          leading: InkWell(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back_ios_new, color: primary, size: 22),
          ),
          titleSpacing: 0,
          title: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => GroupInfoView(group: group)),
              );
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: primary.withValues(alpha: 0.12),
                  backgroundImage:
                      hasAvatar
                          ? CachedNetworkImageProvider(group.avatarUrl!)
                          : null,
                  child: !hasAvatar ? Text(group.name[0].toUpperCase()) : null,
                ),
                const Gap(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.name, overflow: TextOverflow.ellipsis),
                      const Text('Tap for group info'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
