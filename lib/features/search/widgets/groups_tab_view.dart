import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../../../../core/constants/app_images.dart';
import '../../../../core/widgets/empty_findings_animation_widget.dart';
import '../../group_chats/cubit/group_list_cubit/group_list_cubit.dart';
import '../../group_chats/models/group_model.dart';
import '../cubit/search_groups_cubit/search_groups_cubit.dart';
import '../utils/groups_tab_skeleton_list.dart';
import '../utils/search_view_metrics.dart';
import 'group_search_result_tile.dart';

class GroupsTabView extends StatefulWidget {
  final ValueListenable<String> searchQuery;
  const GroupsTabView({super.key, required this.searchQuery});

  @override
  State<GroupsTabView> createState() => _GroupsTabViewState();
}

class _GroupsTabViewState extends State<GroupsTabView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.searchQuery.addListener(_onQueryChanged);
  }

  void _onQueryChanged() {
    final query = widget.searchQuery.value;
    if (query.isNotEmpty) {
      context.read<SearchGroupsCubit>().search(query);
    }
  }

  @override
  void dispose() {
    widget.searchQuery.removeListener(_onQueryChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return ValueListenableBuilder<String>(
      valueListenable: widget.searchQuery,
      builder: (context, query, _) {
        if (query.isEmpty) {
          return BlocBuilder<GroupListCubit, GroupListState>(
            builder: (context, groupListState) {
              if (groupListState is GroupListInitial ||
                  groupListState is GroupListLoading) {
                return const GroupsTabSkeletonList();
              }

              if (groupListState is GroupListLoaded) {
                final myGroups = groupListState.groups;

                if (myGroups.isEmpty) {
                  return _buildEmptyState(theme, query, isMyGroupsEmpty: true);
                }

                return _buildGroupsList(myGroups);
              }

              return const SizedBox.shrink();
            },
          );
        }

        return BlocBuilder<SearchGroupsCubit, SearchGroupsState>(
          builder: (context, state) {
            if (state is SearchGroupsLoading) {
              return const GroupsTabSkeletonList();
            }

            if (state is SearchGroupsError) {
              return _buildErrorState(context, theme, state.message, query);
            }

            final groups =
                state is SearchGroupsLoaded ? state.groups : <GroupModel>[];

            if (groups.isEmpty) {
              return _buildEmptyState(theme, query);
            }

            return _buildGroupsList(groups);
          },
        );
      },
    );
  }

  Widget _buildGroupsList(List<GroupModel> groups) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        SearchViewMetrics.horizontalPadding,
        SearchViewMetrics.topGap,
        SearchViewMetrics.horizontalPadding,
        SearchViewMetrics.bottomGap,
      ),
      physics: const ClampingScrollPhysics(),
      itemCount: groups.length,
      separatorBuilder: (_, __) => const Gap(SearchViewMetrics.itemGap),
      itemBuilder: (context, i) {
        return GroupSearchResultTile(
          key: ValueKey(groups[i].id),
          group: groups[i],
        );
      },
    );
  }

  Widget _buildEmptyState(
    ThemeData theme,
    String query, {
    bool isMyGroupsEmpty = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const EmptyFindingsThemedAnimation(
              animationPath: AppImages.emptyFindingsLot,
              width: 150,
              height: 150,
            ),
            const Gap(12),
            Text(
              query.isEmpty
                  ? (isMyGroupsEmpty
                      ? 'You haven\'t joined any groups yet'
                      : 'Search for groups')
                  : 'No groups found for "$query"',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    ThemeData theme,
    String message,
    String query,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 42,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const Gap(12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const Gap(14),
            TextButton(
              onPressed: () {
                if (query.isNotEmpty) {
                  context.read<SearchGroupsCubit>().search(query);
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
