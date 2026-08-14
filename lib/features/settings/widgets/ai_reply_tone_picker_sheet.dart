import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../ai_assistant/entities/ai_reply_tone.dart';

class AiReplyTonePickerSheet extends StatelessWidget {
  const AiReplyTonePickerSheet({super.key, required this.selected});
  final AiReplyTone selected;

  static Future<AiReplyTone?> show(BuildContext context, AiReplyTone current) {
    return showModalBottomSheet<AiReplyTone>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AiReplyTonePickerSheet(selected: current),
    );
  }

  static const _options = <AiReplyTone, (String, IconData)>{
    AiReplyTone.standard: (
      'Lets the AI choose the tone based on context',
      Icons.auto_awesome_rounded,
    ),
    AiReplyTone.formal: (
      'Polished, professional wording',
      Icons.work_outline_rounded,
    ),
    AiReplyTone.enthusiastic: (
      'Energetic and upbeat wording',
      Icons.bolt_rounded,
    ),
    AiReplyTone.casual: (
      'Relaxed, spontaneous everyday wording',
      Icons.emoji_emotions_outlined,
    ),
    AiReplyTone.encouraging: (
      'Warm and supportive wording',
      Icons.favorite_outline_rounded,
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
              'Reply Tone',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const Gap(4),
            const Text(
              'What tone should AI-generated captions and replies use?',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Gap(12),
            ..._options.entries.map((entry) {
              final tone = entry.key;
              final (subtitle, icon) = entry.value;
              final isSelected = tone == selected;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  icon,
                  color: isSelected ? Theme.of(context).primaryColor : null,
                ),
                title: Text(
                  tone.displayLabel,
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
                onTap: () => Navigator.pop(context, tone),
              );
            }),
          ],
        ),
      ),
    );
  }
}
