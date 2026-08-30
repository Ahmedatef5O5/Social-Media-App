import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import '../themes/cubits/theme_cubit.dart';

class EmptyFindingsThemedAnimation extends StatelessWidget {
  final String animationPath;
  final double? width;
  final double? height;

  const EmptyFindingsThemedAnimation({
    super.key,
    required this.animationPath,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final (bgCircle, primaryColor, isDark) = context.select(
      (ThemeCubit cubit) => (
        cubit.state.theme.bgCircle,
        cubit.state.theme.primaryColor,
        cubit.state.theme.isDark,
      ),
    );

    return RepaintBoundary(
      child: Lottie.asset(
        animationPath,
        width: width,
        height: height,
        delegates: LottieDelegates(
          values: [
            ValueDelegate.color(const [
              'bg Outlines',
              '**',
              'Fill 1',
            ], value: bgCircle),
            ValueDelegate.color(const [
              'Sombra lupa',
              'LUPA sombra',
              '**',
              'Fill 1',
            ], value: bgCircle),
            ValueDelegate.color(const [
              'Papel front Outlines',
              'Group 3',
              '**',
              'Fill 1',
            ], value: bgCircle),

            ValueDelegate.strokeColor(const ['**'], value: primaryColor),

            ValueDelegate.color(const [
              'papel bot Outlines',
              '**',
              'Fill 1',
            ], value: primaryColor),
            ValueDelegate.color(const [
              'Papel top Outlines',
              '**',
              'Fill 1',
            ], value: primaryColor),
            ValueDelegate.color(const [
              'Papel front Outlines',
              'Group 1',
              '**',
              'Fill 1',
            ], value: primaryColor),
            ValueDelegate.color(const [
              'LUPA rotacion 3D',
              'Group 1',
              '**',
              'Fill 1',
            ], value: primaryColor),
            ValueDelegate.color(const [
              'LUPA rotacion 3D',
              'Group 3',
              '**',
              'Fill 1',
            ], value: primaryColor),
            ValueDelegate.color(const [
              'circulito Outlines',
              '**',
              'Fill 1',
            ], value: primaryColor),
            ValueDelegate.color(const [
              'x 2 Outlines',
              '**',
              'Fill 1',
            ], value: primaryColor),

            ValueDelegate.color(const [
              'Papel front Outlines',
              'Group 4',
              '**',
              'Fill 1',
            ], value: isDark ? bgCircle : Colors.white),
            ValueDelegate.color(const [
              'LUPA rotacion 3D',
              'Group 2',
              '**',
              'Fill 1',
            ], value: isDark ? bgCircle : Colors.white),
          ],
        ),
      ),
    );
  }
}
