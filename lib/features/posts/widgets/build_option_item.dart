import 'package:flutter/material.dart';

class BuildOptionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final void Function()? onTap;
  const BuildOptionItem(
    this.icon,
    this.title,
    this.color, {
    super.key,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      hoverColor: color.withValues(alpha: 0.1),
      splashColor: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(icon, color: color, size: 30),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall!.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface,
        ),
      ),
      onTap: onTap,
    );
  }
}
