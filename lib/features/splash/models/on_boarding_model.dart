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
        'Discover creative content, explore new ideas, and connect with a global community that shares your interests.',
  ),
  OnBoardingModel(
    image: AppImages.onBoardingTwo,
    title: 'Meet Awesome People & Enjoy yourself',
    subTitle:
        'Expand your social network, engage in meaningful conversations, and share your favorite moments with others.',
  ),
  OnBoardingModel(
    image: AppImages.onBoardingThree,
    title: 'Hangout with Friends',
    subTitle:
        'Stay close to your loved ones through seamless video, voice, and text chats no matter where you are.',
  ),
];
