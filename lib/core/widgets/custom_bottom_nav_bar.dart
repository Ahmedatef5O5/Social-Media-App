import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:social_media_app/core/widgets/exit_confirmation_dialog.dart';
import 'package:social_media_app/core/widgets/main_user_avatar.dart';
import 'package:social_media_app/features/chats/views/chats_view.dart';
import 'package:social_media_app/features/discover/views/discover_view.dart';
import 'package:social_media_app/features/profile/views/profile_view.dart';
import 'package:social_media_app/features/settings/widgets/profile_drawer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/home/views/home_view.dart';
import '../../features/profile/cubits/profile_cubit/profile_cubit.dart';
import 'nav_bar_icon_widget.dart';

class CustomBottomNavBar extends StatefulWidget {
  const CustomBottomNavBar({super.key});

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late PersistentTabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: 0);
  }

  Future<bool?> _showExitConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => const ExitConfirmationDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (_scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
          _scaffoldKey.currentState?.closeEndDrawer();
          return;
        }

        if (_controller.index != 0) {
          _controller.jumpToTab(0);
          return;
        }
        bool shouldExit = await _showExitConfirmationDialog(context) ?? false;
        if (shouldExit == true) {
          await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
        }
      },
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => ProfileCubit()..getProfileData(userId),
          ),
        ],
        child: Scaffold(
          key: _scaffoldKey,
          endDrawer: ProfileDrawer(navController: _controller),
          body: PersistentTabView(
            controller: _controller,
            gestureNavigationEnabled: true,
            handleAndroidBackButtonPress: false,
            selectedTabPressConfig: const SelectedTabPressConfig(
              popAction: PopActionType.all,
            ),
            tabs: [
              PersistentTabConfig(
                screen: HomeView(),
                item: ItemConfig(
                  icon: NavBarIcon(icon: Icons.home_outlined, isActive: true),
                  inactiveIcon: NavBarIcon(
                    icon: Icons.home_outlined,
                    isActive: false,
                  ),
                ),
              ),
              PersistentTabConfig(
                screen: DiscoverView(),
                item: ItemConfig(
                  icon: NavBarIcon(
                    icon: Icons.add_box_outlined,
                    isActive: true,
                  ),
                  inactiveIcon: NavBarIcon(
                    icon: Icons.add_box_outlined,
                    isActive: false,
                  ),
                ),
              ),
              PersistentTabConfig(
                screen: const ChatsView(),
                item: ItemConfig(
                  icon: const NavBarIcon(
                    icon: Icons.chat_bubble_outline,
                    isActive: true,
                  ),
                  inactiveIcon: const NavBarIcon(
                    icon: Icons.chat_bubble_outline,

                    isActive: false,
                  ),
                ),
              ),

              PersistentTabConfig(
                screen: ProfileView(),

                item: ItemConfig(
                  icon: BlocBuilder<ProfileCubit, ProfileState>(
                    builder: (context, state) {
                      String? imageUrl;
                      if (state is ProfileLoaded) {
                        imageUrl = state.user.imageUrl;
                      }
                      return NavBarIcon(
                        isActive: true,
                        child: MainUserAvatar(
                          imageUrl: imageUrl,
                          showBorder: true,
                          size: 31,
                        ),
                      );
                    },
                  ),
                  inactiveIcon: BlocBuilder<ProfileCubit, ProfileState>(
                    builder: (context, state) {
                      String? imageUrl;
                      if (state is ProfileLoaded) {
                        imageUrl = state.user.imageUrl;
                      }
                      return NavBarIcon(
                        isActive: false,

                        child: MainUserAvatar(
                          imageUrl: imageUrl,
                          showBorder: true,
                          size: 31,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],

            navBarBuilder:
                (navBarConfig) => Style9BottomNavBar(
                  navBarConfig: navBarConfig.copyWith(
                    onItemSelected: (index) {
                      if (index == 3) {
                        _scaffoldKey.currentState!.openEndDrawer();
                      }
                      navBarConfig.onItemSelected(index);
                    },
                  ),
                ),
          ),
        ),
      ),
    );
  }
}
