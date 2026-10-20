import 'package:flutter/material.dart';
import '../models/ai_chat_session.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

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
            title: Text(
              context.l10n.deleteThisChat,
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              context.l10n.deleteThisPermanentlyRemoves(session.title),
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  context.l10n.cancel,
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  context.l10n.delete,
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
    );
  }
}
