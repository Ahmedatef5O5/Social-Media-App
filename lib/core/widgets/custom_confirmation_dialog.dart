import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lottie/lottie.dart';
import 'package:social_media_app/core/widgets/custom_elevated_button.dart';
import '../../features/single_chats/widgets/empty_placeholder_state.dart';
import '../constants/app_images.dart';
import '../design/theme/lottie_color_ramp.dart';
import '../localization/l10n_extension.dart';
import '../themes/app_colors.dart';

class CustomConfirmationDialog extends StatelessWidget {
  final String title;
  final TextStyle? style;
  final TextAlign? textAlign;
  final String img;
  final String? confirmBtnText;
  final String? cancelBtnText;
  final VoidCallback onConfirm;
  final Color? confirmBtnColor;
  final Color? confirmTxtColor;
  final LottieDelegates? lottieDelegates;

  const CustomConfirmationDialog({
    super.key,
    required this.title,
    this.style,
    this.textAlign,
    required this.img,
    this.confirmBtnText,
    this.cancelBtnText,
    required this.onConfirm,
    this.confirmBtnColor,
    this.confirmTxtColor,
    this.lottieDelegates,
  });

  LottieDelegates _resolveDelegates(BuildContext context) {
    if (lottieDelegates != null) return lottieDelegates!;

    final colorScheme = Theme.of(context).colorScheme;

    if (img == AppImages.exitAnimationLot) {
      return LottieColorRamp.fromColorScheme(colorScheme).exitDoorDelegates();
    }

    return LottieDelegates(
      values: [
        ValueDelegate.color(const [
          'Shape 1',
          '**',
        ], value: Theme.of(context).primaryColor),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    final Color effectiveConfirmTxtColor =
        confirmTxtColor ?? Theme.of(context).primaryColor;
    final effectiveCancel = cancelBtnText ?? context.l10n.no;
    final effectiveConfirm = confirmBtnText ?? context.l10n.yes;
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
                delegates: _resolveDelegates(context),
                imgHeight: screenWidth * 0.4,
                imgWidth: screenWidth * 0.45,
                title: title,
                textAlign: textAlign,
                style:
                    style ??
                    Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
              ),
              const Gap(24),
              Row(
                children: [
                  Expanded(
                    child: CustomElevatedButton(
                      maximumSize: const Size(80, 40),
                      minimumSize: const Size(80, 40),
                      txtBtn: effectiveCancel,
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
                      maximumSize: const Size(80, 40),
                      minimumSize: const Size(80, 40),
                      txtBtn: effectiveConfirm,
                      txtBtnStyle: Theme.of(context).textTheme.titleMedium!
                          .copyWith(color: effectiveConfirmTxtColor),
                      txtColor: effectiveConfirmTxtColor,
                      onPressed: onConfirm,
                      elevation: 1.5,
                      bgColor: confirmBtnColor ?? AppColors.white,
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
