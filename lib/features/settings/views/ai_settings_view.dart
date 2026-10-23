import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../../ai_assistant/cubits/ai_preferences_cubit/ai_preferences_cubit.dart';
import '../../ai_assistant/entities/ai_autocomplete_language.dart';
import '../../ai_assistant/entities/ai_reply_length.dart';
import '../../ai_assistant/entities/ai_reply_tone.dart';
import '../../ai_assistant/widgets/ai_usage_quota_card.dart';
import '../widgets/ai_language_picker_sheet.dart';
import '../widgets/ai_reply_length_picker_sheet.dart';
import '../widgets/ai_reply_tone_picker_sheet.dart';
import '../widgets/settings_detail_sliver_app_bar.dart';
import '../widgets/settings_item_data.dart';
import '../widgets/settings_section.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class AiSettingsView extends StatelessWidget {
  const AiSettingsView({super.key});

  Future<void> _pickAiLanguage(
    BuildContext context,
    AiAutoCompleteLanguage current,
  ) async {
    final result = await AiLanguagePickerSheet.show(context, current);
    if (result == null || !context.mounted) return;
    await context.read<AiPreferencesCubit>().setLanguage(result);
  }

  Future<void> _pickReplyTone(BuildContext context, AiReplyTone current) async {
    final result = await AiReplyTonePickerSheet.show(context, current);
    if (result == null || !context.mounted) return;
    await context.read<AiPreferencesCubit>().setReplyTone(result);
  }

  Future<void> _pickReplyLength(
    BuildContext context,
    AiReplyLength current,
  ) async {
    final result = await AiReplyLengthPickerSheet.show(context, current);
    if (result == null || !context.mounted) return;
    await context.read<AiPreferencesCubit>().setReplyLength(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocBuilder<AiPreferencesCubit, AiPreferencesState>(
        builder: (context, aiState) {
          return CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              SettingsDetailSliverAppBar(
                icon: Icons.auto_awesome_rounded,
                title: context.l10n.settingsAiSettings,
                subtitle: context.l10n.featuresLanguageUsage,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SettingsSection(
                        title: context.l10n.aiFeatures,
                        icon: Icons.tune_rounded,
                        delay: 0,
                        items: [
                          SettingsItemData(
                            icon: Icons.auto_fix_high_rounded,
                            label: context.l10n.aiAutoComplete,
                            subtitle: context.l10n.tapTheAiIcon,
                            toggle: aiState.autoCompleteEnabled,
                            onToggle:
                                (v) => context
                                    .read<AiPreferencesCubit>()
                                    .toggleAutoComplete(v),
                          ),
                          SettingsItemData(
                            icon: Icons.spellcheck_rounded,
                            label: context.l10n.aiAutoDetect,
                            subtitle:
                                context.l10n.automaticSpellingSuggestionsWhile,
                            toggle: aiState.autoDetectEnabled,
                            onToggle:
                                (v) => context
                                    .read<AiPreferencesCubit>()
                                    .toggleAutoDetect(v),
                            footer:
                                aiState.autoDetectEnabled
                                    ? const _AutoDetectQuotaWarning()
                                    : null,
                          ),
                          SettingsItemData(
                            icon: Icons.mode_comment_outlined,
                            label: context.l10n.aiCommentSuggestions,
                            subtitle: context.l10n.quickAiSuggestedReplies,
                            toggle: aiState.commentSuggestionsEnabled,
                            onToggle:
                                (v) => context
                                    .read<AiPreferencesCubit>()
                                    .toggleCommentSuggestions(v),
                          ),
                          SettingsItemData(
                            icon: Icons.translate_rounded,
                            label: context.l10n.autoCompleteLanguage,
                            subtitle: aiState.language.localizedTitle(context),
                            onTap:
                                () =>
                                    _pickAiLanguage(context, aiState.language),
                          ),
                          SettingsItemData(
                            icon: Icons.record_voice_over_rounded,
                            label: context.l10n.replyTone,
                            subtitle: aiState.replyTone.localizedTitle(context),
                            onTap:
                                () =>
                                    _pickReplyTone(context, aiState.replyTone),
                          ),
                          SettingsItemData(
                            icon: Icons.straighten_rounded,
                            label: context.l10n.replyLength,
                            subtitle: aiState.replyLength.localizedTitle(
                              context,
                            ),
                            onTap:
                                () => _pickReplyLength(
                                  context,
                                  aiState.replyLength,
                                ),
                          ),
                        ],
                      ),
                      const Gap(12),
                      const AiUsageQuotaCard(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AutoDetectQuotaWarning extends StatelessWidget {
  const _AutoDetectQuotaWarning();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final warningColor = Colors.amber.shade700;

    return Padding(
      padding: const EdgeInsets.fromLTRB(68, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: warningColor.withValues(alpha: isDark ? 0.14 : 0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.bolt_rounded, size: 15, color: warningColor),
            const Gap(6),
            Expanded(
              child: Text(
                context.l10n.thisFeatureChecksYour,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
