import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';
import '../models/group_model.dart';
import 'group_privacy_pill.dart';

/// Group identity card: avatar picker + rounded name field + privacy hint.
class GroupHeaderSection extends StatelessWidget {
  final File? groupImage;
  final VoidCallback onPickImage;
  final TextEditingController controller;
  final Color primary;
  final bool isDark;
  final GroupPrivacy privacy;

  const GroupHeaderSection({
    super.key,
    required this.groupImage,
    required this.onPickImage,
    required this.controller,
    required this.primary,
    required this.isDark,
    this.privacy = GroupPrivacy.privateGroup,
  });

  OutlineInputBorder _border(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: c, width: w),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hairline = theme.colorScheme.outlineVariant.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: onPickImage,
                  child: Stack(
                    children: [
                      Container(
                        height: 70,
                        width: 70,
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          image:
                              groupImage != null
                                  ? DecorationImage(
                                    image: FileImage(groupImage!),
                                    fit: BoxFit.cover,
                                  )
                                  : null,
                          border: Border.all(
                            color: primary.withValues(alpha: 0.25),
                            width: 2,
                          ),
                        ),
                        child:
                            groupImage == null
                                ? Icon(
                                  Icons.groups_rounded,
                                  size: 32,
                                  color: primary,
                                )
                                : null,
                      ),
                      PositionedDirectional(
                        bottom: 0,
                        end: 0,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.surface,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(14),
                Expanded(
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, _) {
                      return TextField(
                        controller: controller,
                        textInputAction: TextInputAction.done,
                        maxLength: 60,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: context.l10n.enterGroupName,
                          hintStyle: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          filled: true,
                          fillColor:
                              isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : theme.colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.45),
                          contentPadding: const EdgeInsetsDirectional.fromSTEB(
                            14,
                            14,
                            6,
                            14,
                          ),
                          isDense: true,
                          border: _border(hairline),
                          enabledBorder: _border(hairline),
                          focusedBorder: _border(
                            primary.withValues(alpha: 0.55),
                            1.5,
                          ),
                          suffixIcon:
                              value.text.isEmpty
                                  ? null
                                  : IconButton(
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                    ),
                                    onPressed: controller.clear,
                                  ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const Gap(12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Row(
                key: ValueKey(privacy),
                children: [
                  Icon(groupPrivacyIcon(privacy), size: 15, color: primary),
                  const Gap(6),
                  Expanded(
                    child: Text(
                      privacy.isPublic
                          ? context.l10n.groupPrivacyPublicHelper
                          : context.l10n.groupPrivacyPrivateHelper,
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                        letterSpacing: context.ls(0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
