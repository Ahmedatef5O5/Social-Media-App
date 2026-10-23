import 'package:flutter/material.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

enum ReportReason {
  violence('violence', Icons.warning_amber_rounded),
  nsfw('nsfw', Icons.visibility_off_outlined),
  childSafety('child_safety', Icons.child_care_outlined),
  hateHarassment('hate_harassment', Icons.sentiment_dissatisfied_outlined),
  spamScam('spam_scam', Icons.campaign_outlined),
  misinformation('misinformation', Icons.fact_check_outlined),
  impersonationPrivacy('impersonation_privacy', Icons.person_off_outlined),
  selfHarm('self_harm', Icons.healing_outlined),
  other('other', Icons.more_horiz_rounded);

  final String dbValue;
  final IconData icon;

  const ReportReason(this.dbValue, this.icon);

  String localizedTitle(BuildContext context) => switch (this) {
    ReportReason.violence => context.l10n.reportReasonViolence,
    ReportReason.nsfw => context.l10n.reportReasonNsfw,
    ReportReason.childSafety => context.l10n.reportReasonChildSafety,
    ReportReason.hateHarassment => context.l10n.reportReasonHateHarassment,
    ReportReason.spamScam => context.l10n.reportReasonSpamScam,
    ReportReason.misinformation => context.l10n.reportReasonMisinformation,
    ReportReason.impersonationPrivacy => context.l10n.reportReasonImpersonation,
    ReportReason.selfHarm => context.l10n.reportReasonSelfHarm,
    ReportReason.other => context.l10n.reportReasonOther,
  };

  String localizedSubtitle(BuildContext context) => switch (this) {
    ReportReason.violence => context.l10n.reportReasonViolenceDesc,
    ReportReason.nsfw => context.l10n.reportReasonNsfwDesc,
    ReportReason.childSafety => context.l10n.reportReasonChildSafetyDesc,
    ReportReason.hateHarassment => context.l10n.reportReasonHateHarassmentDesc,
    ReportReason.spamScam => context.l10n.reportReasonSpamScamDesc,
    ReportReason.misinformation => context.l10n.reportReasonMisinformationDesc,
    ReportReason.impersonationPrivacy =>
      context.l10n.reportReasonImpersonationDesc,
    ReportReason.selfHarm => context.l10n.reportReasonSelfHarmDesc,
    ReportReason.other => context.l10n.reportReasonOtherDesc,
  };
}
