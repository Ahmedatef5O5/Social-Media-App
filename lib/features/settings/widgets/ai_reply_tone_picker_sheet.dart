import 'package:flutter/material.dart';
import '../../ai_assistant/entities/ai_reply_tone.dart';
import 'ai_setting_option_card.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class AiReplyTonePickerSheet extends StatelessWidget {
  const AiReplyTonePickerSheet({super.key, required this.selected});
  final AiReplyTone selected;

  static Future<AiReplyTone?> show(BuildContext context, AiReplyTone current) {
    return showModalBottomSheet<AiReplyTone>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AiReplyTonePickerSheet(selected: current),
    );
  }

  static const _icons = <AiReplyTone, IconData>{
    AiReplyTone.standard: Icons.auto_awesome_rounded,
    AiReplyTone.formal: Icons.work_outline_rounded,
    AiReplyTone.enthusiastic: Icons.bolt_rounded,
    AiReplyTone.casual: Icons.emoji_emotions_outlined,
    AiReplyTone.encouraging: Icons.favorite_outline_rounded,
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
                context.l10n.replyTone,
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
                  context.l10n.whatToneShouldAi,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Scrollable Options List (Prevents any Overflow)
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children:
                        AiReplyTone.values.map((tone) {
                          return AiSettingOptionCard<AiReplyTone>(
                            value: tone,
                            currentValue: selected,
                            title: tone.localizedTitle(context),
                            subtitle: tone.localizedDescription(context),
                            icon: _icons[tone] ?? Icons.auto_awesome_rounded,
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
