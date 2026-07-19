import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/widgets/calls/calls.dart';
import '../models/group_call_model.dart';
import '../services/group_call_signaling_service.dart';
import 'zego_group_call_view.dart';

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
  String _currentUserName = 'Loading...';

  late final GroupCallSignalingService _signaling;
  late final AnimationController _dotController;
  late final Animation<int> _dotAnim;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _signaling = context.read<GroupCallSignalingService>();
    _fetchMyName();
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

  Future<void> _fetchMyName() async {
    final user = SupabaseProvider.user!;
    final data =
        await SupabaseProvider.client
            .from('users')
            .select('name')
            .eq('id', user.id)
            .maybeSingle();
    if (mounted) {
      setState(() => _currentUserName = (data?['name'] as String?) ?? 'Me');
    }
  }

  Future<void> _playRingtone() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/outgoing_ring.mp3'));
    } catch (_) {}
  }

  void _startCallMonitoring() {
    _callSubscription = _signaling.activeCallStream(widget.groupId).listen((
      call,
    ) {
      if (call == null) return;
      _currentCallId = call.callId;

      if (call.status == GroupCallStatus.accepted ||
          call.status == GroupCallStatus.ongoing) {
        _navigateToZego(call);
      }
    });
  }

  void _navigateToZego(GroupCallModel call) {
    _cleanup();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => ZegoGroupCallView(
              call: call,
              currentUserId: SupabaseProvider.id,
              currentUserName: _currentUserName,
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
          CallGradientBackground(baseColor: primary),
          CallAmbientBackground(style: CallAmbientStyle.drift, isVideo: isVideo),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final shortest = constraints.biggest.shortestSide;
                  final avatarDiameter = (shortest.clamp(280.0, 460.0) * 0.34).toDouble();
                  final buttonSize = (shortest.clamp(280.0, 460.0) * 0.19).toDouble();
                  final isCompact = constraints.maxHeight < 620;

                  return Column(
                    children: [
                      SizedBox(height: isCompact ? 16 : 28),

                      CallStatusPill(
                        icon:
                            isVideo ? Icons.videocam_rounded : Icons.phone_rounded,
                        label: isVideo ? 'Group Video Call' : 'Group Voice Call',
                      ),

                      Expanded(
                        child: Center(
                          child: _buildGroupInfoSection(avatarDiameter),
                        ),
                      ),

                      GlassCallActionButton(
                        icon: Icons.call_end_rounded,
                        label: 'Cancel',
                        color: Colors.red.shade600,
                        size: buttonSize,
                        onTap: () async {
                          _cleanup();
                          if (_currentCallId != null) {
                            await _signaling.endCall(_currentCallId!);
                          }
                          if (mounted) Navigator.pop(context);
                        },
                      ),

                      SizedBox(height: isCompact ? 24 : 56),
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

  Widget _buildGroupInfoSection(double avatarDiameter) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RippleAvatar(
          avatarDiameter: avatarDiameter,
          rippleColor: Colors.white,
          avatar: CallAvatarImage(
            imageUrl: widget.groupAvatarUrl,
            fallbackLabel: widget.groupName,
            diameter: avatarDiameter,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          widget.groupName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        _buildCallingStatus(),
      ],
    );
  }

  Widget _buildCallingStatus() {
    return AnimatedBuilder(
      animation: _dotAnim,
      builder: (_, __) {
        final dots = '.' * (_dotAnim.value + 1);
        return Text(
          'Calling group members$dots',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 16,
            letterSpacing: 0.3,
          ),
        );
      },
    );
  }
}
