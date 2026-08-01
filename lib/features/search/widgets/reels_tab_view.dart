import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/widgets/empty_findings_animation_widget.dart';
import '../../reels/model/reel_model.dart';
import '../../reels/views/reels_full_screen_view.dart';
import '../cubit/search_reels_cubit/search_reels_cubit.dart';
import '../utils/search_matcher.dart';
import '../utils/search_view_metrics.dart';
import 'reel_grid_tile.dart';
import '../utils/reels_grid_skeleton.dart';

class ReelsTabView extends StatefulWidget {
  final ValueListenable<String> searchQuery;
  const ReelsTabView({super.key, required this.searchQuery});

  @override
  State<ReelsTabView> createState() => _ReelsTabViewState();
}

class _ReelsTabViewState extends State<ReelsTabView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.searchQuery.addListener(_maybeBroadenSearchPool);
  }

  void _maybeBroadenSearchPool() {
    final query = widget.searchQuery.value;
    if (query.isEmpty) return;
    final state = context.read<SearchReelsCubit>().state;
    if (state is SearchReelsLoaded && !state.hasReachedMax) {
      final matches =
          state.reels
              .where(
                (r) => matchesSearchQuery(query, [
                  r.title,
                  r.description,
                  r.channel.channelName,
                ]),
              )
              .length;
      if (matches < 6) {
        context.read<SearchReelsCubit>().getReels();
      }
    }
  }

  @override
  void dispose() {
    widget.searchQuery.removeListener(_maybeBroadenSearchPool);
    super.dispose();
  }

  void _openReel(List<ReelModel> reels, int index) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => ReelsFullScreenView(reels: reels, initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);

    return ValueListenableBuilder<String>(
      valueListenable: widget.searchQuery,
      builder: (context, query, _) {
        return BlocConsumer<SearchReelsCubit, SearchReelsState>(
          listener: (context, state) {
            if (query.isNotEmpty &&
                state is SearchReelsLoaded &&
                !state.hasReachedMax) {
              final matches =
                  state.reels
                      .where(
                        (r) => matchesSearchQuery(query, [
                          r.title,
                          r.description,
                          r.channel.channelName,
                        ]),
                      )
                      .length;

              if (matches < 6) {
                context.read<SearchReelsCubit>().getReels();
              }
            }
          },

          builder: (context, state) {
            if (state is SearchReelsInitial || state is SearchReelsLoading) {
              return const ReelsGridSkeleton();
            }

            if (state is SearchReelsError) {
              return _buildErrorState(context, theme, state.message);
            }

            final allReels =
                state is SearchReelsLoaded ? state.reels : const <ReelModel>[];
            final hasReachedMax =
                state is SearchReelsLoaded ? state.hasReachedMax : true;

            final reels =
                query.isEmpty
                    ? allReels
                    : allReels
                        .where(
                          (r) => matchesSearchQuery(query, [
                            r.title,
                            r.description,
                            r.channel.channelName,
                          ]),
                        )
                        .toList();

            if (reels.isEmpty) {
              return _buildEmptyState(theme, query);
            }

            return NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (scrollInfo.metrics.pixels >=
                    scrollInfo.metrics.maxScrollExtent - 200) {
                  context.read<SearchReelsCubit>().getReels();
                }
                return false;
              },
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      SearchViewMetrics.horizontalPadding - 10,
                      SearchViewMetrics.topGap - 7,
                      SearchViewMetrics.horizontalPadding - 10,
                      SearchViewMetrics.bottomGap,
                    ),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 2,
                            mainAxisSpacing: 2,
                            childAspectRatio: 9 / 16,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => ReelGridTile(
                          key: ValueKey(reels[i].id),
                          reel: reels[i],
                          onTap: () => _openReel(reels, i),
                        ),
                        childCount: reels.length,
                      ),
                    ),
                  ),
                  if (query.isEmpty && !hasReachedMax)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                ],
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
                  ? 'No reels available'
                  : 'No reels found for "$query"',
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
              onPressed: () => context.read<SearchReelsCubit>().getReels(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
