import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/call_identity.dart';
import '../../../core/services/current_user_name_resolver.dart';
import '../../../core/services/incoming_call_navigation_guard.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/widgets/calls/call_avatar_backdrop.dart';
import '../../../core/widgets/calls/call_layout_metrics.dart';
import '../../../core/widgets/calls/calls.dart';
import '../models/group_call_model.dart';
import '../services/group_call_signaling_service.dart';
import 'livekit_group_call_view.dart';

class OutgoingGroupCallScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String? groupAvatarUrl;
  final GroupCallType callType;

  const OutgoingGroupCallScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    this.groupAvatarUrl,
    required this.callType,
  });

  @override
  State<OutgoingGroupCallScreen> createState() =>
      _OutgoingGroupCallScreenState();
}

class _OutgoingGroupCallScreenState extends State<OutgoingGroupCallScreen>
    with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();

  StreamSubscription? _callSubscription;
  Timer? _timeoutTimer;
  String? _currentCallId;
  bool _isNavigating = false;

  // Empty == "not resolved yet" (CallIdentity.isPlaceholderName treats it as
  // a placeholder). Never sent to LiveKit until replaced by the real name.
  String _currentUserName = '';
  late final Future<String> _nameFuture;

  late final GroupCallSignalingService _signaling;
  late final AnimationController _dotController;
  late final Animation<int> _dotAnim;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _signaling = context.read<GroupCallSignalingService>();
    // Belt-and-braces: `GroupCallInitiator` already set this before
    // `initiateCall`, but a screen pushed from anywhere else must hold the
    // flag too so no IncomingGroupCallScreen can stack on top of it.
    IncomingCallNavigationGuard.setOutgoingGroupCallActive(true);
    _nameFuture = CurrentUserNameResolver.resolve();
    unawaited(_captureName());
    _playRingtone();
    _initAnimations();
    _startCallMonitoring();
    _timeoutTimer = Timer(const Duration(seconds: 45), _handleTimeout);
  }

  void _initAnimations() {
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    _dotAnim = IntTween(begin: 0, end: 3).animate(_dotController);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  Future<void> _captureName() async {
    final name = await _nameFuture;
    if (mounted) _currentUserName = name;
  }

  Future<void> _playRingtone() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/outgoing_ring.mp3'));
    } catch (e) {
      debugPrint('[OutgoingGroupCall] failed to play ringtone: $e');
    }
  }

  void _startCallMonitoring() {
    _callSubscription = _signaling.activeCallStream(widget.groupId).listen((
      call,
    ) {
      if (call == null) return;
      _currentCallId = call.callId;

      if (call.status == GroupCallStatus.accepted ||
          call.status == GroupCallStatus.ongoing) {
        unawaited(_navigateToLiveKit(call));
      }
    });
  }

  Future<void> _navigateToLiveKit(GroupCallModel call) async {
    if (_isNavigating) return;
    _isNavigating = true;
    _cleanup();

    // The call can be accepted before the name lookup finishes. Wait for it:
    // 'Loading...' / 'Me' must never reach LiveKit as the participant name.
    var name = _currentUserName;
    if (CallIdentity.isPlaceholderName(name)) {
      name = await _nameFuture;
    }
    if (!mounted) return;

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => LiveKitGroupCallView(
              call: call,
              currentUserId: SupabaseProvider.id,
              currentUserName: name,
            ),
      ),
    );
  }

  Future<void> _handleTimeout() async {
    if (_currentCallId != null) await _signaling.markAsMissed(_currentCallId!);
    if (mounted) Navigator.pop(context);
  }

  void _cleanup() {
    _audioPlayer.stop();
    _callSubscription?.cancel();
    _timeoutTimer?.cancel();
  }

  @override
  void dispose() {
    IncomingCallNavigationGuard.setOutgoingGroupCallActive(false);
    _cleanup();
    _audioPlayer.dispose();
    _dotController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isVideo = widget.callType == GroupCallType.video;

    return Scaffold(
      body: Stack(
        children: [
          CallAvatarBackdrop(
            avatarUrl: widget.groupAvatarUrl,
            baseColor: primary,
          ),
          CallAmbientBackground(
            style: CallAmbientStyle.orbit,
            isVideo: isVideo,
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final metrics = CallLayoutMetrics.of(constraints);

                  return Column(
                    children: [
                      SizedBox(height: metrics.topGap),

                      CallStatusPill(
                        icon:
                            isVideo
                                ? Icons.videocam_rounded
                                : Icons.phone_rounded,
                        label:
                            isVideo ? 'Group Video Call' : 'Group Voice Call',
                      ),

                      SizedBox(height: metrics.midGap),

                      RippleAvatar(
                        avatarDiameter: metrics.avatarDiameter,
                        rippleColor: Colors.white,
                        avatar: CallAvatarImage(
                          imageUrl: widget.groupAvatarUrl,
                          fallbackLabel: widget.groupName,
                          diameter: metrics.avatarDiameter,
                          isGroup: true,
                        ),
                      ),

                      SizedBox(height: metrics.midGap),

                      Text(
                        widget.groupName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              blurRadius: 12,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 10),

                      _buildCallingStatus(isVideo),

                      const Spacer(),

                      GlassCallActionButton(
                        icon: Icons.call_end_rounded,
                        label: 'Cancel',
                        color: Colors.redAccent.shade700,
                        size: metrics.buttonSize,
                        onTap: () async {
                          _cleanup();
                          if (_currentCallId != null) {
                            // Was still ringing — nobody ever joined. `markAsMissed` is the
                            // correct terminal state here (not `endCall`, which is reserved for
                            // a call that actually connected). This also fires the cancellation
                            // push to backgrounded receivers — see GroupCallSignalingService.
                            await _signaling.markAsMissed(_currentCallId!);
                          }
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                      ),

                      SizedBox(height: metrics.bottomGap),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallingStatus(bool isVideo) {
    return AnimatedBuilder(
      animation: _dotAnim,
      builder: (_, __) {
        final dots = '.' * (_dotAnim.value + 1);
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.phone_forwarded_rounded,
              color: Colors.white60,
              size: 15,
            ),
            const SizedBox(width: 6),
            Text(
              isVideo
                  ? 'Calling group (Video)$dots'
                  : 'Calling group (Audio)$dots',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                letterSpacing: 0.3,
              ),
            ),
          ],
        );
      },
    );
  }
}
