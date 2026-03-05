import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/constants/app_images.dart';
import 'package:social_media_app/features/auth/widgets/login_view_widget.dart';
import 'package:social_media_app/features/auth/widgets/register_view_widget.dart';
import '../../../core/themes/background_theme_widget.dart';
import '../widgets/custom_tab_bar.dart';

class AuthView extends StatelessWidget {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Tab> tabs = [
      const Tab(text: 'Sign in'),
      const Tab(text: 'Sign up'),
    ];
    final List<Widget> tabViews = [LoginViewWidget(), RegisterViewWidget()];
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        body: BackgroundThemeWidget(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 55),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Gap(35),
                Image.asset(AppImages.logo, width: 300),
                Gap(30),
                CustomTabBar(tabs: tabs),
                Gap(30),
                Expanded(child: TabBarView(children: tabViews)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
