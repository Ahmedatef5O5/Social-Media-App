import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';

class DiscoverPeopleHeaderSection extends StatelessWidget {
  const DiscoverPeopleHeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Discover People',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              color: AppColors.black54,
              fontSize: 19,
              fontWeight: FontWeight.w400,
            ),
          ),
          Icon(Icons.more_vert_outlined, color: AppColors.black54, size: 26),
        ],
      ),
    );
  }
}
