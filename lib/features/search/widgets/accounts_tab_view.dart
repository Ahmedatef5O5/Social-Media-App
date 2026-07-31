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
import '../utils/search_matcher.dart';
import '../utils/accounts_skeleton_list.dart';

class AccountsTabView extends StatefulWidget {
  final ValueListenable<String> searchQuery;
  const AccountsTabView({super.key, required this.searchQuery});

  @override
  State<AccountsTabView> createState() => _AccountsTabViewState();
}

class _AccountsTabViewState extends State<AccountsTabView>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    widget.searchQuery.addListener(_maybeBroadenSearchPool);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<DiscoverPeopleCubit>().getDiscoverPeople();
    }
  }

  /// If the current query returns few matches from the pool we've
  /// already loaded, fetch another page from the same RPC to broaden
  /// the search pool. This does NOT search the whole users table
  /// server-side (that RPC has no search param — see Step 5 notes) —
  /// it just grows the local candidate set the client-side filter runs
  /// against.
  void _maybeBroadenSearchPool() {
    final query = widget.searchQuery.value;
    if (query.isEmpty) return;
    final state = context.read<DiscoverPeopleCubit>().state;
    if (state is DiscoverPeopleSuccess && !state.hasReachedMax) {
      final matches =
          state.users
              .where(
                (u) =>
                    matchesSearchQuery(query, [u.user.name, u.user.userName]),
              )
              .length;
      if (matches < 5) {
        context.read<DiscoverPeopleCubit>().getDiscoverPeople();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    widget.searchQuery.removeListener(_maybeBroadenSearchPool);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
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
              return _buildErrorState(context, theme, state.message);
            }

            final allUsers =
                state is DiscoverPeopleSuccess
                    ? state.users
                    : const <DiscoverPersonModel>[];
            final hasReachedMax =
                state is DiscoverPeopleSuccess ? state.hasReachedMax : true;

            final users =
                query.isEmpty
                    ? allUsers
                    : allUsers
                        .where(
                          (u) => matchesSearchQuery(query, [
                            u.user.name,
                            u.user.userName,
                          ]),
                        )
                        .toList();

            if (users.isEmpty) {
              return _buildEmptyState(theme, query);
            }

            return CustomPullToRefresh(
              onRefresh:
                  () => context.read<DiscoverPeopleCubit>().getDiscoverPeople(
                    isRefresh: true,
                  ),
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                // The "load more" tail only makes sense against the raw
                // (unfiltered) pool — loading more users can surface
                // more matches — driven independently by _onScroll.
                itemCount:
                    users.length + (query.isEmpty && !hasReachedMax ? 1 : 0),
                separatorBuilder: (_, __) => const Gap(12),
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
                  () => context.read<DiscoverPeopleCubit>().getDiscoverPeople(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
