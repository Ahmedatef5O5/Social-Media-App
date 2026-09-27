import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/themes/background_theme_widget.dart';

class PostThemesView extends StatelessWidget {
  const PostThemesView({super.key});

  @override
  Widget build(BuildContext context) {
    return BackgroundThemeWidget(
      bottom: false,
      child: Scaffold(
        backgroundColor: AppColors.transparent,
        appBar: AppBar(
          backgroundColor: AppColors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 24),
          ),
          title: Text(
            'Background Color',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 18,
            ),
          ),
        ),
        body: const SizedBox.expand(),
      ),
    );
  }
}
