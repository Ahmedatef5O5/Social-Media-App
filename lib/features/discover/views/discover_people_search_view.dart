import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../../../core/widgets/empty_findings_animation_widget.dart';
import '../../search/utils/accounts_skeleton_list.dart';
import '../../social_graph/models/discover_person_model.dart';
import '../cubits/discover_people_cubit.dart';
import '../utils/discover_grid_metrics.dart';
import '../widgets/discover_person_grid_card_widget.dart';

class DiscoverPeopleSearchView extends StatefulWidget {
  const DiscoverPeopleSearchView({super.key});

  @override
  State<DiscoverPeopleSearchView> createState() =>
      _DiscoverPeopleSearchViewState();
}

class _DiscoverPeopleSearchViewState extends State<DiscoverPeopleSearchView> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late final DiscoverPeopleCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<DiscoverPeopleCubit>();
    if (_cubit.state is DiscoverPeopleInitial) {
      _cubit.getDiscoverPeople();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _handleBack() {
    _cubit.searchPeople('');
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _cubit.searchPeople('');
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.primaryColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark, primary),
            Expanded(
              child: BlocBuilder<DiscoverPeopleCubit, DiscoverPeopleState>(
                bloc: _cubit,
                builder: (context, state) {
                  final query = _searchController.text.trim();

                  if (state is DiscoverPeopleInitial ||
                      state is DiscoverPeopleLoading) {
                    return const AccountsSkeletonList();
                  }

                  if (state is DiscoverPeopleFailure) {
                    return _buildErrorState(theme, state.message, query);
                  }

                  final users =
                      state is DiscoverPeopleSuccess
                          ? state.users
                          : const <DiscoverPersonModel>[];
                  final hasReachedMax =
                      state is DiscoverPeopleSuccess
                          ? state.hasReachedMax
                          : true;

                  if (users.isEmpty) {
                    return _buildEmptyState(theme, query);
                  }

                  return NotificationListener<ScrollNotification>(
                    onNotification: (scrollInfo) {
                      if (scrollInfo.metrics.pixels >=
                          scrollInfo.metrics.maxScrollExtent - 200) {
                        if (query.isEmpty) {
                          _cubit.getDiscoverPeople();
                        } else {
                          _cubit.loadMoreSearchResults();
                        }
                      }
                      return false;
                    },
                    child: CustomScrollView(
                      physics: const ClampingScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverMasonryGrid.count(
                            crossAxisCount: DiscoverGridMetrics.crossAxisCount,
                            mainAxisSpacing:
                                DiscoverGridMetrics.mainAxisSpacing,
                            crossAxisSpacing:
                                DiscoverGridMetrics.crossAxisSpacing,
                            childCount: users.length,
                            itemBuilder: (context, i) {
                              final person = users[i];
                              return DiscoverPersonGridCardWidget(
                                key: ValueKey(person.user.id),
                                personData: person,
                                highlightQuery: query.isEmpty ? null : query,
                                onDismiss:
                                    query.isEmpty
                                        ? () => _cubit.dismissSuggestion(
                                          person.user.id,
                                        )
                                        : null,
                              );
                            },
                          ),
                        ),
                        if (!hasReachedMax)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: CustomLoadingIndicator(radius: 12),
                              ),
                            ),
                          ),
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, Color primary) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.07),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: _handleBack,
          ),
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: (value) {
                  setState(() {});
                  _cubit.searchPeople(value);
                },
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Search people...',
                  hintStyle: TextStyle(
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.35)
                            : Colors.grey.shade400,
                    fontSize: 15,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: primary,
                    size: 22,
                  ),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color:
                                  isDark
                                      ? Colors.white54
                                      : Colors.grey.shade500,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _cubit.searchPeople('');
                              _focusNode.requestFocus();
                              setState(() {});
                            },
                          )
                          : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            EmptyFindingsThemedAnimation(
              animationPath: AppImages.emptyFindingsLot,
              width: 260,
              height: 220,
            ),
            const SizedBox(height: 16),
            Text(
              query.isEmpty
                  ? 'No suggestions right now'
                  : 'No results for "$query"',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (query.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Try a different name or username',
                style: theme.textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String message, String query) {
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
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed:
                  () =>
                      query.isEmpty
                          ? _cubit.getDiscoverPeople()
                          : _cubit.searchPeople(query),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
