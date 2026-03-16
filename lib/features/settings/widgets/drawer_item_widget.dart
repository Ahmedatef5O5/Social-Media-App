import 'package:flutter/material.dart';
import 'package:social_media_app/core/themes/app_colors.dart';

class DrawerItemWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color color;

  const DrawerItemWidget({
    super.key,

    required this.icon,
    required this.title,
    required this.onTap,
    this.color = AppColors.black87,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: color == Colors.red ? Colors.red : AppColors.primaryColor,
      ),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppColors.grey,
      ),
      onTap: onTap,
    );
  }
}
