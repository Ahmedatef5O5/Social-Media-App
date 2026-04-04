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
      unselectedLabelColor: AppColors.grey4,
      dividerColor: AppColors.grey3,
      indicatorSize: TabBarIndicatorSize.tab,
      indicatorWeight: 3,
      indicatorPadding: const EdgeInsets.only(top: 45),
      dividerHeight: 1.8,
    );
  }
}
