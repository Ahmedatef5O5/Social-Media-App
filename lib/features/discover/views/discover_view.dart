import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/themes/background_theme_widget.dart';
import 'package:social_media_app/core/widgets/custom_pull_to_refresh.dart';
import 'package:social_media_app/core/widgets/custom_tab_wrapper.dart';
import 'package:social_media_app/features/discover/cubit/discover_people_cubit.dart';
import 'package:social_media_app/features/discover/views/discover_skeleton_view.dart';
import '../widgets/discover_people_header_section.dart';
import '../widgets/discover_person_card_widget.dart';

class DiscoverView extends StatelessWidget {
  const DiscoverView({super.key});

  @override
  Widget build(BuildContext context) {
    return BackgroundThemeWidget(
      top: true,
      child: BlocBuilder<DiscoverPeopleCubit, DiscoverPeopleState>(
        builder: (context, state) {
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
                          sliver: SliverList.separated(
                            itemCount: state.users.length,
                            separatorBuilder:
                                (BuildContext context, int index) =>
                                    const Gap(16),
                            itemBuilder: (BuildContext context, int index) {
                              return DiscoverPersonCardWidget(
                                userData: state.users[index],
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
