import 'package:flutter/material.dart';

class AiChatForwardSheet {
  const AiChatForwardSheet._();

  static void show(BuildContext context, {required VoidCallback onForward}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.shortcut_rounded),
                  title: const Text('Forward'),
                  onTap: () {
                    Navigator.pop(ctx);
                    onForward();
                  },
                ),
              ],
            ),
          ),
    );
  }
}
