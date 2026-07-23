import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../model/presence_privacy.dart';

class PresencePrivacySheet extends StatelessWidget {
  const PresencePrivacySheet({super.key, required this.selected});
  final PresencePrivacy selected;

  static Future<PresencePrivacy?> show(
    BuildContext context,
    PresencePrivacy current,
  ) {
    return showModalBottomSheet<PresencePrivacy>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PresencePrivacySheet(selected: current),
    );
  }

  static const _options = <PresencePrivacy, (String, String, IconData)>{
    PresencePrivacy.everyone: (
      'Everyone',
      'Anyone using the app can see your status',
      Icons.public,
    ),
    PresencePrivacy.friends: (
      'My Friends',
      'Only accepted friends can see your status',
      Icons.people_alt_outlined,
    ),
    PresencePrivacy.specific: (
      'Specific People',
      'Choose exactly who can see your status',
      Icons.person_search_outlined,
    ),
    PresencePrivacy.nobody: (
      'Nobody',
      'Your online status stays private',
      Icons.visibility_off_outlined,
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
              'Who can see your online status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const Gap(4),
            const Text(
              'This controls your green dot and "last seen" everywhere in the app.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Gap(12),
            ..._options.entries.map((entry) {
              final privacy = entry.key;
              final (label, subtitle, icon) = entry.value;
              final isSelected = privacy == selected;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  icon,
                  color: isSelected ? Theme.of(context).primaryColor : null,
                ),
                title: Text(
                  label,
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
                onTap: () => Navigator.pop(context, privacy),
              );
            }),
          ],
        ),
      ),
    );
  }
}
