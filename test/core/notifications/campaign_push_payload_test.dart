import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_media_app/core/notifications/campaign/campaign_push_payload.dart';

const _uuid = '11111111-1111-4111-8111-111111111111';

void main() {
  group('CampaignPushPayload.fromData', () {
    test('recognises campaign pushes only', () {
      expect(
        CampaignPushPayload.isCampaign({'notificationType': 'campaign'}),
        isTrue,
      );
      expect(
        CampaignPushPayload.isCampaign({'notificationType': 'chat'}),
        isFalse,
      );
      expect(CampaignPushPayload.isCampaign({}), isFalse);
    });

    test('post and profile need a UUID target', () {
      final post = CampaignPushPayload.fromData({
        'route': 'post',
        'target_id': _uuid,
        'campaign_id': 'c1',
      });
      expect(post.route, CampaignRoute.post);
      expect(post.targetId, _uuid);
      expect(post.campaignId, 'c1');

      expect(
        CampaignPushPayload.fromData({'route': 'profile', 'target_id': _uuid})
            .route,
        CampaignRoute.profile,
      );
    });

    test('a malformed or missing target degrades to opening the app', () {
      for (final data in [
        {'route': 'post'},
        {'route': 'post', 'target_id': 'not-a-uuid'},
        {'route': 'profile', 'target_id': '  '},
      ]) {
        final p = CampaignPushPayload.fromData(data);
        expect(p.route, CampaignRoute.none, reason: '$data');
        expect(p.targetId, isNull);
      }
    });

    test('announcement works with or without an id', () {
      expect(
        CampaignPushPayload.fromData({'route': 'announcement'}).route,
        CampaignRoute.announcement,
      );
      final withId = CampaignPushPayload.fromData({
        'route': 'announcement',
        'target_id': 'voice-rooms',
      });
      expect(withId.targetId, 'voice-rooms');
    });

    test('unknown routes and non-string values never throw', () {
      expect(
        CampaignPushPayload.fromData({'route': 'settings'}).route,
        CampaignRoute.none,
      );
      expect(
        CampaignPushPayload.fromData({'route': 5, 'target_id': 7}).route,
        CampaignRoute.none,
      );
      expect(CampaignPushPayload.fromData({}).campaignId, isNull);
    });
  });

  group('local payload round trip', () {
    test('survives encode/decode', () {
      const original = CampaignPushPayload(
        campaignId: 'c1',
        route: CampaignRoute.post,
        targetId: _uuid,
      );
      final decoded = CampaignPushPayload.fromLocalPayload(
        original.toLocalPayload(),
      );
      expect(decoded, original);
    });

    test('plain campaign', () {
      const original = CampaignPushPayload(campaignId: 'c9');
      expect(original.toLocalPayload(), 'campaign|none||c9');
      expect(CampaignPushPayload.fromLocalPayload(original.toLocalPayload()),
          original);
    });

    test('rejects other payload families and re-validates targets', () {
      expect(CampaignPushPayload.isLocalPayload('social|follow|1'), isFalse);
      expect(CampaignPushPayload.fromLocalPayload('social|follow|1'), isNull);
      expect(CampaignPushPayload.fromLocalPayload(null), isNull);
      // A tampered payload cannot smuggle a non-UUID into the post route.
      final tampered = CampaignPushPayload.fromLocalPayload(
        'campaign|post|../../etc|c1',
      );
      expect(tampered!.route, CampaignRoute.none);
    });
  });

  group('currentPushPlatform', () {
    test('maps mobile platforms only', () {
      expect(currentPushPlatform(TargetPlatform.android), 'android');
      expect(currentPushPlatform(TargetPlatform.iOS), 'ios');
      expect(currentPushPlatform(TargetPlatform.macOS), isNull);
      expect(currentPushPlatform(TargetPlatform.windows), isNull);
    });
  });
}
