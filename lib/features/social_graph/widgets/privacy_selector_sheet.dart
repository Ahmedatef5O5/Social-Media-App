import 'package:flutter/material.dart';
import '../models/content_privacy.dart';

Future<ContentPrivacy?> showPrivacySelectorSheet(
  BuildContext context, {
  required ContentPrivacy currentPrivacy,
}) {
  return showModalBottomSheet<ContentPrivacy>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      Widget option(ContentPrivacy value, String label, IconData icon) {
        return ListTile(
          leading: Icon(icon),
          title: Text(label),
          trailing: currentPrivacy == value ? const Icon(Icons.check) : null,
          onTap: () => Navigator.pop(context, value),
        );
      }

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            option(ContentPrivacy.public, 'Public', Icons.public),
            option(ContentPrivacy.friends, 'Friends', Icons.people_alt_rounded),
            option(
              ContentPrivacy.private,
              'Private (Specific people)',
              Icons.lock_outline,
            ),
          ],
        ),
      );
    },
  );
}
