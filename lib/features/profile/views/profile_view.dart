import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/core/themes/background_theme_widget.dart';
import 'package:social_media_app/features/profile/cubit/profile_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/data/models/user_data.dart';
import '../../home/cubit/home_cubit.dart';
import '../../home/widgets/post_item_widget.dart';
import '../widgets/profile_header.dart';
import '../widgets/proflie_states_widget.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final userId = Supabase.instance.client.auth.currentUser!.id;
    return BackgroundThemeWidget(
      top: false,
      child: BlocProvider(
        create: (context) => ProfileCubit()..getProfileData(userId),
        child: Center(
          child: BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, state) {
              if (state is ProfileLoading) {
                return Center(
                  child: CupertinoActivityIndicator(color: AppColors.black12),
                );
              } else if (state is ProfileLoaded) {
                return MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: DefaultTabController(
                    length: 2,
                    child: NestedScrollView(
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
                            pinned: true,
                            delegate: _SliverTabBarDelegate(
                              TabBar(
                                labelColor: Theme.of(context).primaryColor,
                                unselectedLabelColor: AppColors.grey,
                                indicatorColor: Theme.of(context).primaryColor,
                                indicatorSize: TabBarIndicatorSize.label,
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
                          ProfilePostsList(userId: state.user.id),
                          ProfileDetailsWidget(user: state.user),
                        ],
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
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this.tabBar);
  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}

class ProfileDetailsWidget extends StatelessWidget {
  final UserData user;
  const ProfileDetailsWidget({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(CupertinoIcons.mail, 'Email', user.email),
          const Gap(15),
          _buildInfoRow(CupertinoIcons.info, 'Bio', 'No bio provided yet.'),
          const Gap(15),
          _buildInfoRow(CupertinoIcons.calendar, 'Joined', 'March 2024'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryColor),
        const Gap(12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }
}

class ProfilePostsList extends StatelessWidget {
  final String userId;
  const ProfilePostsList({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is PostsLoaded) {
          final userPosts =
              state.posts.where((p) => p.authorId == userId).toList();

          if (userPosts.isEmpty) {
            return const Center(child: Text('No posts yet'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            // physics: const NeverScrollableScrollPhysics(),
            // shrinkWrap: true,
            itemCount: userPosts.length,
            itemBuilder:
                (context, index) => PostItemWidget(post: userPosts[index]),
            separatorBuilder: (BuildContext context, int index) => Gap(20),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
