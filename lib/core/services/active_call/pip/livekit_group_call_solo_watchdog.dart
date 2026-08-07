import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';

class LiveKitGroupCallSoloWatchdog {
  EventsListener<RoomEvent>? _listener;
  Timer? _graceTimer;
  bool _callHasStarted = false;
  bool _hasTriggered = false;

  void start({
    required Room room,
    required VoidCallback onSoloTimeout,
    Duration grace = const Duration(seconds: 3),
  }) {
    stop();
    _hasTriggered = false;

    _evaluate(room.remoteParticipants.length, onSoloTimeout, grace);

    _listener = room.createListener();
    _listener!
      ..on<ParticipantConnectedEvent>(
        (_) => _evaluate(room.remoteParticipants.length, onSoloTimeout, grace),
      )
      ..on<ParticipantDisconnectedEvent>(
        (_) => _evaluate(room.remoteParticipants.length, onSoloTimeout, grace),
      );
  }

  void _evaluate(int remoteCount, VoidCallback onSoloTimeout, Duration grace) {
    if (_hasTriggered) return;

    final total = remoteCount + 1;

    if (total >= 2) {
      _callHasStarted = true;
      _graceTimer?.cancel();
      _graceTimer = null;
      return;
    }

    if (_callHasStarted && total < 2) {
      _graceTimer ??= Timer(grace, () {
        _hasTriggered = true;
        onSoloTimeout();
      });
    }
  }

  void stop() {
    _listener?.dispose();
    _listener = null;
    _graceTimer?.cancel();
    _graceTimer = null;
    _callHasStarted = false;
  }
}
