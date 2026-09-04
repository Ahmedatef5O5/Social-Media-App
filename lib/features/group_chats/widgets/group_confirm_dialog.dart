import 'package:flutter/material.dart';

class GroupConfirmDialog {
  const GroupConfirmDialog._();

 static Future<bool?> show(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  required Color confirmColor,
}) {
  return showDialog<bool>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                confirmLabel,
                style: TextStyle(color: confirmColor),
              ),
            ),
          ],
        ),
  );
}
}
