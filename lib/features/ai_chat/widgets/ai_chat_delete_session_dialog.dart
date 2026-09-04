import 'package:flutter/material.dart';
import '../models/ai_chat_session.dart';

class AiChatDeleteSessionDialog {
  const AiChatDeleteSessionDialog._();

  static Future<bool?> show(BuildContext context, AiChatSession session) {
    return showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1C1D24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Delete this chat?',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Delete "${session.title}"? This permanently removes it '
              "from Syncra and can't be undone.",
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
    );
  }
}
