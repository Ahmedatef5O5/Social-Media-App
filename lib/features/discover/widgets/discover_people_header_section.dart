import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../views/search_view.dart';

class DiscoverPeopleHeaderSection extends StatelessWidget {
  const DiscoverPeopleHeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discover People',
                  style: theme.textTheme.titleLarge!.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(2),
                Text(
                  'People you may know',
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Gap(12),
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () {
              Navigator.of(context, rootNavigator: true).push(
                PageRouteBuilder(
                  pageBuilder: (_, animation, __) => const SearchView(),
                  transitionsBuilder: (_, anim, __, child) {
                    return FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.05),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(parent: anim, curve: Curves.easeOut),
                        ),
                        child: child,
                      ),
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 280),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_rounded,
                size: 22,
                color: theme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
