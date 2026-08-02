import 'package:flutter/material.dart';
import '../entities/ai_action_type.dart';
import 'ai_chat_summary_sheet.dart';

/// Design note: the original plan called for a floating overlay (like the
/// `@`-mention popup), but a bottom sheet gives the same "command menu"
/// result with far less machinery (no LayerLink/OverlayEntry to keep in
/// sync), and works identically for both the plain TextField (single chat)
/// and MentionAwareTextField (group chat) hosts.
class AiChatCommandTrigger {
  /// The exact field content that opens the command menu.
  static const trigger = '/ai';

  static void showCommandMenu({
    required BuildContext context,
    required String Function(int maxMessages) buildTranscript,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CommandTile(
                  icon: Icons.short_text_rounded,
                  label: 'لخّص المحادثة (مختصر)',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openSummary(
                      context,
                      AiActionType.chatSummaryShort,
                      buildTranscript(30),
                    );
                  },
                ),
                _CommandTile(
                  icon: Icons.notes_rounded,
                  label: 'لخّص المحادثة (تفصيلي)',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openSummary(
                      context,
                      AiActionType.chatSummaryDetailed,
                      buildTranscript(100),
                    );
                  },
                ),
                _CommandTile(
                  icon: Icons.help_outline_rounded,
                  label: 'الكلام ده عن إيه؟',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openSummary(
                      context,
                      AiActionType.chatSummaryTopic,
                      buildTranscript(100),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  static void _openSummary(
    BuildContext context,
    AiActionType mode,
    String transcript,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AiChatSummarySheet(mode: mode, transcript: transcript),
    );
  }
}

class _CommandTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CommandTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(label),
      onTap: onTap,
    );
  }
}
