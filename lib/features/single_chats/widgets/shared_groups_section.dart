import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../cubits/shared_groups_cubit/shared_groups_cubit.dart';
import '../cubits/shared_groups_cubit/shared_groups_state.dart';
import '../helpers/shared_groups_shimmer.dart';
import 'shared_group_tile.dart';

class SharedGroupsSection extends StatelessWidget {
  final SharedGroupsCubit groupsCubit;

  const SharedGroupsSection({super.key, required this.groupsCubit});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SharedGroupsCubit, SharedGroupsState>(
      bloc: groupsCubit..load(),
      builder: (context, state) {
        if (state is SharedGroupsInitial || state is SharedGroupsLoading) {
          return const SharedGroupsShimmer();
        }

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
              const Gap(7),
              ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: groups.length,
                separatorBuilder: (_, _) => const Gap(4),
                itemBuilder:
                    (context, index) => SharedGroupTile(item: groups[index]),
              ),
            ],
          ),
        );
      },
    );
  }
}
