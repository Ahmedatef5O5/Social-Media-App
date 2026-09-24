import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/widgets/custom_confirmation_dialog.dart';
import '../../../core/widgets/custom_grey_container.dart';
import '../cubits/auth_cubit/auth_cubit.dart';

class SocialSignSection extends StatelessWidget {
  const SocialSignSection({super.key, required this.label});
  final String label;
  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> _handleFacebookTap(BuildContext context) async {
    final shouldContinue = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => CustomConfirmationDialog(
            title:
                'Facebook log in is in Dev Mode (Test accounts and admin only). Continue?',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 17,
            ),
            textAlign: TextAlign.center,
            img: AppImages.alertAnimationLot,
            cancelBtnText: 'Cancel',
            confirmBtnText: 'Continue',
            onConfirm: () {
              Navigator.of(dialogContext, rootNavigator: true).pop(true);
            },
          ),
    );

    if (shouldContinue == true && context.mounted) {
      context.read<AuthCubit>().signInWithFacebook();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(label),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const Gap(14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            CustomGreyContainer(
              img: AppImages.google,
              onTap: () => context.read<AuthCubit>().signInWithGoogle(),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                CustomGreyContainer(
                  img: AppImages.facebook,
                  onTap: () => _handleFacebookTap(context),
                ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: IgnorePointer(
                    child: Container(
                      height: 16,
                      width: 16,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5252),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Text(
                        'dev',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 5.5,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            CustomGreyContainer(
              img: _isIOS ? AppImages.apple : AppImages.microsoft,
              onTap: () {
                if (_isIOS) {
                  // Apple Sign-In:
                } else {
                  context.read<AuthCubit>().signInWithMicrosoft();
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
