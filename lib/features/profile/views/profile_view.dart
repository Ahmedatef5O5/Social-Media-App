import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/core/themes/background_theme_widget.dart';
import 'package:social_media_app/core/widgets/custom_pull_to_refresh.dart';
import 'package:social_media_app/features/home/cubit/home_cubit.dart';
import 'package:social_media_app/features/profile/cubits/profile_cubit/profile_cubit.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../widgets/profile_details_widget_tab.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_posts_list_tab.dart';
import '../widgets/proflie_states_widget.dart';
import '../widgets/sliver_tab_bar_delegate.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return BackgroundThemeWidget(
      top: false,
      child: Center(
        child: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading) {
              return CustomLoadingIndicator();
            } else if (state is ProfileLoaded) {
              return MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: DefaultTabController(
                  length: 2,
                  child: CustomPullToRefresh(
                    onRefresh: () async {
                      final userId =
                          (context.read<ProfileCubit>().state as ProfileLoaded)
                              .user
                              .id;

                      await Future.wait([
                        context.read<ProfileCubit>().getProfileData(
                          userId,
                          isRefresh: true,
                        ),
                        context.read<HomeCubit>().fetchPosts(isRefresh: true),
                      ]);
                    },
                    child: NestedScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      headerSliverBuilder: (
                        BuildContext context,
                        bool innerBoxIsScrolled,
                      ) {
                        return [
                          SliverToBoxAdapter(
                            child: Column(
                              children: [
                                ProfileHeader(size: size, user: state.user),
                                Gap(20),
                                ProfileStatsWidget(stats: state.stats),
                                Gap(20),
                              ],
                            ),
                          ),
                          SliverPersistentHeader(
                            // pinned: true,
                            delegate: SliverTabBarDelegate(
                              TabBar(
                                labelColor: Theme.of(context).primaryColor,
                                unselectedLabelColor: AppColors.grey4,
                                dividerColor: AppColors.grey3,
                                indicatorColor: Theme.of(context).primaryColor,
                                indicatorSize: TabBarIndicatorSize.tab,
                                indicatorWeight: 3,
                                padding: EdgeInsets.symmetric(horizontal: 30),
                                indicator: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(60),
                                ),
                                indicatorPadding: const EdgeInsets.only(
                                  top: 45,
                                ),

                                tabs: [
                                  Tab(text: 'Posts'),
                                  Tab(text: 'Details'),
                                ],
                              ),
                            ),
                          ),
                        ];
                      },
                      body: TabBarView(
                        children: [
                          ProfilePostsListTab(userId: state.user.id),
                          ProfileDetailsWidgetTab(user: state.user),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            } else if (state is ProfileError) {
              return Center(child: Text(state.message));
            } else {
              return SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }
}
