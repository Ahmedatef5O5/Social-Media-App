import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:livekit_client/livekit_client.dart';
import '../../../core/services/active_call/call_termination_service.dart';
import '../../../core/services/active_call/cubit/active_call_session_cubit.dart';
import '../../../core/services/active_call/pip/call_pip_cubit.dart';
import '../../../core/services/call_foreground_task_handler.dart';
import '../../../core/services/livekit_token_service.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/widgets/calls/call_control_button.dart';
import '../../../core/widgets/calls/call_layout_metrics.dart';
import '../../../core/widgets/calls/calls.dart';
import '../../../core/widgets/calls/call_avatar_backdrop.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../models/group_call_model.dart';
import '../services/group_call_signaling_service.dart';
import '../widgets/group_call_members_sheet.dart';

class LiveKitGroupCallView extends StatefulWidget {
  final GroupCallModel call;
  final String currentUserId;
  final String currentUserName;

  const LiveKitGroupCallView({
    super.key,
    required this.call,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  State<LiveKitGroupCallView> createState() => _LiveKitGroupCallViewState();
}

class _LiveKitGroupCallViewState extends State<LiveKitGroupCallView> {
  late final GroupCallSignalingService _signaling;
  late final CallPipCubit _pipCubit;
  late final ActiveCallSessionCubit _sessionCubit;
  Room? _room;
  EventsListener<RoomEvent>? _listener;

  bool get _isVideo => widget.call.type == GroupCallType.video;

  bool _connecting = true;
  String? _loadError;
  bool _isEnding = false;

  bool _micEnabled = true;
  bool _cameraEnabled = true;
  bool _isFrontCamera = true;

  final List<String> _participantIds = [];
  final Set<String> _leavingIds = {};
  Set<String> _activeSpeakerIds = {};
  Map<String, Participant> _participantsByIdentity = {};
  final Map<String, Future<String?>> _avatarCache = {};

  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  late DateTime _startedAt;
  StreamSubscription? _activeCallSub;

  @override
  void initState() {
    super.initState();
    _signaling = context.read<GroupCallSignalingService>();
    _pipCubit = context.read<CallPipCubit>();
    _sessionCubit = context.read<ActiveCallSessionCubit>();
    _pipCubit.restore();
    _startedAt = DateTime.now();
    _startTicker();
    _initRoom();
    _watchCallEndedByOthers();
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed = DateTime.now().difference(_startedAt));
    });
  }

  Future<void> _initRoom() async {
    final activeSession = context.read<ActiveCallSessionCubit>().state;

    if (_pipCubit.state.room != null &&
        activeSession?.callId == widget.call.callId) {
      _startedAt = activeSession!.startedAt;
      _elapsed = DateTime.now().difference(_startedAt);
      _attachTo(_pipCubit.state.room!);
      return;
    }
    await _connectNewRoom();
  }

  void _watchCallEndedByOthers() {
    _activeCallSub = _signaling.activeCallStream(widget.call.groupId).listen((
      call,
    ) {
      if (!mounted || _isEnding) return;
      if (call == null || call.callId != widget.call.callId) {
        _terminateCallSilently();
      }
    });
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

      _sessionCubit.startGroupCallSession(
        callId: widget.call.callId,
        title: widget.call.groupName,
        avatarUrl: widget.call.groupAvatarUrl,
        isVideo: _isVideo,
        startedAt: _startedAt,
        groupCall: widget.call,
        currentUserId: widget.currentUserId,
        currentUserName: widget.currentUserName,
      );

      _pipCubit.attach(
        room: room,
        isVideo: _isVideo,
        isGroup: true,
        onSoloTimeout: _terminateCall,
      );

      _attachTo(room);

      await FlutterForegroundTask.startService(
        serviceId: 102,
        notificationTitle: widget.call.groupName,
        notificationText: 'Ongoing Group Call',
        callback: startCallServiceCallback,
      );
    } catch (e, st) {
      debugPrint('❌ LiveKitGroupCallView._connectNewRoom failed: $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      _sessionCubit.endSession();
      setState(() {
        _loadError = e.toString();
        _connecting = false;
      });
    }
  }

  void _attachTo(Room room) {
    _room = room;
    _listener = room.createListener();
    _listener!
      ..on<ParticipantConnectedEvent>((_) => _recomputeParticipants())
      ..on<ParticipantDisconnectedEvent>((_) => _recomputeParticipants())
      ..on<TrackSubscribedEvent>((_) => _refresh())
      ..on<TrackUnsubscribedEvent>((_) => _refresh())
      ..on<TrackMutedEvent>((_) => _refresh())
      ..on<TrackUnmutedEvent>((_) => _refresh())
      ..on<ActiveSpeakersChangedEvent>((event) {
        if (!mounted) return;
        setState(() {
          _activeSpeakerIds = event.speakers.map((p) => p.identity).toSet();
        });
      })
      ..on<RoomDisconnectedEvent>((_) => _onRoomDisconnected());

    _recomputeParticipants();
    if (mounted) setState(() => _connecting = false);
  }

  void _refresh() {
    _recomputeParticipants();
    _pushPreviewTrack();
  }

  void _pushPreviewTrack() {
    final room = _room;
    if (room == null) return;
    _pipCubit.updatePreviewTrack(_resolveGroupPreviewTrack(room));
  }

  VideoTrack? _resolveGroupPreviewTrack(Room room) {
    for (final identity in _activeSpeakerIds) {
      if (identity == room.localParticipant?.identity) continue;
      final participant = _participantsByIdentity[identity];
      if (participant == null) continue;
      for (final pub in participant.videoTrackPublications) {
        if (pub.subscribed && !pub.muted && pub.track != null) {
          return pub.track as VideoTrack;
        }
      }
    }

    for (final participant in room.remoteParticipants.values) {
      for (final pub in participant.videoTrackPublications) {
        if (pub.subscribed && !pub.muted && pub.track != null) {
          return pub.track as VideoTrack;
        }
      }
    }

    for (final pub
        in room.localParticipant?.videoTrackPublications ?? const []) {
      if (!pub.muted && pub.track != null) return pub.track as VideoTrack;
    }
    return null;
  }

  void _recomputeParticipants() {
    final room = _room;
    if (room == null) return;

    final combined = <String, Participant>{};
    final local = room.localParticipant;
    if (local != null) combined[local.identity] = local;
    for (final p in room.remoteParticipants.values) {
      combined[p.identity] = p;
    }

    final newIds = combined.keys.toSet();
    final currentIds = _participantIds.toSet();

    for (final id in currentIds.difference(newIds)) {
      if (_leavingIds.contains(id)) continue;
      _leavingIds.add(id);
      Timer(const Duration(milliseconds: 320), () {
        if (!mounted) return;
        setState(() {
          _participantIds.remove(id);
          _leavingIds.remove(id);
        });
      });
    }
    for (final id in newIds.difference(currentIds)) {
      _participantIds.add(id);
    }

    _participantsByIdentity = combined;
    if (mounted) setState(() {});
  }

  void _onRoomDisconnected() {
    if (!mounted || _isEnding) return;
    _terminateCall();
  }

  Future<String?> _avatarFuture(String identity) {
    return _avatarCache.putIfAbsent(identity, () async {
      try {
        final data =
            await SupabaseProvider.client
                .from('users')
                .select('image_url')
                .eq('id', identity)
                .maybeSingle();
        return data?['image_url'] as String?;
      } catch (_) {
        return null;
      }
    });
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

  Future<void> _terminateCallSilently() async {
    if (_isEnding) return;
    _isEnding = true;
    if (mounted) setState(() {});
    await CallTerminationService.endActiveCall(
      pipCubit: _pipCubit,
      sessionCubit: _sessionCubit,
      signalEnd: () async {},
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _terminateCall() async {
    if (_isEnding) return;
    _isEnding = true;
    if (mounted) setState(() {});

    final duration = _formatDuration(DateTime.now().difference(_startedAt));
    final remainingAfterLeave = _participantIds.length - 1;
    final endForEveryone = remainingAfterLeave <= 1;

    await CallTerminationService.endActiveCall(
      pipCubit: _pipCubit,
      sessionCubit: _sessionCubit,
      signalEnd:
          () =>
              endForEveryone
                  ? _signaling.endCall(
                    widget.call.callId,
                    duration: duration,
                    participantCount: remainingAfterLeave.clamp(0, 1 << 30),
                  )
                  : _signaling.leaveCall(widget.call.callId),
    );
    if (mounted) Navigator.of(context).pop();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _listener?.dispose();
    _activeCallSub?.cancel();
    super.dispose();
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

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) context.read<CallPipCubit>().minimize();
      },
      child: Scaffold(
        body: Stack(
          children: [
            CallAvatarBackdrop(
              avatarUrl: widget.call.groupAvatarUrl,
              baseColor: primary,
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final metrics = CallLayoutMetrics.of(
                    constraints,
                    reservedHeight: 0,
                  );
                  return Column(
                    children: [
                      _buildTopBar(),
                      Expanded(child: _buildGrid()),
                      const SizedBox(height: 8),
                      _buildControls(metrics.buttonSize),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');

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
                        widget.call.groupName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      CallStatusPill(
                        icon: Icons.circle,
                        label: '$m:$s',
                        showLiveDot: true,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed:
                      () => GroupCallMembersSheet.show(context, widget.call),
                  icon: const Icon(Icons.groups_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    final count = _participantIds.length;
    if (count == 0) return const SizedBox.shrink();

    final columns = count <= 1 ? 1 : (count <= 4 ? 2 : (count <= 9 ? 3 : 4));

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 3 / 4,
      ),
      itemCount: count,
      itemBuilder: (context, index) {
        final id = _participantIds[index];
        final participant = _participantsByIdentity[id];
        if (participant == null) return const SizedBox.shrink();

        return _ParticipantTile(
          key: ValueKey(id),
          participant: participant,
          isLeaving: _leavingIds.contains(id),
          isSpeaking: _activeSpeakerIds.contains(id),
          avatarFuture: _avatarFuture(id),
          isMe: id == widget.currentUserId,
        );
      },
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
          onTap: _terminateCall,
        ),
      ],
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final Participant participant;
  final bool isMe;
  final bool isLeaving;
  final bool isSpeaking;
  final Future<String?> avatarFuture;

  const _ParticipantTile({
    super.key,
    required this.participant,
    required this.isMe,
    required this.isLeaving,
    required this.isSpeaking,
    required this.avatarFuture,
  });

  VideoTrack? get _videoTrack {
    for (final pub in participant.videoTrackPublications) {
      if (!pub.muted && pub.track != null) return pub.track as VideoTrack;
    }
    return null;
  }

  bool get _isMuted {
    final pubs = participant.audioTrackPublications;
    return pubs.isEmpty || pubs.first.muted;
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: isLeaving ? 0.0 : 1.0),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.85 + (0.15 * value.clamp(0.0, 1.0)),
            child: child,
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isSpeaking
                      ? Colors.greenAccent
                      : Colors.white.withValues(alpha: 0.12),
              width: isSpeaking ? 2.4 : 1,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _videoTrack != null
                  ? VideoTrackRenderer(_videoTrack!)
                  : Center(
                    child: FutureBuilder<String?>(
                      future: avatarFuture,
                      builder: (context, snapshot) {
                        return CallAvatarImage(
                          imageUrl: snapshot.data,
                          fallbackLabel:
                              participant.name.isNotEmpty
                                  ? participant.name
                                  : participant.identity,
                          diameter: 64,
                        );
                      },
                    ),
                  ),
              Positioned(
                left: 8,
                bottom: 6,
                right: 8,
                child: Row(
                  children: [
                    if (_isMuted)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.mic_off_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                      ),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isMe
                              ? 'You'
                              : (participant.name.isNotEmpty
                                  ? participant.name
                                  : participant.identity),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
