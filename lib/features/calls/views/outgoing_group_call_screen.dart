import 'dart:async';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../group_chat/models/group_call_model.dart';
import '../../group_chat/services/group_call_signaling_service.dart';
import '../views/zego_group_call_view.dart';

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
  final _signaling = GroupCallSignalingService();

  StreamSubscription? _callSubscription;
  Timer? _timeoutTimer;
  String? _currentCallId;
  String _currentUserName = 'Loading...';

  late AnimationController _rippleController;
  late AnimationController _particleController;
  late AnimationController _dotController;
  late Animation<int> _dotAnim;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fetchMyName();
    _playRingtone();
    _initAnimations();
    _startCallMonitoring();
    _timeoutTimer = Timer(const Duration(seconds: 45), _handleTimeout);
  }

  Future<void> _fetchMyName() async {
    final user = Supabase.instance.client.auth.currentUser!;
    final data =
        await Supabase.instance.client
            .from('users')
            .select('name')
            .eq('id', user.id)
            .maybeSingle();
    if (mounted) {
      setState(() => _currentUserName = (data?['name'] as String?) ?? 'Me');
    }
  }

  void _initAnimations() {
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

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
              currentUserId: Supabase.instance.client.auth.currentUser!.id,
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
    _rippleController.dispose();
    _particleController.dispose();
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
          _buildBackground(primary),
          _buildParticles(isVideo),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  const SizedBox(height: 28),
                  _buildCallTypeBadge(isVideo, primary),
                  Expanded(
                    child: Center(child: _buildGroupInfoSection(primary)),
                  ),
                  _buildCancelButton(),
                  const SizedBox(height: 56),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(Color primary) {
    final hsl = HSLColor.fromColor(primary);
    final darker =
        hsl.withLightness((hsl.lightness - 0.22).clamp(0.0, 1.0)).toColor();
    final mid =
        hsl.withLightness((hsl.lightness - 0.10).clamp(0.0, 1.0)).toColor();
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, mid, darker],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  Widget _buildParticles(bool isVideo) {
    return AnimatedBuilder(
      animation: _particleController,
      builder:
          (_, __) => CustomPaint(
            painter: _OutgoingParticlePainter(
              progress: _particleController.value,
              isVideo: isVideo,
            ),
            child: const SizedBox.expand(),
          ),
    );
  }

  Widget _buildCallTypeBadge(bool isVideo, Color primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVideo ? Icons.videocam_rounded : Icons.phone_rounded,
            color: Colors.white.withValues(alpha: 0.9),
            size: 15,
          ),
          const SizedBox(width: 8),
          Text(
            isVideo ? 'Group Video Call' : 'Group Voice Call',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupInfoSection(Color primary) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _rippleController,
          builder: (context, child) {
            return SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _buildRipple(0.0),
                  _buildRipple(0.33),
                  _buildRipple(0.66),
                  child!,
                ],
              ),
            );
          },
          child: _buildAvatarCircle(primary),
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

  Widget _buildRipple(double delay) {
    final t = (_rippleController.value + delay) % 1.0;
    final scale = 0.85 + t * 0.7;
    final opacity = (0.25 * (1 - t)).clamp(0.0, 1.0);
    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.8),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarCircle(Color primary) {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.7),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: primary.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child:
            widget.groupAvatarUrl?.isNotEmpty == true
                ? CachedNetworkImage(
                  imageUrl: widget.groupAvatarUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _defaultAvatar(primary),
                )
                : _defaultAvatar(primary),
      ),
    );
  }

  Widget _defaultAvatar(Color primary) => Container(
    color: primary.withValues(alpha: 0.3),
    child: Center(
      child: Text(
        widget.groupName.isNotEmpty ? widget.groupName[0].toUpperCase() : 'G',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 54,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );

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

  Widget _buildCancelButton() {
    return GestureDetector(
      onTap: () async {
        _cleanup();
        if (_currentCallId != null) await _signaling.endCall(_currentCallId!);
        if (mounted) Navigator.pop(context);
      },
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.red.shade600,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.5),
                  blurRadius: 24,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.call_end_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Cancel',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutgoingParticlePainter extends CustomPainter {
  final double progress;
  final bool isVideo;

  _OutgoingParticlePainter({required this.progress, required this.isVideo});

  @override
  void paint(Canvas canvas, Size size) {
    const count = 14;
    for (int i = 0; i < count; i++) {
      final seed = (i * 137.5) % 360;
      final x = (seed / 360) * size.width;
      final yProgress = (progress + i / count) % 1.0;
      final y = size.height * (1 - yProgress);
      final radius = 2.0 + (i % 4) * 1.5;
      final opacity = (1 - yProgress).clamp(0.0, 1.0) * 0.5;
      canvas.drawCircle(
        Offset(x + math.sin(progress * math.pi * 2 + seed) * 20, y),
        radius,
        Paint()..color = Colors.white.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_OutgoingParticlePainter old) => old.progress != progress;
}
