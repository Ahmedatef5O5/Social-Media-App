import 'package:flutter/material.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';
import '../../../core/toast/app_toast.dart';
import '../models/group_model.dart';

/// Polite explanation shown when a restricted member taps a call button.
void showGroupCallRestrictedToast(
  BuildContext context,
  GroupWhoCanSend policy,
) {
  final l = context.l10n;
  AppToast.info(
    policy == GroupWhoCanSend.ownerOnly
        ? l.groupCallsRestrictedOwnerOnly
        : l.groupCallsRestrictedAdminsOnly,
  );
}

/// Small circular lock overlay. Place it inside a [Stack] with
/// `PositionedDirectional(bottom: .., end: ..)` so it sits bottom-right in
/// LTR and bottom-left in RTL.
class GroupLockBadge extends StatelessWidget {
  const GroupLockBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        shape: BoxShape.circle,
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: Icon(
        Icons.lock_rounded,
        size: 10.5,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Replaces the message input bar for an ACTIVE but restricted member.
class GroupChatRestrictedBanner extends StatelessWidget {
  final GroupWhoCanSend policy;
  const GroupChatRestrictedBanner({super.key, required this.policy});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final text =
        policy == GroupWhoCanSend.ownerOnly
            ? l.groupChatRestrictedOwnerOnly
            : l.groupChatRestrictedAdminsOnly;
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline_rounded, size: 16, color: theme.hintColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
                fontWeight: FontWeight.w500,
                letterSpacing: context.ls(0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
