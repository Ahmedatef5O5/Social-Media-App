import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';

class BuildOptionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const BuildOptionItem(this.icon, this.title, this.color, {super.key});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color, size: 30),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.black87,
        ),
      ),
      onTap: () {},
    );
  }
}
