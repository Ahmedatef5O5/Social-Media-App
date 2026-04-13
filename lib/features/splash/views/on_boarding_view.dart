import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_media_app/core/themes/background_theme_widget.dart';
import 'package:social_media_app/core/widgets/custom_elevated_button.dart';
import 'package:social_media_app/features/splash/models/on_boarding_model.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/themes/app_colors.dart';
import '../widgets/on_boarding_content_widget.dart';

class OnBoardingView extends StatefulWidget {
  const OnBoardingView({super.key});

  @override
  State<OnBoardingView> createState() => _OnBoardingViewState();
}

class _OnBoardingViewState extends State<OnBoardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.authRoute,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundThemeWidget(
        top: false,
        showCircles: true,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0, top: 8.0),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _finishOnboarding,
                  child: Text(
                    'Skip',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: AppColors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 1.3,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: onboardingPages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder:
                    (context, index) =>
                        OnBoardingContent(model: onboardingPages[index]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                onboardingPages.length,
                (index) => buildDot(index),
              ),
            ),
            const Gap(40),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              transitionBuilder:
                  (Widget child, Animation<double> animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
              child:
                  _currentPage == onboardingPages.length - 1
                      ? Padding(
                        key: const ValueKey('buttons'),
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Column(
                          children: [
                            CustomElevatedButton(
                              onPressed: _finishOnboarding,
                              bgColor: Theme.of(context).primaryColor,
                              minimumSize: const Size(double.infinity, 54),

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              txtBtn: 'Join Now',
                              txtBtnStyle: TextStyle(
                                color: AppColors.white,
                                fontSize: 18,
                              ),
                            ),
                            const Gap(15),
                            TextButton(
                              onPressed: _finishOnboarding,
                              child: Text(
                                'Sign In',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      : SizedBox(key: const ValueKey('empty'), height: 118),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDot(int index) {
    return AnimatedContainer(
      curve: Curves.easeInOutBack,
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 5),
      height: 8,
      width: _currentPage == index ? 20 : 10,
      decoration: BoxDecoration(
        color:
            _currentPage == index
                ? Theme.of(context).primaryColor
                : AppColors.grey2,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}
