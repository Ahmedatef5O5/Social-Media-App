import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import '../../../features/group_chats/widgets/group_invite_bottom_sheet.dart';
import '../../helpers/content_deep_link_navigator.dart';
import '../../services/notification_services.dart';
import '../../supabase/supabase_provider.dart';

class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  static const String host = 'social-media-app-98f58.web.app';
  static const Set<String> _expectedHosts = {host};

  bool get hasPendingColdStartDeepLink => _pendingColdStartUri != null;

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;

  bool _initialized = false;
  Uri? _pendingColdStartUri;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    _linkSub = _appLinks.uriLinkStream.listen(
      _handleWarmLink, // warm start: app already settled, safe to route immediately
      onError: (e, s) => debugPrint('⚠️ DeepLinkService stream error: $e'),
    );
  }

  Future<void> consumeInitialDeepLinkIfAny() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null && _isOwnHost(initial)) {
        _pendingColdStartUri = initial;
      }
    } catch (e) {
      debugPrint('⚠️ DeepLinkService initial link error: $e');
    }
  }

  void flushPendingColdStartDeepLinkIfAny() {
    final uri = _pendingColdStartUri;
    _pendingColdStartUri = null;
    if (uri != null) _route(uri);
  }

  void discardPendingColdStartDeepLink() {
    _pendingColdStartUri = null;
  }

  void _handleWarmLink(Uri uri) {
    if (!_isOwnHost(uri)) return;

    // A warm-start link firing before any session exists is an edge case
    // (app backgrounded pre-login) rather than the common path — cold
    // start already waits for SplashView to resolve the session first.
    if (SupabaseProvider.currentSession == null) {
      debugPrint(
        '⚠️ DeepLinkService: link received with no active session, ignoring.',
      );
      return;
    }

    _route(uri);
  }

  bool _isOwnHost(Uri uri) => _expectedHosts.contains(uri.host);

  void _route(Uri uri) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length < 2) return;

    final type = segments[0];
    final id = segments[1];
    if (id.isEmpty) return;

    switch (type) {
      case 'post':
        ContentDeepLinkNavigator.openPost(id);
        break;
      case 'story':
        ContentDeepLinkNavigator.openStoryById(id);
        break;
      case 'join':
        final context = navigatorKey.currentContext;
        if (context != null && context.mounted) {
          GroupInviteBottomSheet.show(context, id);
        }
        break;
      default:
        debugPrint('⚠️ DeepLinkService: unknown deep link type "$type"');
    }
  }

  Future<void> dispose() async {
    await _linkSub?.cancel();
    _initialized = false;
  }
}
