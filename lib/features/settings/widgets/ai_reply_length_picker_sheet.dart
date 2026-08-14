import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../ai_assistant/entities/ai_reply_length.dart';

class AiReplyLengthPickerSheet extends StatelessWidget {
  const AiReplyLengthPickerSheet({super.key, required this.selected});
  final AiReplyLength selected;

  static Future<AiReplyLength?> show(
    BuildContext context,
    AiReplyLength current,
  ) {
    return showModalBottomSheet<AiReplyLength>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
              'Reply Length',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const Gap(4),
            const Text(
              'How long should AI-generated captions and replies be?',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Gap(12),
            ..._options.entries.map((entry) {
              final length = entry.key;
              final (subtitle, icon) = entry.value;
              final isSelected = length == selected;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  icon,
                  color: isSelected ? Theme.of(context).primaryColor : null,
                ),
                title: Text(
                  length.displayLabel,
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
                onTap: () => Navigator.pop(context, length),
              );
            }),
          ],
        ),
      ),
    );
  }
}
