import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:social_media_app/core/widgets/main_user_avatar.dart';
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

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    return MultiBlocProvider(
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
                icon: NavBarIcon(icon: Icons.add_box_outlined, isActive: true),
                inactiveIcon: NavBarIcon(
                  icon: Icons.add_box_outlined,
                  isActive: false,
                ),
              ),
            ),
            PersistentTabConfig(
              screen: const Center(child: Text("New Content Section")),
              item: ItemConfig(
                icon: const NavBarIcon(icon: Icons.chat_bubble, isActive: true),
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
    );
  }
}
