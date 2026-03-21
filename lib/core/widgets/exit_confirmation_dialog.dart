import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/widgets/custom_elevated_button.dart';
import '../../features/chats/widgets/empty_placeholder_state.dart';
import '../constants/app_images.dart';
import '../themes/app_colors.dart';

class ExitConfirmationDialog extends StatelessWidget {
  const ExitConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return AlertDialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: screenWidth * 0.9),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EmptyPlaceholderState(
                opacity: 1,
                periodSpeed: 1,
                img: AppImages.exitAnimationLot,
                // imgHeight: 170,
                // imgWidth: 180,
                imgHeight: screenWidth * 0.4,
                imgWidth: screenWidth * 0.45,
                title: 'Are you sure you want to quit ?',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: AppColors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              const Gap(24),
              Row(
                children: [
                  Expanded(
                    child: CustomElevatedButton(
                      maximumSize: Size(80, 40),
                      minimumSize: Size(80, 40),
                      txtBtn: 'No',
                      onPressed:
                          () => Navigator.of(
                            context,
                            rootNavigator: true,
                          ).pop(false),
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: CustomElevatedButton(
                      maximumSize: Size(80, 40),
                      minimumSize: Size(80, 40),
                      txtBtn: 'Yes',
                      txtColor: AppColors.primaryColor,
                      onPressed:
                          () => Navigator.of(
                            context,
                            rootNavigator: true,
                          ).pop(true),
                      elevation: 1.5,
                      bgColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
