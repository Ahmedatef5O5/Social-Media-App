import 'package:flutter/material.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/widgets/custom_confirmation_dialog.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

Future<bool?> showUnfriendConfirmationDialog(
  BuildContext context, {
  required String friendName,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    pageBuilder: (_, __, ___) => const SizedBox(),
    transitionBuilder: (context, anim1, __, ___) {
      return Transform.scale(
        scale: anim1.value,
        child: CustomConfirmationDialog(
          title: context.l10n.removeFromYourFriends(friendName),
          textAlign: TextAlign.center,
          img: AppImages.deleteFilesAnimationLot,
          confirmBtnText: context.l10n.remove,
          cancelBtnText: context.l10n.cancel,
          onConfirm: () => Navigator.of(context, rootNavigator: true).pop(true),
        ),
      );
    },
  );
}
