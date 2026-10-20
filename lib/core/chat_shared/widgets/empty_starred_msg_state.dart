import 'package:flutter/material.dart';
import '../../constants/app_images.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class EmptyStarredMsgState extends StatelessWidget {
  const EmptyStarredMsgState({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final screenHeight = size.height;
    final textTheme = Theme.of(context).textTheme;

    final double horizontalPadding = (screenWidth * 0.08).clamp(16.0, 48.0);
    final double imageWidth = (screenWidth * 0.60).clamp(160.0, 280.0);
    final double largeSpacing = (screenHeight * 0.03).clamp(16.0, 32.0);
    final double smallSpacing = (screenHeight * 0.01).clamp(6.0, 14.0);

    final double titleFontSize = (screenWidth * 0.045).clamp(16.0, 22.0);
    final double bodyFontSize = (screenWidth * 0.035).clamp(12.0, 16.0);

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: largeSpacing,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                AppImages.noStarredMsgsIcon,
                width: imageWidth,
                fit: BoxFit.contain,
              ),
              SizedBox(height: largeSpacing),
              Text(
                context.l10n.noStarredMessages,
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(fontSize: titleFontSize),
              ),
              SizedBox(height: smallSpacing),
              Text(
                context.l10n.tapAndHoldOn,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  fontSize: bodyFontSize,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
