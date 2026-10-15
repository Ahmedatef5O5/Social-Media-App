import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_images.dart';

/// Tombstone shown when the viewed profile belongs to a soft-deleted
/// (ghost) account. It intentionally exposes no actions.
class DeletedProfilePlaceholder extends StatelessWidget {
  const DeletedProfilePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final mutedColor = theme.textTheme.bodyMedium?.color?.withValues(
      alpha: 0.65,
    );

    return SafeArea(
      child: Stack(
        children: [
          if (Navigator.canPop(context))
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  tooltip: 'Back',
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => Navigator.maybePop(context),
                ),
              ),
            ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipOval(
                    child: Image.asset(
                      AppImages.deletedUserAccountIcon,
                      width: width * 0.52,
                      height: width * 0.52,
                      fit: BoxFit.cover,
                    ),
                  ),

                  const Gap(28),
                  Text(
                    'Deleted Account',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    'This account has been deleted and its profile is no '
                    'longer available.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: mutedColor,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
