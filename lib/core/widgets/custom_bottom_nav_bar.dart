import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:social_media_app/features/discover/views/discover_view.dart';
import 'package:social_media_app/features/profile/views/profile_view.dart';
import 'package:social_media_app/features/settings/views/settings_view.dart';
import '../../features/home/views/home_view.dart';
import 'nav_bar_icon_widget.dart';

class CustomBottomNavBar extends StatefulWidget {
  const CustomBottomNavBar({super.key});

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      // resizeToAvoidBottomInset: false,
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
          screen: ProfileView(),
          item: ItemConfig(
            icon: NavBarIcon(icon: Icons.person_outline, isActive: true),
            inactiveIcon: NavBarIcon(
              icon: Icons.person_outline,
              isActive: false,
            ),
          ),
        ),
        PersistentTabConfig(
          screen: SettingsView(),
          item: ItemConfig(
            icon: NavBarIcon(icon: Icons.settings_outlined, isActive: true),
            inactiveIcon: NavBarIcon(
              icon: Icons.settings_outlined,
              isActive: false,
            ),
          ),
        ),
      ],

      navBarBuilder:
          (navBarConfig) => Style9BottomNavBar(navBarConfig: navBarConfig),
    );
  }
}
