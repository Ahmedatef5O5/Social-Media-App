import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/session_guard.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/themes/background_theme_widget.dart';
import '../../../core/widgets/custom_elevated_button.dart';

/// Shown when a recovery link is expired, already used, or invalid.
class AuthLinkExpiredView extends StatelessWidget {
  const AuthLinkExpiredView({super.key});

  void _requestNewLink(BuildContext context) {
    final nav = Navigator.of(context);
    nav.pushNamedAndRemoveUntil(AppRoutes.authRoute, (r) => false);
    nav.pushNamed(AppRoutes.forgotPasswordRoute);
  }

  void _goHome(BuildContext context) {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.homeRoute, (r) => false);
  }

  void _goToLogin(BuildContext context) {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.authRoute, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    // The user already changed the password with this very link and is signed
    // in: sending them to "request a new link" would be confusing.
    final alreadySignedIn = SessionGuard.isFullySignedIn;
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          alreadySignedIn ? _goHome(context) : _goToLogin(context);
        }
      },
      child: Scaffold(
        body: BackgroundThemeWidget(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.link_off_rounded,
                    size: 88,
                    color: theme.primaryColor,
                  ),
                  const Gap(24),
                  Text(
                    alreadySignedIn
                        ? 'This link was already used'
                        : 'This link is no longer valid',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  const Gap(12),
                  Text(
                    alreadySignedIn
                        ? "Your password was already updated and you're signed in."
                        : 'This link has expired or has already been used. '
                            'Please request a new one.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.grey,
                      height: 1.4,
                    ),
                  ),
                  const Gap(32),
                  CustomElevatedButton(
                    txtBtn: alreadySignedIn ? 'Go to Home' : 'Request new link',
                    onPressed:
                        () =>
                            alreadySignedIn
                                ? _goHome(context)
                                : _requestNewLink(context),
                  ),
                  if (!alreadySignedIn) ...[
                    const Gap(12),
                    TextButton(
                      onPressed: () => _goToLogin(context),
                      child: const Text('Back to login'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
