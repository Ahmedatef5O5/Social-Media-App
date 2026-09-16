import 'package:flutter/material.dart';
import '../../ai_assistant/entities/ai_reply_length.dart';
import 'ai_setting_option_card.dart';

class AiReplyLengthPickerSheet extends StatelessWidget {
  const AiReplyLengthPickerSheet({super.key, required this.selected});
  final AiReplyLength selected;

  static Future<AiReplyLength?> show(
    BuildContext context,
    AiReplyLength current,
  ) {
    return showModalBottomSheet<AiReplyLength>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AiReplyLengthPickerSheet(selected: current),
    );
  }

  static const _options = <AiReplyLength, (String, IconData)>{
    AiReplyLength.standard: (
      'Natural, everyday length',
      Icons.auto_awesome_rounded,
    ),
    AiReplyLength.short: ('Brief and to the point', Icons.short_text_rounded),
    AiReplyLength.detailed: ('Longer and more thorough', Icons.subject_rounded),
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
                'Reply Length',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),

              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'How long should AI-generated captions and replies be?',
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
                        _options.entries.map((entry) {
                          final length = entry.key;
                          final (subtitle, icon) = entry.value;
                          return AiSettingOptionCard<AiReplyLength>(
                            value: length,
                            currentValue: selected,
                            title: length.displayLabel,
                            subtitle: subtitle,
                            icon: icon,
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
