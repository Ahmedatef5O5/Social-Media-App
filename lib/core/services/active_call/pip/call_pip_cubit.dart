import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livekit_client/livekit_client.dart';
import 'call_pip_state.dart';
import 'livekit_group_call_solo_watchdog.dart';

/// App-wide (registered once in `app.dart`, never disposed) owner of the
/// live LiveKit [Room] connection for whichever call is currently active,
/// plus the single source of truth for "is the call minimized right now".

class CallPipCubit extends Cubit<CallPipState> {
  CallPipCubit() : super(const CallPipState());

  final LiveKitGroupCallSoloWatchdog _soloWatchdog =
      LiveKitGroupCallSoloWatchdog();

  Timer? _heartbeatTimer;

  void attach({
    required Room room,
    required bool isVideo,
    bool isGroup = false,
    VoidCallback? onSoloTimeout,
    Future<void> Function()? onHeartbeat,
    Duration heartbeatInterval = const Duration(seconds: 15),
  }) {
    _soloWatchdog.stop();
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    final previous = state.room;
    if (previous != null && previous != room) {
      unawaited(_disconnectAndDispose(previous));
    }
    emit(CallPipState(room: room, isMinimized: false, isVideo: isVideo));

    if (isGroup && onSoloTimeout != null) {
      _soloWatchdog.start(room: room, onSoloTimeout: onSoloTimeout);
    }

    if (isGroup && onHeartbeat != null) {
      unawaited(onHeartbeat());
      _heartbeatTimer = Timer.periodic(
        heartbeatInterval,
        (_) => unawaited(onHeartbeat()),
      );
    }
  }

  void updatePreviewTrack(VideoTrack? track) {
    if (state.room == null) return;
    emit(state.copyWith(previewTrack: track, clearPreviewTrack: track == null));
  }

  void minimize() {
    if (state.room == null) return;
    emit(state.copyWith(isMinimized: true));
  }

  void restore() {
    if (state.room == null) return;
    emit(state.copyWith(isMinimized: false));
  }

  Future<void> reset() async {
    _soloWatchdog.stop();
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    final room = state.room;
    if (room != null) {
      await _disconnectAndDispose(room);
    }

    if (state.room != null || state.isMinimized) {
      emit(const CallPipState());
    }
  }

  Future<void> _disconnectAndDispose(Room room) async {
    try {
      await room.disconnect();
    } catch (e) {
      debugPrint('[CallPipCubit] room.disconnect failed: $e');
    }
    try {
      if (!room.isDisposed) {
        await room.dispose();
      }
    } catch (e) {
      debugPrint('[CallPipCubit] room.dispose failed: $e');
    }
  }

  bool get hasActiveRoom => state.room != null;

  @override
  Future<void> close() {
    _soloWatchdog.stop();
    _heartbeatTimer?.cancel();
    final room = state.room;
    if (room != null) {
      unawaited(_disconnectAndDispose(room));
    }
    return super.close();
  }
}
