import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/design/components/app_bottom_sheet.dart';
import 'package:social_media_app/core/design/components/app_button.dart';
import 'package:social_media_app/core/design/theme/theme_extensions.dart';
import 'package:social_media_app/core/toast/app_toast.dart';
import '../cubits/report_cubit/report_cubit.dart';
import '../models/report_reason.dart';
import '../models/report_target.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class ReportBottomSheet extends StatelessWidget {
  const ReportBottomSheet({super.key});

  /// Single entry point for every surface (post, comment, story, ...).
  static Future<void> show(
    BuildContext context, {
    required ReportTarget target,
  }) {
    if (!context.mounted) {
      debugPrint(
        'ReportBottomSheet.show skipped: context is no longer mounted',
      );
      return Future<void>.value();
    }

    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => BlocProvider(
            create: (_) => ReportCubit(target: target),
            child: const ReportBottomSheet(),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final target = context.read<ReportCubit>().target;

    return BlocListener<ReportCubit, ReportState>(
      listenWhen: (_, current) => current is ReportSubmitted,
      listener: (context, _) {
        Navigator.of(context).pop();
        AppToast.success(context.l10n.thanksForReportingOur);
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: AppBottomSheet(
            title: context.l10n.report2(target.type.label),
            child: const _ReportForm(),
          ),
        ),
      ),
    );
  }
}

class _ReportForm extends StatelessWidget {
  const _ReportForm();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final cubit = context.read<ReportCubit>();

    return BlocBuilder<ReportCubit, ReportState>(
      builder: (context, state) {
        final form = state is ReportFormState ? state : const ReportFormState();
        final selected = form.reason;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.whyAreYouReporting,
              style: context.typography.bodyMedium?.copyWith(
                color: palette.onSurfaceVariant,
              ),
            ),
            const Gap(8),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    for (final reason in ReportReason.values)
                      _ReasonTile(
                        reason: reason,
                        isSelected: reason == selected,
                        onTap: () => cubit.selectReason(reason),
                      ),
                    if (selected != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 4),
                        child: TextField(
                          onChanged: cubit.updateNote,
                          maxLength: ReportCubit.maxNoteLength,
                          minLines: 2,
                          maxLines: 3,
                          textInputAction: TextInputAction.newline,
                          decoration: InputDecoration(
                            hintText:
                                selected == ReportReason.other
                                    ? context.l10n.tellUsWhatIs
                                    : context.l10n.addDetailsOptional,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const Gap(12),
            AppButton(
              text: context.l10n.submitReport,
              onPressed: form.canSubmit ? cubit.submit : null,
            ),
          ],
        );
      },
    );
  }
}

class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    required this.reason,
    required this.isSelected,
    required this.onTap,
  });

  final ReportReason reason;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(
              reason.icon,
              color: isSelected ? palette.primary : palette.onSurfaceVariant,
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reason.title,
                    style: context.typography.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: palette.onSurface,
                    ),
                  ),
                  Text(
                    reason.subtitle,
                    style: context.typography.bodySmall?.copyWith(
                      color: palette.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? palette.primary : palette.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }
}
