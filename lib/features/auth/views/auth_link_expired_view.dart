import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/session_guard.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/themes/background_theme_widget.dart';
import '../../../core/widgets/custom_elevated_button.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

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
                        ? context.l10n.thisLinkWasAlready
                        : context.l10n.thisLinkIsNo,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  const Gap(12),
                  Text(
                    alreadySignedIn
                        ? context.l10n.yourPasswordWasAlready
                        : context.l10n.thisLinkHasExpired,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.grey,
                      height: 1.4,
                    ),
                  ),
                  const Gap(32),
                  CustomElevatedButton(
                    txtBtn:
                        alreadySignedIn
                            ? context.l10n.goToHome
                            : context.l10n.requestNewLink,
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
                      child: Text(context.l10n.backToLogin),
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
