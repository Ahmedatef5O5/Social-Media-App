import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../../router/app_routes.dart';
import '../../services/notification_services.dart' show navigatorKey;
import '../models/incoming_share_payload.dart';

class ShareIntentService {
  ShareIntentService._();
  static final ShareIntentService instance = ShareIntentService._();

  StreamSubscription<List<SharedMediaFile>>? _mediaSub;
  final _payloadController = StreamController<IncomingSharePayload>.broadcast();
  Stream<IncomingSharePayload> get payloadStream => _payloadController.stream;

  bool _initialized = false;
  bool _isShareTargetOpen = false;
  IncomingSharePayload? _pendingColdStartPayload;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    _mediaSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      _handleIncoming, // warm start: app already settled, safe to route immediately
      onError: (e, s) => debugPrint('⚠️ ShareIntentService stream error: $e'),
    );
  }

  Future<void> consumeInitialShareIfAny() async {
    try {
      final initial = await ReceiveSharingIntent.instance.getInitialMedia();
      if (initial.isNotEmpty) {
        _pendingColdStartPayload = IncomingSharePayload.fromSharedFiles(
          initial,
        );
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

  void _handleIncoming(List<SharedMediaFile> raw) {
    final payload = IncomingSharePayload.fromSharedFiles(raw);
    if (payload == null) return;
    _payloadController.add(payload);
    _routeSafely(payload);
  }

  Future<void> _routeSafely(IncomingSharePayload payload) async {
    try {
      final nav = navigatorKey.currentState;
      if (nav == null) return;

      // Avoid stacking a second share-target screen on rapid repeated shares.
      if (_isShareTargetOpen) {
        nav.popUntil(
          (route) =>
              route.settings.name != AppRoutes.incomingShareTargetViewRoute,
        );
      }

      _isShareTargetOpen = true;
      await nav.pushNamed(
        AppRoutes.incomingShareTargetViewRoute,
        arguments: payload,
      );
      _isShareTargetOpen = false;
    } catch (e) {
      debugPrint('⚠️ ShareIntentService routing failed, falling back home: $e');
      _isShareTargetOpen = false;
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.homeRoute,
        (route) => false,
      );
    }
  }

  Future<void> dispose() async {
    await _mediaSub?.cancel();
    await _payloadController.close();
    _initialized = false;
  }
}
