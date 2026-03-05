import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:social_media_app/features/discover/views/discover_view.dart';
import 'package:social_media_app/features/profile/views/profile_view.dart';
import 'package:social_media_app/features/settings/views/settings_view.dart';
import '../../features/home/views/home_view.dart';

class CustomBottomNavBar extends StatefulWidget {
  const CustomBottomNavBar({super.key});

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      gestureNavigationEnabled: true,
      tabs: [
        PersistentTabConfig(
          screen: HomeView(),
          item: ItemConfig(
            icon: ActiveNavBarIcon(icon: Icons.home_outlined),
            inactiveIcon: InActiveNavBarIcon(icon: Icons.home_outlined),
          ),
        ),
        PersistentTabConfig(
          screen: DiscoverView(),
          item: ItemConfig(
            icon: ActiveNavBarIcon(icon: Icons.add_box_outlined),
            inactiveIcon: InActiveNavBarIcon(icon: Icons.add_box_outlined),
          ),
        ),
        PersistentTabConfig(
          screen: ProfileView(),
          item: ItemConfig(
            icon: ActiveNavBarIcon(icon: Icons.person_outline),
            inactiveIcon: InActiveNavBarIcon(icon: Icons.person_outline),
          ),
        ),
        PersistentTabConfig(
          screen: SettingsView(),
          item: ItemConfig(
            icon: ActiveNavBarIcon(icon: Icons.settings_outlined),
            inactiveIcon: InActiveNavBarIcon(icon: Icons.settings_outlined),
          ),
        ),
      ],

      navBarBuilder:
          (navBarConfig) => Style9BottomNavBar(navBarConfig: navBarConfig),
    );
  }
}

class InActiveNavBarIcon extends StatelessWidget {
  const InActiveNavBarIcon({super.key, this.icon});
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Icon(icon, color: Colors.grey),
    );
  }
}

class ActiveNavBarIcon extends StatelessWidget {
  const ActiveNavBarIcon({super.key, this.icon});
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: .2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon),
    );
  }
}
