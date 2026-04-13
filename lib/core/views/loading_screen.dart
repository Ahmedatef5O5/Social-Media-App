import 'package:flutter/material.dart';
import '../themes/background_theme_widget.dart';
import '../widgets/custom_loading_indicator.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: BackgroundThemeWidget(
        top: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [CustomLoadingIndicator()],
        ),
      ),
    );
  }
}
