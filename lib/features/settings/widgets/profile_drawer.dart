import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:social_media_app/features/auth/cubit/auth_cubit/auth_cubit.dart';
import 'package:social_media_app/features/profile/cubits/profile_cubit/profile_cubit.dart';
import 'package:social_media_app/features/settings/widgets/drawer_item_widget.dart';
import 'package:social_media_app/features/settings/widgets/theme_picker_sheet_widget.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/themes/cubit/theme_cubit.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
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
                return SizedBox(
                  height: MediaQuery.of(context).size.height * 0.3,
                  child: CustomLoadingIndicator(),
                );
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
                  icon: Icons.people_outline,
                  title: "Discover People",
                  onTap: () {
                    Navigator.of(context).pop();
                    navController.jumpToTab(1);
                  },
                ),
                DrawerItemWidget(
                  icon: Icons.photo_library_outlined,
                  title: "Photos/Videos",
                  onTap: () {},
                ),
                DrawerItemWidget(
                  icon: Icons.group_outlined,
                  title: "Group",
                  onTap: () {},
                ),
                DrawerItemWidget(
                  icon: Icons.color_lens_sharp,
                  title: "Your Themes",
                  onTap: () => _showThemeSheet(context),
                ),
                DrawerItemWidget(
                  icon: Icons.search,
                  title: "Search Profile",
                  onTap: () {},
                ),
                DrawerItemWidget(
                  icon: Icons.settings_outlined,
                  title: "Settings",
                  onTap:
                      () => Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushNamed(AppRoutes.settingsViewRoute),
                ),
                DrawerItemWidget(
                  icon: Icons.info_outline,
                  title: "About Us",
                  onTap: () {},
                ),
                DrawerItemWidget(
                  icon: Icons.language,
                  title: "Language",
                  onTap: () {},
                ),
                BlocConsumer<AuthCubit, AuthState>(
                  listener: (context, state) {
                    if (state is AuthSignedOut) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Log out Successfully',
                            style: Theme.of(context).textTheme.titleSmall!
                                .copyWith(color: Colors.white),
                          ),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushNamedAndRemoveUntil(
                        AppRoutes.authRoute,
                        (route) => false,
                      );
                    } else if (state is AuthFailure) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(state.errMsg)));
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
}

void _showThemeSheet(BuildContext context) {
  final profileState = context.read<ProfileCubit>().state;
  if (profileState is! ProfileLoaded) return;
  final userId = profileState.user.id;
  final themeCubit = context.read<ThemeCubit>();

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder:
        (_) => BlocProvider.value(
          value: themeCubit,
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.3,
            maxChildSize: 0.95,
            expand: false,
            snap: true,
            builder: (context, scrollController) {
              return ThemePickerSheetWidget(
                userId: userId,
                scrollController: scrollController,
              );
            },
          ),
        ),
  );
}
