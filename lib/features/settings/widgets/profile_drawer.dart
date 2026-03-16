import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/core/constants/app_images.dart';
import 'package:social_media_app/core/themes/app_colors.dart';

class ProfileDrawer extends StatelessWidget {
  const ProfileDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          bottomLeft: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),

          const Divider(indent: 20, endIndent: 20),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 10),
              children: [
                _drawerItem(
                  icon: CupertinoIcons.pen,
                  title: "Edit Profile",
                  onTap: () {},
                ),
                _drawerItem(
                  icon: Icons.people_outline,
                  title: "Network",
                  onTap: () {},
                ),
                _drawerItem(
                  icon: Icons.photo_library_outlined,
                  title: "Photos/Videos",
                  onTap: () {},
                ),
                _drawerItem(
                  icon: Icons.group_outlined,
                  title: "Group",
                  onTap: () {},
                ),
                _drawerItem(
                  icon: Icons.lock_outline,
                  title: "Your Privacy",
                  onTap: () {},
                ),
                _drawerItem(
                  icon: Icons.search,
                  title: "Search Profile",
                  onTap: () {},
                ),
                _drawerItem(
                  icon: Icons.settings_outlined,
                  title: "Settings",
                  onTap: () {},
                ),
                _drawerItem(
                  icon: Icons.info_outline,
                  title: "About Us",
                  onTap: () {},
                ),
                _drawerItem(
                  icon: Icons.language,
                  title: "Language",
                  onTap: () {},
                ),
              ],
            ),
          ),
          _drawerItem(
            icon: Icons.logout,
            title: "Log Out",
            color: Colors.red,
            onTap: () {
              // نادى على الـ AuthCubit هنا
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 60, bottom: 20),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 45,
            backgroundImage: NetworkImage(AppImages.defaultUserImg),
          ),
          const SizedBox(height: 15),
          const Text(
            "Dave C. Brown",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Text(
            "@dave_brown",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.black87,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color == Colors.red ? Colors.red : Colors.blue,
      ),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }
}
