import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';
import '../../../core/chat_shared/cubits/shared_media_cubit/shared_media_cubit.dart';
import '../../../core/chat_shared/widgets/shared_media_preview_section.dart';
import '../models/group_profile_model.dart';
import 'group_view_header.dart';

/// Tab 3 of GroupView: about, creation info, posting policy and shared media.
class GroupDetailsTab extends StatelessWidget {
  final GroupProfileModel profile;
  final SharedMediaCubit mediaCubit;
  final void Function(BuildContext sheetContext, String messageId)?
  onShowInChat;

  const GroupDetailsTab({
    super.key,
    required this.profile,
    required this.mediaCubit,
    this.onShowInChat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final created = DateFormat.yMMMMd(
      locale,
    ).format(profile.createdAt.toLocal());
    final muted = theme.colorScheme.onSurfaceVariant;

    Widget row(IconData icon, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 19, color: theme.primaryColor),
          const Gap(12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium!.copyWith(
                letterSpacing: context.ls(0),
              ),
            ),
          ),
        ],
      ),
    );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (profile.description?.trim().isNotEmpty == true) ...[
                Text(
                  context.l10n.groupDescription,
                  style: theme.textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.w700,
                    color: muted,
                  ),
                ),
                const Gap(6),
                Text(
                  profile.description!.trim(),
                  style: theme.textTheme.bodyMedium!.copyWith(height: 1.45),
                ),
                const Gap(10),
                const Divider(height: 1),
                const Gap(6),
              ],
              row(Icons.event_rounded, context.l10n.createdOnDate(created)),
              if (profile.creatorName?.trim().isNotEmpty == true)
                row(
                  Icons.person_outline_rounded,
                  context.l10n.createdByName(profile.creatorName!),
                ),
              row(Icons.lock_outline_rounded, context.l10n.groupPrivateNotice),
              row(
                Icons.edit_note_rounded,
                '${context.l10n.whoCanPost}: ${whoCanPostLabel(context, profile.whoCanPost)}',
              ),
            ],
          ),
        ),
        SharedMediaPreviewSection(
          mediaCubit: mediaCubit,
          onShowInChat: onShowInChat,
        ),
      ],
    );
  }
}
