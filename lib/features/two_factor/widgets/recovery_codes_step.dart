import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/themes/app_colors.dart';
import '../../../core/toast/app_toast.dart';
import '../../../core/widgets/custom_elevated_button.dart';
import '../utils/clipboard_guard.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class RecoveryCodesStep extends StatefulWidget {
  final List<String> codes;
  final VoidCallback onDone;
  const RecoveryCodesStep({
    super.key,
    required this.codes,
    required this.onDone,
  });

  @override
  State<RecoveryCodesStep> createState() => _RecoveryCodesStepState();
}

class _RecoveryCodesStepState extends State<RecoveryCodesStep> {
  bool _saved = false;

  String get _asText =>
      'Social Mate recovery codes\n'
      'Each code works once. Keep them somewhere safe.\n\n'
      '${widget.codes.join('\n')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.saveYourRecoveryCodes,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.keepTheseCodesIn,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.5),
            ),
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Wrap(
              children: [
                for (final code in widget.codes)
                  FractionallySizedBox(
                    widthFactor: 0.5,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 14,
                      ),
                      child: SelectableText(
                        code,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: context.ls(1),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ClipboardGuard.copySensitive(_asText);
                  AppToast.success(context.l10n.codesCopiedClipboardClears);
                },
                icon: const Icon(CupertinoIcons.doc_on_doc, size: 18),
                label: Text(context.l10n.copyAll),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    () => SharePlus.instance.share(
                      ShareParams(
                        text: _asText,
                        subject: 'Social Mate recovery codes',
                      ),
                    ),
                icon: const Icon(CupertinoIcons.share, size: 18),
                label: Text(context.l10n.saveShare),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Material(
          color: Colors.transparent,
          child: CheckboxListTile(
            value: _saved,
            onChanged: (v) => setState(() => _saved = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.primaryColor,
            title: Text(
              context.l10n.iSavedTheseCodes,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
        const SizedBox(height: 8),
        CustomElevatedButton(
          txtBtn: 'Done',
          onPressed: _saved ? widget.onDone : null,
        ),
      ],
    );
  }
}
