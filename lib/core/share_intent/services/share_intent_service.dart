import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../../../features/auth/services/auth_link_handler.dart';
import '../../deep_link/services/incoming_link_classifier.dart';
import '../../notifications/notification_navigator_key.dart';
import '../../router/app_routes.dart';
import '../../session/session_guard.dart';
import '../models/incoming_share_payload.dart';

class ShareIntentService {
  ShareIntentService._();
  static final ShareIntentService instance = ShareIntentService._();

  StreamSubscription<List<SharedMediaFile>>? _mediaSub;
  final _payloadController = StreamController<IncomingSharePayload>.broadcast();
  Stream<IncomingSharePayload> get payloadStream => _payloadController.stream;

  bool _initialized = false;
  IncomingSharePayload? _pendingColdStartPayload;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    _mediaSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      _handleIncoming, // warm start: app already settled, safe to route immediately
      onError: (e, s) => debugPrint('⚠️ ShareIntentService stream error: $e'),
    );
  }

  bool _isAppDeepLink(IncomingSharePayload payload) {
    if (AuthLinkHandler.instance.isBusy) return true;
    if (payload.kind != IncomingShareKind.text) return false;
    final text = payload.text?.trim() ?? '';
    if (text.isEmpty) return false;
    return IncomingLinkClassifier.classify(text) != IncomingLinkKind.other;
  }

  void _handleIncoming(List<SharedMediaFile> raw) {
    final payload = IncomingSharePayload.fromSharedFiles(raw);
    if (payload == null) return;
    if (_isAppDeepLink(payload)) {
      ReceiveSharingIntent.instance.reset();
      return;
    }
    _payloadController.add(payload);
    _routeSafely(payload);
  }

  Future<void> _routeSafely(IncomingSharePayload payload) async {
    if (!SessionGuard.isFullySignedIn) {
      debugPrint('ℹ️ ShareIntentService: no usable session, share dropped.');
      return;
    }
    try {
      final nav = navigatorKey.currentState;
      if (nav == null) return;

      nav.pushNamed(AppRoutes.incomingShareTargetViewRoute, arguments: payload);
    } catch (e) {
      debugPrint('⚠️ ShareIntentService routing failed: $e');
    }
  }

  Future<void> consumeInitialShareIfAny() async {
    try {
      final initial = await ReceiveSharingIntent.instance.getInitialMedia();
      if (initial.isNotEmpty) {
        final payload = IncomingSharePayload.fromSharedFiles(initial);
        if (payload != null && !_isAppDeepLink(payload)) {
          _pendingColdStartPayload = payload;
        }
      }
    } catch (e) {
      debugPrint('⚠️ ShareIntentService initial media error: $e');
    } finally {
      ReceiveSharingIntent.instance.reset();
    }
  }

  void flushPendingColdStartShareIfAny() {
    final payload = _pendingColdStartPayload;
    _pendingColdStartPayload = null;
    if (payload != null) _routeSafely(payload);
  }

  void discardPendingColdStartShare() {
    _pendingColdStartPayload = null;
  }

  Future<void> dispose() async {
    await _mediaSub?.cancel();
    await _payloadController.close();
    _initialized = false;
  }
}
