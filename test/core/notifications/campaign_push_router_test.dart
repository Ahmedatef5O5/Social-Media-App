import 'package:flutter_test/flutter_test.dart';
import 'package:social_media_app/core/notifications/campaign/campaign_push_payload.dart';
import 'package:social_media_app/core/notifications/campaign/campaign_push_router.dart';

const _uuid = '22222222-2222-4222-8222-222222222222';

class _FakeDestinations implements CampaignDestinations {
  final List<String> calls = [];
  Object? throwOn;

  @override
  Future<void> openPost(String postId) async {
    if (throwOn == 'post') throw StateError('post gone');
    calls.add('post:$postId');
  }

  @override
  Future<void> openProfile(String userId) async {
    if (throwOn == 'profile') throw StateError('no such user');
    calls.add('profile:$userId');
  }

  @override
  Future<void> openAnnouncement(String? announcementId) async {
    calls.add('announcement:${announcementId ?? ''}');
  }
}

void main() {
  late _FakeDestinations destinations;
  late CampaignPushRouter router;

  setUp(() {
    destinations = _FakeDestinations();
    router = CampaignPushRouter(destinations: destinations);
  });

  test('FCM data routes to a post', () async {
    await router.openFromData({
      'notificationType': 'campaign',
      'route': 'post',
      'target_id': _uuid,
    });
    expect(destinations.calls, ['post:$_uuid']);
  });

  test('FCM data routes to a profile', () async {
    await router.openFromData({'route': 'profile', 'target_id': _uuid});
    expect(destinations.calls, ['profile:$_uuid']);
  });

  test('announcement routes with and without an id', () async {
    await router.openFromData({'route': 'announcement'});
    await router.openFromData({'route': 'announcement', 'target_id': 'a1'});
    expect(destinations.calls, ['announcement:', 'announcement:a1']);
  });

  test('a plain campaign opens nothing extra', () async {
    await router.openFromData({'notificationType': 'campaign'});
    expect(destinations.calls, isEmpty);
  });

  test('a malformed link degrades to a no-op instead of a bad navigation', () async {
    await router.openFromData({'route': 'post', 'target_id': 'oops'});
    expect(destinations.calls, isEmpty);
  });

  test('local notification payloads route the same way', () async {
    const payload = CampaignPushPayload(
      campaignId: 'c1',
      route: CampaignRoute.post,
      targetId: _uuid,
    );
    await router.openFromLocalPayload(payload.toLocalPayload());
    expect(destinations.calls, ['post:$_uuid']);

    await router.openFromLocalPayload('social|follow|1'); // not ours
    await router.openFromLocalPayload(null);
    expect(destinations.calls, hasLength(1));
  });

  test('a destination that throws never propagates', () async {
    destinations.throwOn = 'post';
    await expectLater(
      router.openFromData({'route': 'post', 'target_id': _uuid}),
      completes,
    );
    destinations.throwOn = 'profile';
    await expectLater(
      router.openFromData({'route': 'profile', 'target_id': _uuid}),
      completes,
    );
  });
}
