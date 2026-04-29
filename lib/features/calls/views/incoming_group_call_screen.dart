import 'dart:async';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../group_chat/models/group_call_model.dart';
import '../../group_chat/services/group_call_signaling_service.dart';
import '../views/zego_group_call_view.dart';

class IncomingGroupCallScreen extends StatefulWidget {
  final GroupCallModel call;
  const IncomingGroupCallScreen({super.key, required this.call});

  @override
  State<IncomingGroupCallScreen> createState() =>
      _IncomingGroupCallScreenState();
}

class _IncomingGroupCallScreenState extends State<IncomingGroupCallScreen>
    with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final _signaling = GroupCallSignalingService();
  String _currentUserName = 'Loading...';

  late AnimationController _rippleController;

  late AnimationController _particleController;

  late AnimationController _titleController;
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;

  late AnimationController _buttonPulseController;
  late Animation<double> _buttonPulse;

  @override
  void initState() {
    super.initState();
    _fetchMyName();
    _playRingtone();
    _initAnimations();
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

    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _titleFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _titleController, curve: Curves.easeOut));
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeOutCubic),
    );
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _titleController.forward();
    });

    _buttonPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _buttonPulse = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _buttonPulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _playRingtone() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/incoming_ring.mp3'));
    } catch (_) {}
  }

  void _cleanup() => _audioPlayer.stop();

  @override
  void dispose() {
    _cleanup();
    _audioPlayer.dispose();
    _rippleController.dispose();
    _particleController.dispose();
    _titleController.dispose();
    _buttonPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isVideo = widget.call.type == GroupCallType.video;

    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(primary),
          _buildParticles(isVideo, primary),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 28),
                _buildIncomingBadge(isVideo, primary),
                Expanded(child: Center(child: _buildGroupInfoSection(primary))),
                _buildActionButtons(context, isVideo),
                const SizedBox(height: 56),
              ],
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

  Widget _buildParticles(bool isVideo, Color primary) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (_, __) {
        return CustomPaint(
          painter: _ParticlePainter(
            progress: _particleController.value,
            isVideo: isVideo,
            color: Colors.white.withValues(alpha: 0.12),
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }

  Widget _buildIncomingBadge(bool isVideo, Color primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
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
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.greenAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            isVideo ? Icons.videocam_rounded : Icons.phone_callback_rounded,
            color: Colors.white,
            size: 15,
          ),
          const SizedBox(width: 6),
          Text(
            isVideo ? 'Incoming Group Video' : 'Incoming Group Voice',
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
        // الأفاتار مع النبضات
        AnimatedBuilder(
          animation: _rippleController,
          builder: (context, child) {
            return SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _buildRipple(0.0, primary),
                  _buildRipple(0.33, primary),
                  _buildRipple(0.66, primary),
                  child!,
                ],
              ),
            );
          },
          child: _buildAvatarCircle(),
        ),
        const SizedBox(height: 32),
        // اسم الجروب مع أنيميشن الظهور
        FadeTransition(
          opacity: _titleFade,
          child: SlideTransition(
            position: _titleSlide,
            child: Column(
              children: [
                Text(
                  widget.call.groupName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.call.initiatorName} is calling',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 15,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRipple(double delay, Color primary) {
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

  Widget _buildAvatarCircle() {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.greenAccent.withValues(alpha: 0.8),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: Colors.greenAccent.withValues(alpha: 0.25),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child:
            widget.call.groupAvatarUrl?.isNotEmpty == true
                ? CachedNetworkImage(
                  imageUrl: widget.call.groupAvatarUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _defaultAvatar(),
                )
                : _defaultAvatar(),
      ),
    );
  }

  Widget _defaultAvatar() => Container(
    color: Colors.white.withValues(alpha: 0.15),
    child: Center(
      child: Text(
        widget.call.groupName.isNotEmpty
            ? widget.call.groupName[0].toUpperCase()
            : 'G',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 54,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );

  Widget _buildActionButtons(BuildContext context, bool isVideo) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.call_end_rounded,
            color: Colors.red.shade600,
            label: 'Decline',
            shadowColor: Colors.red,
            onTap: () {
              _cleanup();
              _signaling.rejectCall(widget.call.callId);
              Navigator.pop(context);
            },
          ),
          ScaleTransition(
            scale: _buttonPulse,
            child: _buildActionButton(
              icon: isVideo ? Icons.videocam_rounded : Icons.call_rounded,
              color: Colors.green.shade500,
              label: 'Accept',
              shadowColor: Colors.green,
              onTap: () async {
                _cleanup();
                final updatedCall = await _signaling.acceptCall(
                  widget.call.callId,
                );
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ZegoGroupCallView(
                            call: updatedCall,
                            currentUserId:
                                Supabase.instance.client.auth.currentUser!.id,
                            currentUserName: _currentUserName,
                          ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required Color shadowColor,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: shadowColor.withValues(alpha: 0.5),
                  blurRadius: 24,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: shadowColor.withValues(alpha: 0.2),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 34),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// Painter للجسيمات الطائرة في الخلفية
class _ParticlePainter extends CustomPainter {
  final double progress;
  final bool isVideo;
  final Color color;

  _ParticlePainter({
    required this.progress,
    required this.isVideo,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const count = 14;
    for (int i = 0; i < count; i++) {
      final seed = (i * 137.5) % 360;
      final x = (seed / 360) * size.width;
      final yProgress = (progress + i / count) % 1.0;
      final y = size.height * (1 - yProgress);
      final radius = 2.0 + (i % 4) * 1.5;
      final opacity = (1 - yProgress).clamp(0.0, 1.0) * 0.6;
      canvas.drawCircle(
        Offset(x + math.sin(progress * math.pi * 2 + seed) * 20, y),
        radius,
        Paint()..color = color.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
