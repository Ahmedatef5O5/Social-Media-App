import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_media_app/core/constants/app_images.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/core/themes/background_theme_widget.dart';
import 'package:social_media_app/core/themes/dynamic_splash_app.dart';
import '../../../core/bootstrap/app_bootstrap.dart';
import '../../../core/deep_link/services/deep_link_service.dart';
import '../../../core/notifications/handlers/tap_action_handler.dart';
import '../../../core/share_intent/services/share_intent_service.dart';
import '../../../core/supabase/supabase_provider.dart';

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

  bool _hasNavigated = false;

  Future<void> _skipSplashForCallLaunch() async {
    await waitForCoreServicesReady();
    if (!mounted || _hasNavigated) return;
    if (!TapActionHandler.instance.hasPendingCallLaunch) return;
    _controller.stop();
    _navigateToNext();
  }

  void _navigateToNext() async {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    await waitForCoreServicesReady();

    final session = SupabaseProvider.currentSession;
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

      if (route == AppRoutes.homeRoute) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          DeepLinkService.instance.markAppReady();

          ShareIntentService.instance.flushPendingColdStartShareIfAny();

          TapActionHandler.instance.markAppReadyAndFlush();
        });
      } else {
        ShareIntentService.instance.discardPendingColdStartShare();
        DeepLinkService.instance.discardPendingLink();
        TapActionHandler.instance.discardPendingLaunch();
      }
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

    unawaited(_skipSplashForCallLaunch());
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
                  child: SizedBox(
                    width: 280,
                    height: 120,
                    child: DynamicSplashLogo(width: 280, height: 120),
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
