import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/features/group_chat/cubit/group_list_cubit/group_list_cubit.dart';
import '../models/group_model.dart';

class GroupChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final GroupModel group;

  const GroupChatAppBar({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    final hasAvatar = group.avatarUrl?.isNotEmpty == true;

    return BlocBuilder<GroupListCubit, GroupListState>(
      builder: (context, state) {
        final updatedGroup =
            (state is GroupListLoaded)
                ? state.groups.firstWhere(
                  (g) => g.id == group.id,
                  orElse: () => group,
                )
                : group;
        final avatarUrl = updatedGroup.avatarUrl;

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
              Navigator.of(
                context,
              ).pushNamed(AppRoutes.groupInfoViewRoute, arguments: group);
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: primary.withValues(alpha: 0.12),
                  backgroundImage:
                      hasAvatar ? CachedNetworkImageProvider(avatarUrl!) : null,
                  child:
                      !hasAvatar
                          ? Text(
                            group.name[0].toUpperCase(),
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge!.copyWith(
                              color: Theme.of(context).primaryColor,
                            ),
                          )
                          : null,
                ),
                const Gap(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          color: Theme.of(context).primaryColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Tap for group info',
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
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
