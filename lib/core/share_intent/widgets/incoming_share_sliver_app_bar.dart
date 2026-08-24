import 'package:flutter/material.dart';
import '../../router/app_routes.dart';

class IncomingShareSliverAppBar extends StatelessWidget {
  final ThemeData theme;
  final bool canPopNormally;

  const IncomingShareSliverAppBar({
    super.key,
    required this.theme,
    required this.canPopNormally,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      title: const Text(
        'Send to...',
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
      titleSpacing: 0,
      centerTitle: false,
      floating: true,
      snap: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () {
          if (canPopNormally) {
            Navigator.pop(context);
          } else {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.homeRoute, (route) => false);
          }
        },
      ),
    );
  }
}
