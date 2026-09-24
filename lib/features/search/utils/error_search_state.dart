import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/widgets/custom_elevated_button.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/themes/cubits/theme_cubit.dart';
import '../../../core/themes/themed_error_lottie.dart';

class ErrorSearchState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorSearchState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.watch<ThemeCubit>().state.theme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RepaintBoundary(
                    child: ThemedErrorLottie(
                      theme: appTheme,
                      assetPath: AppImages.blueError404Lot,
                      height: (constraints.maxHeight * 0.26).clamp(90.0, 220.0),
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 15,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.9,
                      ),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 26),
                  CustomElevatedButton(
                    txtBtn: 'Retry Again',
                    txtColor: theme.colorScheme.onPrimary,
                    bgColor: theme.primaryColor,
                    minimumSize: const Size(200, 45),
                    maximumSize: const Size(200, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    onPressed: onRetry,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
