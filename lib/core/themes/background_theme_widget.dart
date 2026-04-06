import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/themes/cubit/theme_cubit.dart';

class BackgroundThemeWidget extends StatelessWidget {
  final Widget child;
  final bool top, bottom;
  final bool showCircles;
  const BackgroundThemeWidget({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.showCircles = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        final theme = state.theme;
        final bool canShowCircles = showCircles && !theme.isDark;
        return Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(color: theme.bgBase),
          child: Stack(
            children: [
              if (canShowCircles) ...[
                Positioned(
                  top: -50,
                  left: -50,
                  child: _circle(theme.bgCircle, context),
                ),
                Positioned(
                  bottom: -50,
                  right: -50,
                  child: _circle(theme.bgCircle, context),
                ),
              ],

              SafeArea(top: top, bottom: bottom, child: child),
            ],
          ),
        );
      },
    );
  }

  Widget _circle(Color color, context) {
    return AnimatedOpacity(
      opacity: 0.8,
      duration: const Duration(milliseconds: 300),
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0.01)],
            stops: const [0.2, 1.0],
          ),
        ),
      ),
    );
  }
}
