import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../themes/app_colors.dart';
import '../themes/background_theme_widget.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: BackgroundThemeWidget(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(child: CupertinoActivityIndicator(color: AppColors.black12)),
          ],
        ),
      ),
    );
  }
}
