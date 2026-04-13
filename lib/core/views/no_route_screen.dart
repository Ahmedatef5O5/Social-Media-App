import 'package:flutter/material.dart';
import '../themes/app_colors.dart';
import '../themes/background_theme_widget.dart';

class NoRouteScreen extends StatelessWidget {
  final String? routeName;
  const NoRouteScreen({super.key, this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundThemeWidget(
        top: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Text(
                'No route found $routeName',
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  color: AppColors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
