import 'package:flutter/material.dart';
import 'package:social_media_app/core/helpers/content_deep_link_navigator.dart';
import 'package:social_media_app/core/notifications/campaign/campaign_push_payload.dart';
import 'package:social_media_app/core/notifications/notification_navigator_key.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/core/supabase/supabase_provider.dart';
import 'package:social_media_app/core/utilities/supabase_constants.dart';
import 'package:social_media_app/features/notifications/views/notification_view.dart';
import 'package:social_media_app/features/single_chats/models/chat_user_model.dart';

/// The screens a campaign push can open. Injectable so routing is unit-tested
/// without a Navigator or Supabase.
abstract class CampaignDestinations {
  Future<void> openPost(String postId);
  Future<void> openProfile(String userId);
  Future<void> openAnnouncement(String? announcementId);
}

/// Routes a tapped campaign push to its destination. Never throws: a dead link
/// (deleted post, unknown user) must leave the user in the app, not crash it.
class CampaignPushRouter {
  CampaignPushRouter({CampaignDestinations? destinations})
    : _destinations = destinations ?? const AppCampaignDestinations();

  static final CampaignPushRouter instance = CampaignPushRouter();

  final CampaignDestinations _destinations;

  /// FCM `data` map (notification opened from the system tray / cold start).
  Future<void> openFromData(Map<String, dynamic> data) =>
      open(CampaignPushPayload.fromData(data));

  /// Local-notification payload string (`campaign|route|target|id`).
  Future<void> openFromLocalPayload(String? payload) async {
    final parsed = CampaignPushPayload.fromLocalPayload(payload);
    if (parsed != null) await open(parsed);
  }

  Future<void> open(CampaignPushPayload payload) async {
    try {
      switch (payload.route) {
        case CampaignRoute.post:
          await _destinations.openPost(payload.targetId!);
        case CampaignRoute.profile:
          await _destinations.openProfile(payload.targetId!);
        case CampaignRoute.announcement:
          await _destinations.openAnnouncement(payload.targetId);
        case CampaignRoute.none:
          // Plain campaign: the app is already open on its home screen.
          break;
      }
    } catch (e, s) {
      debugPrint('[CampaignPushRouter] failed to open $payload: $e\n$s');
    }
  }
}

/// Production destinations.
///
/// There is no dedicated announcements screen in the app yet, so an
/// `announcement` push opens the in-app Notifications screen (where campaign
/// pushes are listed). Swap [openAnnouncement] when a real screen exists.
class AppCampaignDestinations implements CampaignDestinations {
  const AppCampaignDestinations();

  @override
  Future<void> openPost(String postId) =>
      ContentDeepLinkNavigator.openPost(postId);

  @override
  Future<void> openProfile(String userId) async {
    final row =
        await SupabaseProvider.client
            .from(SupabaseConstants.users)
            .select(
              '${UserColumns.id}, ${UserColumns.name}, ${UserColumns.imageUrl}',
            )
            .eq(UserColumns.id, userId)
            .maybeSingle();
    if (row == null) return; // deleted / unknown user: stay where we are

    final user = ChatUserModel(
      id: userId,
      name: (row[UserColumns.name] ?? '').toString(),
      imageUrl: row[UserColumns.imageUrl] as String?,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.pushNamed(
        AppRoutes.receiverProfileViewRoute,
        arguments: user,
      );
    });
  }

  @override
  Future<void> openAnnouncement(String? announcementId) async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const NotificationsView()),
      );
    });
  }
}
