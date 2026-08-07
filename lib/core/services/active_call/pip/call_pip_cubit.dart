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

  void attach({
    required Room room,
    required bool isVideo,
    bool isGroup = false,
    VoidCallback? onSoloTimeout,
  }) {
    _soloWatchdog.stop();
    final previous = state.room;
    if (previous != null && previous != room) {
      unawaited(previous.disconnect());
    }
    emit(CallPipState(room: room, isMinimized: false, isVideo: isVideo));

    if (isGroup && onSoloTimeout != null) {
      _soloWatchdog.start(room: room, onSoloTimeout: onSoloTimeout);
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

    final room = state.room;
    if (room != null) {
      try {
        await room.disconnect();
      } catch (e) {
        debugPrint('[CallPipCubit] room.disconnect failed: $e');
      }
    }

    if (state.room != null || state.isMinimized) {
      emit(const CallPipState());
    }
  }

  bool get hasActiveRoom => state.room != null;

  @override
  Future<void> close() {
    _soloWatchdog.stop();
    state.room?.disconnect();
    return super.close();
  }
}
