import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class SettingsSliverAppBar extends StatelessWidget {
  const SettingsSliverAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.primaryColor;

    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double minHeight = statusBarHeight + 60.0;

    return SliverAppBar(
      expandedHeight: 120,
      collapsedHeight: 60,
      pinned: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,

      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: primary),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final top = constraints.maxHeight;
          double titleOpacity = (minHeight + 20 - top) / 20.0;
          titleOpacity = titleOpacity.clamp(0.0, 1.0);

          double bgOpacity = (top - (minHeight + 10)) / 30.0;
          bgOpacity = bgOpacity.clamp(0.0, 1.0);

          return FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            titlePadding: const EdgeInsets.only(left: 52, bottom: 20),

            title: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),

              opacity: titleOpacity,
              child: Text(
                'Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            background: Padding(
              padding: const EdgeInsets.fromLTRB(20, 70, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.settings_rounded,
                      color: primary,
                      size: 22,
                    ),
                  ),
                  const Gap(14),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'Manage your preferences',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white38 : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
