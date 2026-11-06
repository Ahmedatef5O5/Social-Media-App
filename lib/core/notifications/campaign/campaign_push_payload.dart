import 'package:flutter/foundation.dart';

/// Where a campaign push sends the user when tapped.
enum CampaignRoute { none, post, profile, announcement }

final RegExp _uuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// Parsed `data` block of a push sent by the `dispatch-campaign` Edge Function.
///
/// Contract (keep in sync with supabase/functions/dispatch-campaign/fcm.ts and
/// the admin payload inspector):
///   notificationType = "campaign"
///   campaign_id      = campaign UUID
///   route            = "post" | "profile" | "announcement"   (optional)
///   target_id        = post / user UUID, or an announcement id (optional)
///
/// Parsing is deliberately forgiving: a malformed or unknown route never
/// throws; it degrades to [CampaignRoute.none], so the tap just opens the app.
@immutable
class CampaignPushPayload {
  const CampaignPushPayload({
    this.campaignId,
    this.route = CampaignRoute.none,
    this.targetId,
  });

  static const String notificationType = 'campaign';
  static const String localPayloadPrefix = 'campaign|';

  final String? campaignId;
  final CampaignRoute route;
  final String? targetId;

  static bool isCampaign(Map<String, dynamic> data) =>
      data['notificationType'] == notificationType;

  static bool isLocalPayload(String? payload) =>
      payload != null && payload.startsWith(localPayloadPrefix);

  factory CampaignPushPayload.fromData(Map<String, dynamic> data) {
    String? text(String key) {
      final v = data[key];
      if (v is! String) return null;
      final t = v.trim();
      return t.isEmpty ? null : t;
    }

    final target = text('target_id');
    final route = switch (text('route')) {
      'post' when target != null && _uuid.hasMatch(target) =>
        CampaignRoute.post,
      'profile' when target != null && _uuid.hasMatch(target) =>
        CampaignRoute.profile,
      'announcement' => CampaignRoute.announcement,
      _ => CampaignRoute.none,
    };

    return CampaignPushPayload(
      campaignId: text('campaign_id'),
      route: route,
      targetId: route == CampaignRoute.none ? null : target,
    );
  }

  /// Payload string carried by the *local* notification shown while the app is
  /// in the foreground: `campaign|<route>|<targetId>|<campaignId>`.
  String toLocalPayload() =>
      '$localPayloadPrefix${route.name}|${targetId ?? ''}|${campaignId ?? ''}';

  static CampaignPushPayload? fromLocalPayload(String? payload) {
    if (!isLocalPayload(payload)) return null;
    final parts = payload!.split('|');
    if (parts.length < 2) return null;
    final route = CampaignRoute.values.firstWhere(
      (r) => r.name == parts[1],
      orElse: () => CampaignRoute.none,
    );
    final target = parts.length > 2 && parts[2].isNotEmpty ? parts[2] : null;
    final campaignId =
        parts.length > 3 && parts[3].isNotEmpty ? parts[3] : null;
    // Re-validate: the string is only as trustworthy as whoever wrote it.
    return CampaignPushPayload.fromData({
      'notificationType': notificationType,
      'route': route == CampaignRoute.none ? null : route.name,
      'target_id': target,
      'campaign_id': campaignId,
    });
  }

  @override
  bool operator ==(Object other) =>
      other is CampaignPushPayload &&
      other.campaignId == campaignId &&
      other.route == route &&
      other.targetId == targetId;

  @override
  int get hashCode => Object.hash(campaignId, route, targetId);

  @override
  String toString() =>
      'CampaignPushPayload(campaign: $campaignId, route: ${route.name}, target: $targetId)';
}

/// `android` / `ios` for the device, or null elsewhere. Stored in
/// `users.fcm_platform` next to the token so campaigns can target a platform.
String? currentPushPlatform([TargetPlatform? platform]) {
  switch (platform ?? defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'android';
    case TargetPlatform.iOS:
      return 'ios';
    default:
      return null;
  }
}
