import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/themes/app_colors.dart';

class StatItemWidget extends StatelessWidget {
  final String label;
  final String value;
  const StatItemWidget({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.black54,
            fontSize: 23,
            height: 0.6,
          ),
        ),
        const Gap(4),
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
            fontSize: 12,
            color: AppColors.black54,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
