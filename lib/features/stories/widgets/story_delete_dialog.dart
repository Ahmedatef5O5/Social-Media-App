import 'package:flutter/material.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/widgets/custom_confirmation_dialog.dart';

Future<bool?> showDeleteStoryDialog(BuildContext context) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    pageBuilder: (_, __, ___) => const SizedBox(),
    transitionBuilder: (context, anim1, __, ___) {
      return Transform.scale(
        scale: anim1.value,
        child: CustomConfirmationDialog(
          title: 'Delete this story?',
          img: AppImages.deleteFilesAnimationLot,
          confirmBtnText: 'Delete',
          cancelBtnText: 'Cancel',
          onConfirm: () => Navigator.of(context, rootNavigator: true).pop(true),
        ),
      );
    },
  );
}
