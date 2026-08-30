import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livekit_client/livekit_client.dart';
import '../../../core/services/active_call/call_termination_service.dart';
import '../../../core/services/active_call/cubit/active_call_session_cubit.dart';
import '../../../core/services/active_call/pip/call_pip_cubit.dart';
import '../../../core/services/livekit_token_service.dart';
import '../../../core/widgets/calls/call_avatar_backdrop.dart';
import '../../../core/widgets/calls/call_control_button.dart';
import '../../../core/widgets/calls/call_layout_metrics.dart';
import '../../../core/widgets/calls/calls.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../models/call_model.dart';
import '../cubits/single_call_cubit/call_cubit.dart';

class LiveKitCallView extends StatefulWidget {
  final CallModel call;
  final String currentUserId;
  final String currentUserName;

  const LiveKitCallView({
    super.key,
    required this.call,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  State<LiveKitCallView> createState() => _LiveKitCallViewState();
}

class _LiveKitCallViewState extends State<LiveKitCallView> {
  Room? _room;
  EventsListener<RoomEvent>? _listener;

  bool get _isVideo => widget.call.type == CallType.video;

  bool _connecting = true;
  String? _loadError;
  bool _isEnding = false;

  bool _micEnabled = true;
  bool _cameraEnabled = true;
  bool _isFrontCamera = true;

  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  late DateTime _startedAt;

  @override
  void initState() {
    super.initState();
    _startedAt = widget.call.startTime ?? DateTime.now();
    _startTicker();
    _initRoom();
  }

  void _startTicker() {
    _refreshElapsed();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _refreshElapsed(),
    );
  }

  void _refreshElapsed() {
    if (!mounted) return;
    final diff = DateTime.now().difference(_startedAt);
    setState(() => _elapsed = diff.isNegative ? Duration.zero : diff);
  }

  Future<void> _initRoom() async {
    final pip = context.read<CallPipCubit>();
    final activeSession = context.read<ActiveCallSessionCubit>().state;
    final existingRoom = pip.state.room;

    if (existingRoom != null && activeSession?.callId == widget.call.callId) {
      _startedAt = activeSession!.startedAt;
      _refreshElapsed();
      _attachTo(existingRoom, alreadyConnected: true);
      return;
    }

    await _connectNewRoom();
  }

  Future<void> _connectNewRoom() async {
    try {
      final connection = await LiveKitTokenService.instance.generateToken(
        roomName: widget.call.callId,
        participantName: widget.currentUserName,
      );

      final room = Room();
      await room.connect(
        connection.url,
        connection.token,
        roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true),
      );

      await room.localParticipant?.setMicrophoneEnabled(true);
      if (_isVideo) {
        await room.localParticipant?.setCameraEnabled(true);
      }

      if (!mounted) {
        await room.disconnect();
        return;
      }

      final isCaller = widget.currentUserId == widget.call.callerId;
      context.read<ActiveCallSessionCubit>().startSingleCallSession(
        callId: widget.call.callId,
        title: isCaller ? widget.call.receiverName : widget.call.callerName,
        avatarUrl:
            isCaller ? widget.call.receiverAvatar : widget.call.callerAvatar,
        isVideo: _isVideo,
        startedAt: _startedAt,
        call: widget.call,
        currentUserId: widget.currentUserId,
        currentUserName: widget.currentUserName,
      );

      context.read<CallPipCubit>().attach(room: room, isVideo: _isVideo);

      _attachTo(room, alreadyConnected: false);
    } catch (e, st) {
      debugPrint('❌ LiveKitCallView._connectNewRoom failed: $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) return;

      try {
        await context.read<CallCubit>().endCall(widget.call.callId);
      } catch (_) {
        // Best-effort — the connection already failed; don't let a
        // secondary signaling error mask the real one.
      }

      if (!mounted) return;

      context.read<ActiveCallSessionCubit>().endSession();
      setState(() {
        _loadError = e.toString();
        _connecting = false;
      });
    }
  }

  void _attachTo(Room room, {required bool alreadyConnected}) {
    _room = room;
    _listener = room.createListener();
    _listener!
      ..on<TrackSubscribedEvent>((_) => _onTracksChanged())
      ..on<TrackUnsubscribedEvent>((_) => _onTracksChanged())
      ..on<TrackMutedEvent>((_) => _onTracksChanged())
      ..on<TrackUnmutedEvent>((_) => _onTracksChanged())
      ..on<ParticipantDisconnectedEvent>((_) => _onRemoteParticipantLeft())
      ..on<RoomDisconnectedEvent>((_) => _onRoomDisconnected());

    if (alreadyConnected) {
      final audioPubs =
          room.localParticipant?.audioTrackPublications ?? const [];
      final videoPubs =
          room.localParticipant?.videoTrackPublications ?? const [];
      _micEnabled = audioPubs.isEmpty || !audioPubs.first.muted;
      _cameraEnabled = videoPubs.isNotEmpty && !videoPubs.first.muted;
    }

    _pushPreviewTrack();
    if (mounted) setState(() => _connecting = false);
  }

  void _onTracksChanged() {
    _pushPreviewTrack();
    if (mounted) setState(() {});
  }

  void _onRemoteParticipantLeft() {
    final room = _room;
    if (room == null || !mounted || _isEnding) return;
    if (room.remoteParticipants.isEmpty) {
      _handleEndCall();
    }
  }

  void _onRoomDisconnected() {
    if (!mounted || _isEnding) return;
    _handleEndCall();
  }

  void _pushPreviewTrack() {
    final room = _room;
    if (room == null) return;
    context.read<CallPipCubit>().updatePreviewTrack(_resolveMainTrack(room));
  }

  VideoTrack? _resolveMainTrack(Room room) {
    final remote = _resolveRemoteTrack(room);
    if (remote != null) return remote;
    for (final pub
        in room.localParticipant?.videoTrackPublications ?? const []) {
      if (!pub.muted && pub.track != null) return pub.track as VideoTrack;
    }
    return null;
  }

  VideoTrack? _resolveRemoteTrack(Room room) {
    for (final participant in room.remoteParticipants.values) {
      for (final pub in participant.videoTrackPublications) {
        if (pub.subscribed && !pub.muted && pub.track != null) {
          return pub.track as VideoTrack;
        }
      }
    }
    return null;
  }

  Future<void> _toggleMic() async {
    final room = _room;
    if (room == null) return;
    final next = !_micEnabled;
    await room.localParticipant?.setMicrophoneEnabled(next);
    if (mounted) setState(() => _micEnabled = next);
  }

  Future<void> _toggleCamera() async {
    final room = _room;
    if (room == null) return;
    final next = !_cameraEnabled;
    await room.localParticipant?.setCameraEnabled(next);
    if (mounted) setState(() => _cameraEnabled = next);
    _pushPreviewTrack();
  }

  bool _isSwitchingCamera = false;

  Future<void> _switchCamera() async {
    if (_isSwitchingCamera) return;
    final room = _room;
    if (room == null) return;

    LocalVideoTrack? localVideoTrack;
    for (final pub
        in room.localParticipant?.videoTrackPublications ?? const []) {
      if (pub.track is LocalVideoTrack) {
        localVideoTrack = pub.track as LocalVideoTrack;
        break;
      }
    }
    if (localVideoTrack == null) return;

    _isSwitchingCamera = true;
    final nextPosition =
        _isFrontCamera ? CameraPosition.back : CameraPosition.front;

    try {
      await localVideoTrack.setCameraPosition(nextPosition);
      if (mounted) setState(() => _isFrontCamera = !_isFrontCamera);
    } catch (e) {
      debugPrint('[CallView] _switchCamera failed: $e');
    } finally {
      _isSwitchingCamera = false;
    }
  }

  void _handleMinimize() => Navigator.of(context).pop();

  Future<void> _handleEndCall() async {
    if (_isEnding) return;
    setState(() => _isEnding = true);

    await CallTerminationService.endActiveCall(
      pipCubit: context.read<CallPipCubit>(),
      sessionCubit: context.read<ActiveCallSessionCubit>(),

      signalEnd: () => context.read<CallCubit>().endCall(widget.call.callId),
    );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _listener?.dispose();
    super.dispose();
  }

  String get _durationText {
    final h = _elapsed.inHours;
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                const Text('The call could not be initiated.'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_connecting || _room == null) {
      return const Scaffold(body: Center(child: CustomLoadingIndicator()));
    }

    final primary = Theme.of(context).primaryColor;
    final remoteTrack = _resolveRemoteTrack(_room!);
    final isCaller = widget.currentUserId == widget.call.callerId;
    final otherPersonName =
        isCaller ? widget.call.receiverName : widget.call.callerName;
    final otherPersonAvatar =
        isCaller ? widget.call.receiverAvatar : widget.call.callerAvatar;
    final showRemoteVideo = _isVideo && remoteTrack != null;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) context.read<CallPipCubit>().minimize();
      },
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final metrics = CallLayoutMetrics.of(
              constraints,
              reservedHeight: 0,
            );
            final avatarDiameter = metrics.avatarDiameter.clamp(110.0, 150.0);

