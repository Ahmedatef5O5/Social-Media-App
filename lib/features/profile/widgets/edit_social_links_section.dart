import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/custom_text_form_field.dart';
import '../models/social_platform_info.dart';

class EditSocialLinksSection extends StatelessWidget {
  final Map<String, TextEditingController> controllers;

  const EditSocialLinksSection({super.key, required this.controllers});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.share_rounded,
              size: 18,
              color: Theme.of(context).primaryColor,
            ),
            const Gap(8),
            Text(
              'Social Media',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall!.copyWith(fontSize: 16),
            ),
          ],
        ),
        const Gap(4),
        Text(
          'Optional — shown as rich cards on your profile.',
          style: TextStyle(color: AppColors.grey, fontSize: 12.5),
        ),
        const Gap(16),
        for (final platform in SocialPlatformInfo.all) ...[
          CustomTextFormField(
            controller: controllers[platform.key],
            labelText: platform.label,
            hintText: platform.hint,
            prefixIcon: platform.buildGlyph(size: 17, onBrandBackground: false),
          ),
          const Gap(16),
        ],
      ],
    );
  }
}
