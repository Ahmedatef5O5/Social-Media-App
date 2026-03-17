import 'package:flutter/cupertino.dart';
import 'package:gap/gap.dart';
import '../../../core/themes/app_colors.dart';
import '../models/on_boarding_model.dart';

class OnBoardingContent extends StatelessWidget {
  final OnBoardingModel model;
  const OnBoardingContent({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        children: [
          Expanded(child: Image.asset(model.image, fit: BoxFit.contain)),
          const Gap(20),
          (model.subTitle != null && model.subTitle!.isNotEmpty)
              ? Text(
                model.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              )
              : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Gap(20),
                  Image.asset(model.title, fit: BoxFit.contain, width: 230),
                  const Gap(20),
                ],
              ),

          if (model.subTitle != null && model.subTitle!.isNotEmpty) ...[
            const Gap(15),
            Text(
              model.subTitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: AppColors.grey),
            ),
          ],
        ],
      ),
    );
  }
}
