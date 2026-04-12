import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:social_media_app/core/widgets/custom_elevated_button.dart';
import '../constants/app_images.dart';

class CustomTabWrapper<T> extends StatefulWidget {
  final Widget loadingSkeleton;
  final Widget child;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  const CustomTabWrapper({
    super.key,
    required this.loadingSkeleton,
    required this.child,
    required this.isLoading,
    this.errorMessage,
    required this.onRetry,
  });

  @override
  State<CustomTabWrapper<T>> createState() => _CustomTabWrapperState<T>();
}

class _CustomTabWrapperState<T> extends State<CustomTabWrapper<T>> {
  bool _isRetrying = false;
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final theme = Theme.of(context);

    if (widget.isLoading) {
      return widget.loadingSkeleton;
    }
    if (widget.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              AppImages.blueError404Lot,
              height: screenSize.height * 0.38,
              fit: BoxFit.contain,
            ),
            SizedBox(height: _isRetrying ? 0 : 22),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: _isRetrying ? 0.0 : 1.0,

              child: AnimatedSize(
                duration: const Duration(milliseconds: 400),
                child:
                    _isRetrying
                        ? const SizedBox(width: double.infinity)
                        : Text(
                          widget.errorMessage!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontSize: 15,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
              ),
            ),
            SizedBox(height: screenSize.height * 0.04),
            CustomElevatedButton(
              txtBtn: 'Retry Again',
              isLoading: _isRetrying,
              txtColor: theme.colorScheme.onPrimary,
              bgColor: theme.primaryColor,
              minimumSize: Size(200, 45),
              maximumSize: Size(200, 45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(22)),
              ),
              onPressed: () async {
                setState(() => _isRetrying = true);

                widget.onRetry();

                await Future.delayed(const Duration(seconds: 1));

                if (mounted) {
                  setState(() => _isRetrying = false);
                }
              },
            ),
            SizedBox(height: screenSize.height * 0.065),
          ],
        ),
      );
    }

    return widget.child;
  }
}
