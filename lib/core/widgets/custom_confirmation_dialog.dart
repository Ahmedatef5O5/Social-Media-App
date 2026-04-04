import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lottie/lottie.dart';
import 'package:social_media_app/core/widgets/custom_elevated_button.dart';
import '../../features/chats/widgets/empty_placeholder_state.dart';
import '../themes/app_colors.dart';

class CustomConfirmationDialog extends StatelessWidget {
  final String title;
  final String img;
  final String confirmBtnText;
  final String cancelBtnText;
  final VoidCallback onConfirm;
  const CustomConfirmationDialog({
    super.key,
    required this.title,
    required this.img,
    this.confirmBtnText = 'Yes',
    this.cancelBtnText = 'No',
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return AlertDialog(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(),
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
                img: img,
                delegates: LottieDelegates(
                  values: [
                    ValueDelegate.color(const [
                      'Shape 1',
                      '**',
                    ], value: Theme.of(context).primaryColor),
                  ],
                ),
                imgHeight: screenWidth * 0.4,
                imgWidth: screenWidth * 0.45,
                title: title,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
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
                      txtBtn: cancelBtnText,
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
                      txtBtn: confirmBtnText,
                      txtBtnStyle: Theme.of(context).textTheme.titleMedium!
                          .copyWith(color: Theme.of(context).primaryColor),
                      txtColor: Theme.of(context).primaryColor,
                      onPressed: onConfirm,
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
