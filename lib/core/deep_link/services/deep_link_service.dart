import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../features/group_chats/widgets/group_invite_bottom_sheet.dart';
import '../../helpers/content_deep_link_navigator.dart';
import '../../notifications/notification_navigator_key.dart';
import '../../secrets/app_secrets.dart';
import '../../supabase/supabase_provider.dart';

class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  static const String host = 'social-media-app-98f58.web.app';
  static const Set<String> _expectedHosts = {host};
  bool _isOwnHost(Uri uri) => _expectedHosts.contains(uri.host);

  static String get _shareFunctionBase =>
      '${AppSecrets.supabaseUrl}/functions/v1/share';

  static String get shareFunctionHost => Uri.parse(AppSecrets.supabaseUrl).host;

  static String urlForPost(String postId) => '$_shareFunctionBase/post/$postId';
  static String urlForStory(String storyId) =>
      '$_shareFunctionBase/story/$storyId';
  static String urlForGroupInvite(String inviteHash) =>
      '$_shareFunctionBase/join/$inviteHash';

  static const _lastConsumedInitialLinkKey = 'deep_link_last_consumed_initial';

  static (String type, String id)? parseInternalLink(Uri? uri) {
    if (uri == null) return null;

    if (uri.host == host) {
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      return segments.length >= 2 ? (segments[0], segments[1]) : null;
    }

    if (uri.host == shareFunctionHost) {
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      final shareIndex = segments.indexOf('share');
      final rest =
          shareIndex == -1 ? segments : segments.sublist(shareIndex + 1);
      return rest.length >= 2 ? (rest[0], rest[1]) : null;
    }

    return null;
  }

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;

  bool _initialized = false;
  bool _isAppReady = false;
  Uri? _pendingUri;

  // True only while _pendingUri came from getInitialLink() (cold start).
  // Stream-delivered (warm) links must NEVER be written to the "last
  // consumed" record below — otherwise tapping the exact same link
  // twice (once warm, once from a later genuine cold start) would have
  // that second, perfectly legitimate tap silently swallowed too.
  bool _pendingIsFromColdStart = false;

  int _retryCount = 0;
  static const int _maxRetries = 3;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    _linkSub = _appLinks.uriLinkStream.listen(
      _handleLink,
      onError: (e, s) => debugPrint('⚠️ DeepLinkService stream error: $e'),
    );

    // Cold start: the link (if any) that actually launched this Activity.
    // On a Flutter Hot Restart, the native Activity/Intent isn't
    // recreated, so this keeps returning the SAME link every restart —
    // expected framework behavior, not a bug (a real user never
    // hot-restarts). _resolvePendingUri records every cold-start link it
    // finishes handling — success OR drop, for ANY reason — so a repeat
    // delivery of the identical link on the next hot restart is
    // recognized and skipped.
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null && _isOwnHost(initial)) {
        final prefs = await SharedPreferences.getInstance();
        final lastConsumed = prefs.getString(_lastConsumedInitialLinkKey);
        if (lastConsumed != initial.toString()) {
          _pendingUri = initial;
          _pendingIsFromColdStart = true;
        }
      }
    } catch (e) {
      debugPrint('⚠️ DeepLinkService initial link error: $e');
    }
  }

  void markAppReady() {
    _isAppReady = true;
    _processPendingLink();
  }

  void discardPendingLink() => _resolvePendingUri();

  void _handleLink(Uri uri) {
    if (!_isOwnHost(uri)) return;
    _pendingUri = uri; // Latest wins
    _pendingIsFromColdStart = false;
    _processPendingLink();
  }

  void _processPendingLink() {
    final uri = _pendingUri;
    if (uri == null) return;

    if (SupabaseProvider.currentSession == null) {
      debugPrint('⚠️ DeepLinkService: No active session, dropping link: $uri');
      _resolvePendingUri();
      return;
    }

    if (!_isAppReady) {
      debugPrint(
        'ℹ️ DeepLinkService: App not ready (e.g. Splash), keeping link buffered.',
      );
      return;
    }

    final nav = navigatorKey.currentState;
    if (nav == null) {
      if (_retryCount < _maxRetries) {
        _retryCount++;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _processPendingLink(),
        );
      } else {
        debugPrint(
          '⚠️ DeepLinkService: Navigator unavailable after $_maxRetries retries. Dropping link.',
        );
        _resolvePendingUri();
      }
      return;
    }

    _retryCount = 0;
    _consumeAndRoute(uri, nav);
  }

  void _consumeAndRoute(Uri uri, NavigatorState nav) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length < 2) {
      _resolvePendingUri();
      return;
    }

    final type = segments[0];
    final id = segments[1];
    if (id.isEmpty) {
      _resolvePendingUri();
      return;
    }

    switch (type) {
      case 'post':
        ContentDeepLinkNavigator.openPost(id);
        break;
      case 'story':
        ContentDeepLinkNavigator.openStoryById(id);
        break;
      case 'join':
        GroupInviteBottomSheet.show(nav.context, id);
        break;
      default:
        debugPrint('⚠️ DeepLinkService: unknown deep link type "$type"');
    }

    _resolvePendingUri(sourceUri: uri);
  }

  /// Clears the pending link and, if (and only if) it came from
  /// getInitialLink() (cold start), records it so a repeat delivery of
  /// the identical link on the next hot restart is skipped — covers
  /// every exit path (successful route, no session, malformed link,
  /// navigator unavailable) with one call, not one per branch.
  void _resolvePendingUri({Uri? sourceUri}) {
    final uri = sourceUri ?? _pendingUri;
    final wasFromColdStart = _pendingIsFromColdStart;

    _pendingUri = null;
    _pendingIsFromColdStart = false;
    _retryCount = 0;

    if (wasFromColdStart && uri != null) {
      unawaited(_rememberConsumedInitialLink(uri));
    }
  }

  Future<void> _rememberConsumedInitialLink(Uri uri) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastConsumedInitialLinkKey, uri.toString());
  }

  Future<void> dispose() async {
    await _linkSub?.cancel();
    _initialized = false;
    _isAppReady = false;
    _pendingUri = null;
    _pendingIsFromColdStart = false;
    _retryCount = 0;
  }
}
