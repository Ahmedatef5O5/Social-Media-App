import 'package:flutter/material.dart';

enum ReportReason {
  violence(
    'violence',
    'Violence or threats',
    'Threats, incitement or graphic violence',
    Icons.warning_amber_rounded,
  ),
  nsfw(
    'nsfw',
    'Nudity or sexual content',
    'Explicit or adult material',
    Icons.visibility_off_outlined,
  ),
  childSafety(
    'child_safety',
    'Child safety',
    'Involves or endangers a minor',
    Icons.child_care_outlined,
  ),
  hateHarassment(
    'hate_harassment',
    'Hate or harassment',
    'Bullying, abuse or discrimination',
    Icons.sentiment_dissatisfied_outlined,
  ),
  spamScam(
    'spam_scam',
    'Spam or scam',
    'Fake offers, phishing or repeated ads',
    Icons.campaign_outlined,
  ),
  misinformation(
    'misinformation',
    'False information',
    'Misleading or fabricated content',
    Icons.fact_check_outlined,
  ),
  impersonationPrivacy(
    'impersonation_privacy',
    'Impersonation or privacy',
    'Pretending to be someone or sharing private info',
    Icons.person_off_outlined,
  ),
  selfHarm(
    'self_harm',
    'Self-harm',
    'Promotes or shows self-injury',
    Icons.healing_outlined,
  ),
  other(
    'other',
    'Something else',
    'Tell us what is wrong',
    Icons.more_horiz_rounded,
  );

  final String dbValue;
  final String title;
  final String subtitle;
  final IconData icon;

  const ReportReason(this.dbValue, this.title, this.subtitle, this.icon);
}
