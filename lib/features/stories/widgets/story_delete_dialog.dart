import 'package:flutter/material.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/widgets/custom_confirmation_dialog.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';
import 'package:social_media_app/core/localization/app_l10n.dart';

Future<bool?> showDeleteStoryDialog(BuildContext context, {int count = 1}) {
  final title =
      count > 1
          ? AppL10n.current.deleteStories(count)
          : AppL10n.current.deleteThisStory;

  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    pageBuilder: (_, __, ___) => const SizedBox(),
    transitionBuilder: (context, anim1, __, ___) {
      return Transform.scale(
        scale: anim1.value,
        child: CustomConfirmationDialog(
          title: title,
          textAlign: TextAlign.center,
          img: AppImages.deleteFilesAnimationLot,
          confirmBtnText: context.l10n.delete,
          cancelBtnText: context.l10n.cancel,
          onConfirm: () => Navigator.of(context, rootNavigator: true).pop(true),
        ),
      );
    },
  );
}
