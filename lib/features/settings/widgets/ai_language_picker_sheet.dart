import 'package:flutter/material.dart';
import '../../ai_assistant/entities/ai_autocomplete_language.dart';
import 'ai_setting_option_card.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class AiLanguagePickerSheet extends StatelessWidget {
  const AiLanguagePickerSheet({super.key, required this.selected});
  final AiAutoCompleteLanguage selected;

  static Future<AiAutoCompleteLanguage?> show(
    BuildContext context,
    AiAutoCompleteLanguage current,
  ) {
    return showModalBottomSheet<AiAutoCompleteLanguage>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AiLanguagePickerSheet(selected: current),
    );
  }

  static const _icons = <AiAutoCompleteLanguage, IconData>{
    AiAutoCompleteLanguage.auto: Icons.auto_awesome_rounded,
    AiAutoCompleteLanguage.arabic: Icons.translate_rounded,
    AiAutoCompleteLanguage.english: Icons.translate_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? theme.scaffoldBackgroundColor : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            spreadRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pill Handle
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                context.l10n.autoCompleteLanguage,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: context.ls(0.2),
                ),
              ),
              const SizedBox(height: 6),

              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  context.l10n.whichLanguageShouldAi,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Scrollable Options List
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children:
                        AiAutoCompleteLanguage.values.map((language) {
                          return AiSettingOptionCard<AiAutoCompleteLanguage>(
                            value: language,
                            currentValue: selected,
                            title: language.localizedTitle(context),
                            subtitle: language.localizedDescription(context),
                            icon: _icons[language] ?? Icons.translate_rounded,
                          );
                        }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
