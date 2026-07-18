import 'package:flutter/material.dart';
import '../models/content_privacy.dart';
import '../views/audience_picker_view.dart';
import '../widgets/privacy_selector_sheet.dart';

class PrivacySelection {
  final ContentPrivacy privacy;
  final Set<String> allowedViewerIds;

  const PrivacySelection({
    required this.privacy,
    required this.allowedViewerIds,
  });
}

Future<PrivacySelection?> pickContentPrivacy(
  BuildContext context, {
  required ContentPrivacy currentPrivacy,
  required Set<String> currentViewerIds,
}) async {
  final result = await showPrivacySelectorSheet(
    context,
    currentPrivacy: currentPrivacy,
  );
  if (result == null || !context.mounted) return null;

  if (result == ContentPrivacy.private) {
    final selected = await Navigator.of(
      context,
      rootNavigator: true,
    ).push<Set<String>>(
      MaterialPageRoute(
        builder:
            (_) => AudiencePickerView(initialSelectedIds: currentViewerIds),
      ),
    );
    if (selected == null || selected.isEmpty) return null;
    return PrivacySelection(
      privacy: ContentPrivacy.private,
      allowedViewerIds: selected,
    );
  }

  return PrivacySelection(privacy: result, allowedViewerIds: const {});
}
