import 'package:social_media_app/core/constants/app_images.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class OnBoardingModel {
  final String image;
  final String title;
  final String? subTitle;

  OnBoardingModel({required this.image, required this.title, this.subTitle});
}

/// Built per-build (not a global list) so the text follows the active language.
List<OnBoardingModel> buildOnboardingPages(AppLocalizations l10n) => [
  OnBoardingModel(image: AppImages.logoApp, title: AppImages.secondaryLogoApp),
  OnBoardingModel(
    image: AppImages.onBoardingOne,
    title: l10n.onboardingOneTitle,
    subTitle: l10n.onboardingOneSubtitle,
  ),
  OnBoardingModel(
    image: AppImages.onBoardingTwo,
    title: l10n.onboardingTwoTitle,
    subTitle: l10n.onboardingTwoSubtitle,
  ),
  OnBoardingModel(
    image: AppImages.onBoardingThree,
    title: l10n.onboardingThreeTitle,
    subTitle: l10n.onboardingThreeSubtitle,
  ),
];
