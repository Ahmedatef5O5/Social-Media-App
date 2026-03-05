import 'package:flutter/material.dart';

class NavBarIcon extends StatelessWidget {
  const NavBarIcon({super.key, this.icon, required this.isActive});
  final IconData? icon;
  final bool isActive;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color:
            isActive ? Colors.blue.withValues(alpha: .175) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: isActive ? Theme.of(context).primaryColor : Colors.grey,
      ),
    );
  }
}
