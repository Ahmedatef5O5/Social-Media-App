import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../../../../core/constants/app_images.dart';
import '../../../../core/widgets/custom_pull_to_refresh.dart';
import '../../../../core/widgets/empty_findings_animation_widget.dart';
import '../../discover/cubit/discover_people_cubit.dart';
import '../../discover/widgets/discover_person_card_widget.dart';
import '../../social_graph/models/discover_person_model.dart';
import '../utils/accounts_skeleton_list.dart';
import '../utils/search_view_metrics.dart';

class AccountsTabView extends StatefulWidget {
  final ValueListenable<String> searchQuery;
  const AccountsTabView({super.key, required this.searchQuery});

  @override
  State<AccountsTabView> createState() => _AccountsTabViewState();
}

class _AccountsTabViewState extends State<AccountsTabView>
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
    context.read<DiscoverPeopleCubit>().searchPeople(query);
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
        return BlocBuilder<DiscoverPeopleCubit, DiscoverPeopleState>(
          builder: (context, state) {
            if (state is DiscoverPeopleInitial ||
                state is DiscoverPeopleLoading) {
              return const AccountsSkeletonList();
            }

            if (state is DiscoverPeopleFailure) {
              return _buildErrorState(context, theme, state.message, query);
            }

            final users =
                state is DiscoverPeopleSuccess
                    ? state.users
                    : const <DiscoverPersonModel>[];
            final hasReachedMax =
                state is DiscoverPeopleSuccess ? state.hasReachedMax : true;

            if (users.isEmpty) {
              return _buildEmptyState(theme, query);
            }

            return NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (scrollInfo.metrics.pixels >=
                    scrollInfo.metrics.maxScrollExtent - 200) {
                  if (query.isEmpty) {
                    context.read<DiscoverPeopleCubit>().getDiscoverPeople();
                  } else {
                    context.read<DiscoverPeopleCubit>().loadMoreSearchResults();
                  }
                }
                return false;
              },
              child: CustomPullToRefresh(
                onRefresh:
                    () => context.read<DiscoverPeopleCubit>().getDiscoverPeople(
                      isRefresh: true,
                    ),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    SearchViewMetrics.horizontalPadding,
                    SearchViewMetrics.topGap,
                    SearchViewMetrics.horizontalPadding,
                    SearchViewMetrics.bottomGap,
                  ),
                  physics: const ClampingScrollPhysics(),
                  itemCount: users.length + (!hasReachedMax ? 1 : 0),
                  separatorBuilder:
                      (_, __) => const Gap(SearchViewMetrics.itemGap),
                  itemBuilder: (context, i) {
                    if (i >= users.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    return DiscoverPersonCardWidget(
                      key: ValueKey(users[i].user.id),
                      personData: users[i],
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme, String query) {
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
                  ? 'No accounts to discover yet'
                  : 'No accounts found for "$query"',
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
              onPressed:
                  () =>
                      query.isEmpty
                          ? context
                              .read<DiscoverPeopleCubit>()
                              .getDiscoverPeople()
                          : context.read<DiscoverPeopleCubit>().searchPeople(
                            query,
                          ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
