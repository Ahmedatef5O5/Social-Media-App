import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:social_media_app/features/auth/cubits/auth_cubit/auth_cubit.dart';
import 'package:social_media_app/features/profile/cubits/profile_cubit/profile_cubit.dart';
import 'package:social_media_app/features/settings/widgets/drawer_item_widget.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/toast/app_toast.dart';
import '../../discover/views/discover_people_search_view.dart';
import '../utils/drawer_header_shimmer.dart';
import 'drawer_header_widget.dart';

class ProfileDrawer extends StatelessWidget {
  final PersistentTabController navController;
  const ProfileDrawer({super.key, required this.navController});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          bottomLeft: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, state) {
              if (state is ProfileLoaded) {
                return DrawerHeaderWidget(user: state.user);
              } else {
                return const DrawerHeaderShimmer();
              }
            },
          ),

          const Divider(indent: 20, endIndent: 20),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 10),
              children: [
                DrawerItemWidget(
                  icon: CupertinoIcons.pen,
                  title: "Edit Profile",
                  onTap: () async {
                    final profileCubit = context.read<ProfileCubit>();
                    final profileState = profileCubit.state;
                    if (profileState is ProfileLoaded) {
                      await Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushNamed(
                        AppRoutes.editProfileViewRoute,
                        arguments: profileState.user,
                      );
                      if (context.mounted) {
                        profileCubit.getProfileData(profileState.user.id);
                      }
                    }
                  },
                ),
                DrawerItemWidget(
                  icon: Icons.search,
                  title: "Search Profile",
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).push(
                      PageRouteBuilder(
                        pageBuilder:
                            (_, animation, __) =>
                                const DiscoverPeopleSearchView(),
                        transitionsBuilder: (_, anim, __, child) {
                          return FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.05),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: anim,
                                  curve: Curves.easeOut,
                                ),
                              ),
                              child: child,
                            ),
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 280),
                      ),
                    );
                  },
                ),

                DrawerItemWidget(
                  icon: Icons.people_outline,
                  title: "Discover People",
                  onTap: () {
                    Navigator.of(context).pop();
                    navController.jumpToTab(1);
                  },
                ),

                DrawerItemWidget(
                  icon: Icons.message_outlined,
                  title: "Your Chats",
                  onTap: () {
                    Navigator.of(context).pop();
                    navController.jumpToTab(2);
                  },
                ),

                DrawerItemWidget(
                  icon: Icons.color_lens_sharp,
                  title: "Your Themes",
                  onTap: () => _openThemesSelectView(context),
                ),
                DrawerItemWidget(
                  icon: Icons.settings_outlined,
                  title: "Settings",
                  onTap:
                      () =>
                          Navigator.of(context, rootNavigator: true).pushNamed(
                            AppRoutes.settingsViewRoute,
                            arguments: context.read<ProfileCubit>(),
                          ),
                ),
                DrawerItemWidget(
                  icon: Icons.info_outline,
                  title: "About Us",
                  onTap: () {
                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pushNamed(AppRoutes.aboutUsViewRoute);
                  },
                ),

                BlocConsumer<AuthCubit, AuthState>(
                  listener: (context, state) {
                    if (state is AuthSignedOut) {
                      AppToast.warning('Log out Successfully');
                    } else if (state is AuthFailure) {
                      AppToast.error(state.errMsg);
                    }
                  },
                  buildWhen:
                      (previous, current) =>
                          current is AuthSignedOut ||
                          current is AuthFailure ||
                          current is AuthLoading,
                  builder: (context, state) {
                    return DrawerItemWidget(
                      icon: Icons.logout,
                      color: Colors.red.withValues(alpha: 0.92),
                      title: "Log Out",
                      onTap:
                          state is AuthLoading
                              ? () {}
                              : () => context.read<AuthCubit>().signOut(),
                    );
                  },
                ),
              ],
            ),
          ),

          const Gap(30),
        ],
      ),
    );
  }

  void _openThemesSelectView(BuildContext context) {
    final profileState = context.read<ProfileCubit>().state;
    if (profileState is! ProfileLoaded) return;

    Navigator.of(context, rootNavigator: true).pushNamed(
      AppRoutes.themesSelectViewRoute,
      arguments: profileState.user.id,
    );
  }
}