            return Stack(
              children: [
                if (showRemoteVideo)
                  Positioned.fill(child: VideoTrackRenderer(remoteTrack))
                else ...[
                  CallAvatarBackdrop(
                    avatarUrl: otherPersonAvatar,
                    baseColor: primary,
                  ),
                  CallAmbientBackground(
                    style: CallAmbientStyle.orbit,
                    isVideo: _isVideo,
                  ),
                  Center(
                    child: CallAvatarImage(
                      imageUrl: otherPersonAvatar,
                      fallbackLabel: otherPersonName,
                      diameter: avatarDiameter,
                    ),
                  ),
                ],

                if (showRemoteVideo)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.35),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.45),
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),
                  ),

                SafeArea(
                  child: Column(
                    children: [
                      _buildTopBar(otherPersonName),
                      const Spacer(),
                      if (_isVideo) _buildLocalPreview(metrics.isCompact),
                      SizedBox(height: metrics.midGap),
                      _buildControls(metrics.buttonSize),
                      SizedBox(height: metrics.bottomGap),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar(String otherPersonName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withValues(alpha: 0.12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _handleMinimize,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white,
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        otherPersonName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      CallStatusPill(
                        icon: Icons.circle,
                        label: _durationText,
                        showLiveDot: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 44),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocalPreview(bool isCompact) {
    final room = _room;
    if (room == null || !_cameraEnabled) return const SizedBox.shrink();

    LocalVideoTrack? localTrack;
    for (final pub
        in room.localParticipant?.videoTrackPublications ?? const []) {
      if (pub.track is LocalVideoTrack) {
        localTrack = pub.track as LocalVideoTrack;
        break;
      }
    }
    if (localTrack == null) return const SizedBox.shrink();

    final width = isCompact ? 78.0 : 96.0;
    final height = isCompact ? 104.0 : 128.0;

    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: width,
            height: height,
            child: VideoTrackRenderer(localTrack),
          ),
        ),
      ),
    );
  }

  Widget _buildControls(double buttonSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        CallControlButton(
          icon: _micEnabled ? Icons.mic_rounded : Icons.mic_off_rounded,
          label: _micEnabled ? 'Mute' : 'Unmute',
          variant:
              _micEnabled
                  ? CallControlVariant.neutral
                  : CallControlVariant.warning,
          size: buttonSize,
          onTap: _toggleMic,
        ),
        if (_isVideo)
          CallControlButton(
            icon:
                _cameraEnabled
                    ? Icons.videocam_rounded
                    : Icons.videocam_off_rounded,
            label: _cameraEnabled ? 'Camera' : 'Off',
            variant:
                _cameraEnabled
                    ? CallControlVariant.neutral
                    : CallControlVariant.warning,
            size: buttonSize,
            onTap: _toggleCamera,
          ),
        if (_isVideo)
          CallControlButton(
            icon: Icons.cameraswitch_rounded,
            label: 'Flip',
            size: buttonSize,
            onTap: _switchCamera,
          ),
        CallControlButton(
          icon: Icons.call_end_rounded,
          label: 'End',
          variant: CallControlVariant.dangerSolid,
          size: buttonSize,
          emphasized: true,
          onTap: _handleEndCall,
        ),
      ],
    );
  }
}
