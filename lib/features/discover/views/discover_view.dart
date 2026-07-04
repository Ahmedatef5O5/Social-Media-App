import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/themes/background_theme_widget.dart';
import 'package:social_media_app/core/widgets/custom_pull_to_refresh.dart';
import 'package:social_media_app/core/widgets/custom_tab_wrapper.dart';
import 'package:social_media_app/features/discover/cubit/discover_people_cubit.dart';
import 'package:social_media_app/features/discover/views/discover_skeleton_view.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../widgets/discover_people_header_section.dart';
import '../widgets/discover_person_card_widget.dart';

class DiscoverView extends StatefulWidget {
  final ScrollController scrollController;
  const DiscoverView({super.key, required this.scrollController});

  @override
  State<DiscoverView> createState() => _DiscoverViewState();
}

class _DiscoverViewState extends State<DiscoverView> {
  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (widget.scrollController.position.pixels >=
        widget.scrollController.position.maxScrollExtent - 200) {
      context.read<DiscoverPeopleCubit>().getDiscoverPeople();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundThemeWidget(
      top: true,
      child: BlocBuilder<DiscoverPeopleCubit, DiscoverPeopleState>(
        builder: (context, state) {
          bool hasReachedMax = false;
          if (state is DiscoverPeopleSuccess) {
            hasReachedMax = state.hasReachedMax;
          }

          return CustomTabWrapper(
            isLoading:
                state is DiscoverPeopleInitial ||
                state is DiscoverPeopleLoading ||
                state is DiscoverPeopleRefreshFeedback,
            loadingSkeleton: const DiscoverPeopleSkeleton(),
            errorMessage: state is DiscoverPeopleFailure ? state.message : null,
            onRetry:
                () => context.read<DiscoverPeopleCubit>().getDiscoverPeople(),

            child: CustomPullToRefresh(
              onRefresh:
                  () async => await context
                      .read<DiscoverPeopleCubit>()
                      .getDiscoverPeople(isRefresh: true),

              child: CustomScrollView(
                controller: widget.scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const Gap(20),
                        DiscoverPeopleHeaderSection(),
                        const Gap(8),
                      ],
                    ),
                  ),

                  Builder(
                    builder: (context) {
                      if (state is DiscoverPeopleSuccess) {
                        return SliverPadding(
                          padding: const EdgeInsets.only(
                            top: 14,
                            left: 12,
                            right: 12,
                            bottom: 100,
                          ),
                          sliver: SliverList.builder(
                            itemCount:
                                state.users.length + (hasReachedMax ? 0 : 1),
                            itemBuilder: (BuildContext context, int index) {
                              if (index >= state.users.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: CustomLoadingIndicator(radius: 12),
                                  ),
                                );
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: DiscoverPersonCardWidget(
                                  userData: state.users[index],
                                ),
                              );
                            },
                          ),
                        );
                      } else {
                        return const SliverToBoxAdapter(
                          child: SizedBox.shrink(),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
