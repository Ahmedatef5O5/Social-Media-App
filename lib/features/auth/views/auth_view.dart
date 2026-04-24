import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/themes/dynamic_splash_app.dart';
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
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: BackgroundThemeWidget(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Gap(35),
                  SizedBox(width: 350, child: DynamicSplashLogo(width: 350)),
                  Gap(40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    child: CustomTabBar(tabs: tabs),
                  ),
                  Gap(30),
                  Expanded(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollStartNotification) {
                          if (notification.metrics.axis == Axis.horizontal) {
                            FocusManager.instance.primaryFocus?.unfocus();
                          }
                        }
                        return false;
                      },
                      child: TabBarView(children: tabViews),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
