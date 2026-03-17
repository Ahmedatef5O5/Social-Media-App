import 'package:social_media_app/core/constants/app_images.dart';

class OnBoardingModel {
  final String image;
  final String title;
  final String? subTitle;

  OnBoardingModel({required this.image, required this.title, this.subTitle});
}

List<OnBoardingModel> onboardingPages = [
  OnBoardingModel(image: AppImages.logoApp, title: AppImages.secondaryLogoApp),
  OnBoardingModel(
    image: AppImages.onBoardingOne,
    title: 'Find Friends & Get Inspiration',
    subTitle:
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Erat vitae quis quam augue quam a.',
  ),
  OnBoardingModel(
    image: AppImages.onBoardingTwo,
    title: 'Meet Awesome People & Enjoy yourself',
    subTitle:
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Erat vitae quis quam augue quam a.',
  ),
  OnBoardingModel(
    image: AppImages.onBoardingThree,
    title: 'Hangout with with Friends',
    subTitle:
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Erat vitae quis quam augue quam a.',
  ),
];
