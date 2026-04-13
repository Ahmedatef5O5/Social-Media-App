import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_media_app/core/constants/app_images.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/core/themes/background_theme_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _topLogoAnimation;
  late Animation<Offset> _bottomLogoAnimation;

  void _navigateToNext() async {
    if (!mounted) return;
    final session = Supabase.instance.client.auth.currentSession;
    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenOnboarding = prefs.getBool('onboarding_seen') ?? false;
    if (mounted) {
      String route = AppRoutes.onBoardingViewRoute;
      if (session != null) {
        route = AppRoutes.homeRoute;
      } else if (hasSeenOnboarding) {
        route = AppRoutes.authRoute;
      }
      Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,

      curve: Curves.easeOutBack,
    );

    //
    _topLogoAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    //
    _bottomLogoAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _navigateToNext();
        });
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundThemeWidget(
        top: false,
        showCircles: true,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SlideTransition(
                  position: _topLogoAnimation,
                  child: Image.asset(AppImages.logoApp, height: 280),
                ),

                const Gap(80),
                SlideTransition(
                  position: _bottomLogoAnimation,
                  child: Image.asset(
                    AppImages.secondaryLogoApp,
                    width: 280,
                    height: 120,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
