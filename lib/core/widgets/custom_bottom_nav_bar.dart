import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:social_media_app/core/themes/cubit/theme_cubit.dart';
import 'package:social_media_app/core/widgets/custom_confirmation_dialog.dart';
import 'package:social_media_app/core/widgets/main_user_avatar.dart';
import 'package:social_media_app/features/chats/cubit/chats_cubit/chats_cubit.dart';
import 'package:social_media_app/features/chats/views/chats_view.dart';
import 'package:social_media_app/features/discover/views/discover_view.dart';
import 'package:social_media_app/features/profile/views/profile_view.dart';
import 'package:social_media_app/features/settings/widgets/profile_drawer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/home/views/home_view.dart';
import '../../features/profile/cubits/profile_cubit/profile_cubit.dart';
import '../constants/app_images.dart';
import 'custom_floating_nav_bar.dart';

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
    _controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<bool?> _showExitConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => CustomConfirmationDialog(
            title: 'Are you sure you want to quit ?',
            img: AppImages.exitAnimationLot,

            onConfirm:
                () => Navigator.of(context, rootNavigator: true).pop(true),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        final currentTheme = themeState.theme;

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
            bool shouldExit =
                await _showExitConfirmationDialog(context) ?? false;
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
              backgroundColor: currentTheme.bgBase,
              key: _scaffoldKey,
              extendBody: true,
              endDrawer: ProfileDrawer(navController: _controller),
              body: Stack(
                children: [
                  PersistentTabView(
                    backgroundColor: Colors.transparent,
                    controller: _controller,
                    gestureNavigationEnabled: true,
                    handleAndroidBackButtonPress: false,
                    selectedTabPressConfig: const SelectedTabPressConfig(
                      popAction: PopActionType.all,
                    ),
                    navBarBuilder: (config) => const SizedBox.shrink(),
                    tabs: [
                      PersistentTabConfig(
                        screen: HomeView(),
                        item: ItemConfig(icon: const Icon(Icons.home)),
                      ),
                      PersistentTabConfig(
                        screen: DiscoverView(),
                        item: ItemConfig(icon: const Icon(Icons.group)),
                      ),
                      PersistentTabConfig(
                        screen: const ChatsView(),
                        item: ItemConfig(icon: const Icon(Icons.chat)),
                      ),
                      PersistentTabConfig(
                        screen: ProfileView(),
                        item: ItemConfig(icon: const Icon(Icons.person)),
                      ),
                    ],
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 8,
                    child: Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.92,
                        child: BlocBuilder<ChatsCubit, ChatsState>(
                          builder: (context, chatsState) {
                            int unread = 0;
                            if (chatsState is ChatsSuccessloaded) {
                              unread = chatsState.chats.fold(
                                0,
                                (s, c) => s + c.unreadCount,
                              );
                            }
                            return BlocBuilder<ProfileCubit, ProfileState>(
                              builder: (context, profileState) {
                                String? imageUrl;
                                if (profileState is ProfileLoaded) {
                                  imageUrl = profileState.user.imageUrl;
                                }
                                return CustomFloatingNavBar(
                                  currentIndex: _controller.index,

                                  onTap: (i) {
                                    _controller.jumpToTab(i);

                                    if (i == 3) {
                                      _scaffoldKey.currentState!
                                          .openEndDrawer();
                                    }
                                    setState(() {});
                                  },
                                  items: [
                                    const NavBarItem(icon: Icons.home_outlined),
                                    const NavBarItem(
                                      icon: Icons.group_outlined,
                                    ),
                                    NavBarItem(
                                      icon: Icons.chat_bubble_outline,
                                      badgeCount: unread,
                                    ),
                                    NavBarItem(
                                      child: MainUserAvatar(
                                        imageUrl: imageUrl,
                                        showBorder: false,
                                        // showBorder: _controller.index == 3,
                                        size: 30,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
