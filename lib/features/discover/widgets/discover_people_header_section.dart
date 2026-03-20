import 'package:flutter/material.dart';
import 'package:social_media_app/core/widgets/custom_header_widget.dart';
import '../../../core/themes/app_colors.dart';

class DiscoverPeopleHeaderSection extends StatelessWidget {
  const DiscoverPeopleHeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomHeader(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      title: 'Discover People',
      style: Theme.of(context).textTheme.titleMedium!.copyWith(
        color: AppColors.black54,
        fontSize: 19,
        fontWeight: FontWeight.w400,
      ),
      actions: const Icon(
        Icons.more_vert_outlined,
        color: AppColors.black54,
        size: 26,
      ),
    );
  }
}
