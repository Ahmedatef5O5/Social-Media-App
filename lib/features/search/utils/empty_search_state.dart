import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/widgets/empty_findings_animation_widget.dart';

class EmptySearchState extends StatelessWidget {
  const EmptySearchState({super.key, required this.theme, required this.query});

  final ThemeData theme;
  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const EmptyFindingsThemedAnimation(
              animationPath: AppImages.emptyFindingsLot,
              width: 150,
              height: 150,
            ),
            const Gap(12),
            Text(
              query.isEmpty
                  ? 'Nothing to show yet'
                  : 'No results found for "$query"',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
