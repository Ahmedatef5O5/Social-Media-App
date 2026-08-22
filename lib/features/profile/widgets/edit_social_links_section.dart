import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/custom_text_form_field.dart';
import '../models/social_platform_info.dart';

class EditSocialLinksSection extends StatefulWidget {
  final Map<String, TextEditingController> controllers;

  const EditSocialLinksSection({super.key, required this.controllers});

  @override
  State<EditSocialLinksSection> createState() => _EditSocialLinksSectionState();
}

class _EditSocialLinksSectionState extends State<EditSocialLinksSection> {
  bool _expanded = false;

  int get _filledCount =>
      widget.controllers.values.where((c) => c.text.trim().isNotEmpty).length;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _toggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(Icons.share_rounded, size: 18, color: primary),
                const Gap(8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Social Media',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall!.copyWith(fontSize: 16),
                      ),
                      const Gap(2),
                      Text(
                        _filledCount > 0
                            ? '$_filledCount link${_filledCount > 1 ? 's' : ''} added'
                            : 'Optional — shown as rich cards on your profile.',
                        style: TextStyle(color: AppColors.grey, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 280),
          sizeCurve: Curves.easeOutCubic,
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: Column(
            children: [
              const Gap(14),
              for (final platform in SocialPlatformInfo.all) ...[
                CustomTextFormField(
                  controller: widget.controllers[platform.key],
                  labelText: platform.label,
                  hintText: platform.hint,
                  prefixIcon: Container(
                    width: 48,
                    alignment: Alignment.center,
                    child: platform.buildGlyph(
                      size: 18,
                      onBrandBackground: false,
                    ),
                  ),
                ),
                const Gap(16),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
