import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/features/profile/widgets/profile_details_widget_tab.dart';
import 'package:social_media_app/features/profile/widgets/profile_header.dart';
import 'package:social_media_app/features/profile/widgets/profile_posts_list_tab.dart';
import 'package:social_media_app/features/profile/widgets/proflie_states_widget.dart';
import 'package:social_media_app/features/profile/widgets/sliver_tab_bar_delegate.dart';

import '../../../core/themes/app_colors.dart';
import '../cubits/profile_cubit/profile_cubit.dart';

class ProfileBodyContent extends StatelessWidget {
  final ProfileLoaded state;
  final ScrollController scrollController;
  final Size size;
  final ValueNotifier<double> refreshProgress;
  final ValueNotifier<bool> isRefreshing;
  const ProfileBodyContent({
    super.key,
    required this.state,
    required this.scrollController,
    required this.size,
    required this.refreshProgress,
    required this.isRefreshing,
  });

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: DefaultTabController(
        length: 2,

        child: NestedScrollView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
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
                    unselectedLabelColor: AppColors.grey4,
                    dividerColor: AppColors.grey3,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorWeight: 3,
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    indicatorPadding: const EdgeInsets.only(top: 45),

                    tabs: [Tab(text: 'Posts'), Tab(text: 'Details')],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              ProfilePostsListTab(
                userId: state.user.id,
                refreshProgress: refreshProgress,
                isRefreshing: isRefreshing,
              ),
              ProfileDetailsWidgetTab(
                user: state.user,
                refreshProgress: refreshProgress,
                isRefreshing: isRefreshing,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
