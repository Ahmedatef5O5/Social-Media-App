import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';
import '../../../core/design/components/app_bottom_sheet.dart';
import '../models/group_model.dart';

String groupPrivacyLabel(BuildContext context, GroupPrivacy p) =>
    p.isPublic
        ? context.l10n.groupPrivacyPublic
        : context.l10n.groupPrivacyPrivate;

IconData groupPrivacyIcon(GroupPrivacy p) =>
    p.isPublic ? Icons.public_rounded : Icons.lock_rounded;

/// AppBar action: shows the chosen privacy and opens a 2-option explainer.
class GroupPrivacyPill extends StatelessWidget {
  final GroupPrivacy value;
  final ValueChanged<GroupPrivacy> onChanged;

  const GroupPrivacyPill({
    super.key,
    required this.value,
    required this.onChanged,
  });

  Future<void> _open(BuildContext context) async {
    final picked = await AppBottomSheet.show<GroupPrivacy>(
      context: context,
      builder:
          (ctx) => AppBottomSheet(
            title: ctx.l10n.groupPrivacyTitle,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final p in GroupPrivacy.values)
                  _PrivacyOptionTile(
                    privacy: p,
                    selected: p == value,
                    onTap: () => Navigator.of(ctx).pop(p),
                  ),
              ],
            ),
          ),
    );
    if (picked != null && picked != value) {
      HapticFeedback.selectionClick();
      onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 12),
      child: Center(
        child: Material(
          color: primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _open(context),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 8, 6),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Row(
                  key: ValueKey(value),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(groupPrivacyIcon(value), size: 15, color: primary),
                    const Gap(5),
                    Text(
                      groupPrivacyLabel(context, value),
                      style: TextStyle(
                        color: primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: context.ls(0),
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrivacyOptionTile extends StatelessWidget {
  final GroupPrivacy privacy;
  final bool selected;
  final VoidCallback onTap;
  const _PrivacyOptionTile({
    required this.privacy,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: CircleAvatar(
          backgroundColor: primary.withValues(alpha: 0.1),
          child: Icon(groupPrivacyIcon(privacy), color: primary, size: 20),
        ),
        title: Text(
          groupPrivacyLabel(context, privacy),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          privacy.isPublic
              ? context.l10n.groupPrivacyPublicHelper
              : context.l10n.groupPrivacyPrivateHelper,
          style: TextStyle(letterSpacing: context.ls(0)),
        ),
        trailing:
            selected
                ? Icon(Icons.check_circle_rounded, color: primary)
                : const SizedBox(width: 24),
      ),
    );
  }
}
