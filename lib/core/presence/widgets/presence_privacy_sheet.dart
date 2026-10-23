import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../models/presence_privacy.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

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

  static const _icons = <PresencePrivacy, IconData>{
    PresencePrivacy.everyone: Icons.public,
    PresencePrivacy.friends: Icons.people_alt_outlined,
    PresencePrivacy.specific: Icons.person_search_outlined,
    PresencePrivacy.nobody: Icons.visibility_off_outlined,
  };
  String _labelFor(BuildContext context, PresencePrivacy privacy) =>
      switch (privacy) {
        PresencePrivacy.everyone => context.l10n.presenceEveryone,
        PresencePrivacy.friends => context.l10n.presenceFriends,
        PresencePrivacy.specific => context.l10n.presenceSpecific,
        PresencePrivacy.nobody => context.l10n.presenceNobody,
      };
  String _subtitleFor(BuildContext context, PresencePrivacy privacy) =>
      switch (privacy) {
        PresencePrivacy.everyone => context.l10n.presenceEveryoneDesc,
        PresencePrivacy.friends => context.l10n.presenceFriendsDesc,
        PresencePrivacy.specific => context.l10n.presenceSpecificDesc,
        PresencePrivacy.nobody => context.l10n.presenceNobodyDesc,
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
            Text(
              context.l10n.whoCanSeeYour,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const Gap(4),
            Text(
              context.l10n.thisControlsYourGreen,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Gap(12),
            ...PresencePrivacy.values.map((privacy) {
              final isSelected = privacy == selected;
              final icon = _icons[privacy] ?? Icons.public;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  icon,
                  color: isSelected ? Theme.of(context).primaryColor : null,
                ),
                title: Text(
                  _labelFor(context, privacy),
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  _subtitleFor(context, privacy),
                  style: const TextStyle(fontSize: 12),
                ),
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
