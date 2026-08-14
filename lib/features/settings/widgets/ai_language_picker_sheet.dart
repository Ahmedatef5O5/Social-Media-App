import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../ai_assistant/entities/ai_autocomplete_language.dart';


class AiLanguagePickerSheet extends StatelessWidget {
  const AiLanguagePickerSheet({super.key, required this.selected});
  final AiAutoCompleteLanguage selected;

  static Future<AiAutoCompleteLanguage?> show(
    BuildContext context,
    AiAutoCompleteLanguage current,
  ) {
    return showModalBottomSheet<AiAutoCompleteLanguage>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AiLanguagePickerSheet(selected: current),
    );
  }

  static const _options = <AiAutoCompleteLanguage, (String, IconData)>{
    AiAutoCompleteLanguage.auto: (
      'Detects the language automatically from what you\'re writing or replying to',
      Icons.auto_awesome_rounded,
    ),
    AiAutoCompleteLanguage.arabic: (
      'AI captions, replies, and corrections are always generated in Arabic',
      Icons.translate_rounded,
    ),
    AiAutoCompleteLanguage.english: (
      'AI captions, replies, and corrections are always generated in English',
      Icons.translate_rounded,
    ),
  };

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Auto Complete Language',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const Gap(4),
            const Text(
              'Which language should AI captions, replies, and corrections use?',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Gap(12),
            ..._options.entries.map((entry) {
              final language = entry.key;
              final (subtitle, icon) = entry.value;
              final isSelected = language == selected;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  icon,
                  color: isSelected ? Theme.of(context).primaryColor : null,
                ),
                title: Text(
                  language.displayLabel,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
                trailing:
                    isSelected
                        ? Icon(
                          Icons.check_circle_rounded,
                          color: Theme.of(context).primaryColor,
                        )
                        : null,
                onTap: () => Navigator.pop(context, language),
              );
            }),
          ],
        ),
      ),
    );
  }
}
