import 'package:flutter/material.dart';

import '../../../core/themes/app_colors.dart';

class CustomTabBar extends StatelessWidget {
  const CustomTabBar({super.key, required this.tabs});

  final List<Tab> tabs;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: DefaultTabController.of(context),
      tabs: tabs,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelPadding: EdgeInsets.only(right: 22),
      labelColor: AppColors.black,
      unselectedLabelColor: Colors.grey,
      indicatorColor: Theme.of(context).primaryColor.withValues(blue: 0.8),
      indicatorSize: TabBarIndicatorSize.tab,
      indicatorPadding: EdgeInsets.only(right: 22),
      labelStyle: Theme.of(
        context,
      ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w400),
      dividerColor: AppColors.secondaryColor,
      dividerHeight: 1.8,
    );
  }
}
