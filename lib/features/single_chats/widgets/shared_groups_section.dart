import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/cached_cloudinary_image.dart';
import '../cubit/shared_groups_cubit/shared_groups_cubit.dart';
import '../cubit/shared_groups_cubit/shared_groups_state.dart';
import '../models/shared_group_item.dart';

class SharedGroupsSection extends StatelessWidget {
  final SharedGroupsCubit groupsCubit;

  const SharedGroupsSection({super.key, required this.groupsCubit});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SharedGroupsCubit, SharedGroupsState>(
      bloc: groupsCubit..load(),
      builder: (context, state) {
        if (state is SharedGroupsInitial || state is SharedGroupsLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        // Fail quiet: a broken mutual-groups fetch shouldn't block the
        // rest of the profile view (media/block are independent above).
        if (state is SharedGroupsError) return const SizedBox.shrink();

        final groups = (state as SharedGroupsLoaded).groups;
        if (groups.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Shared Groups',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const Spacer(),
                  Text(
                    '${groups.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
              const Gap(8),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: groups.length,
                separatorBuilder: (_, _) => const Gap(4),
                itemBuilder:
                    (context, index) => _SharedGroupTile(item: groups[index]),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SharedGroupTile extends StatelessWidget {
  final SharedGroupItem item;
  const _SharedGroupTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final group = item.group;
    final hasAvatar = group.avatarUrl != null && group.avatarUrl!.isNotEmpty;
    final primary = Theme.of(context).primaryColor;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushNamed(AppRoutes.groupChatRoute, arguments: group);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            ClipOval(
              child: Container(
                width: 44,
                height: 44,
                color: primary.withValues(alpha: 0.12),
                child:
                    hasAvatar
                        ? CachedCloudinaryImage(
                          secureUrl: group.avatarUrl!,
                          fit: BoxFit.cover,
                          isAvatar: true,
                        )
                        : Center(
                          child: Text(
                            group.name.isNotEmpty
                                ? group.name[0].toUpperCase()
                                : 'G',
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                        ),
              ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    '${item.membersCount} ${item.membersCount == 1 ? 'member' : 'members'}',
                    style: TextStyle(fontSize: 12.5, color: AppColors.grey4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
