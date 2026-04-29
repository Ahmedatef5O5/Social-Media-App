import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/single_call_cubit/call_cubit.dart';
import '../model/call_model.dart';

class DialingView extends StatefulWidget {
  final CallModel call;

  const DialingView({super.key, required this.call});

  @override
  State<DialingView> createState() => _DialingViewState();
}

class _DialingViewState extends State<DialingView>
    with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();

  late AnimationController _pulseController;
  late AnimationController _floatController;
  late AnimationController _dotController;

  late Animation<double> _pulse1;
  late Animation<double> _pulse2;
  late Animation<double> _pulse3;
  late Animation<double> _floatAnim;
  late Animation<double> _dotAnim;

  @override
  void initState() {
    super.initState();
    _playRingtone();
    _initAnimations();
  }

  void _initAnimations() {
    // Pulse rings around avatar
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _pulse1 = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _pulse2 = Tween<double>(begin: 1.0, end: 1.9).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );
    _pulse3 = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    // Floating decoration icons
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _dotAnim = Tween<double>(begin: 0, end: 3).animate(_dotController);
  }

  Future<void> _playRingtone() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/outgoing_ring.mp3'));
    } catch (_) {}
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isVideo = widget.call.type == CallType.video;

    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(primary),

          _buildDecorativeSymbols(primary, isVideo),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 50),

                _buildCallTypeBadge(isVideo, primary),

                const SizedBox(height: 40),

                _buildAvatarWithPulse(primary),

                const SizedBox(height: 28),

                // Name
                Text(
                  widget.call.receiverName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 10),

                _buildCallingDots(),

                const Spacer(),

                _buildCancelButton(context),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(Color primary) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary,
            primary.withValues(alpha: 0.85),
            HSLColor.fromColor(primary)
                .withLightness(
                  (HSLColor.fromColor(primary).lightness - 0.15).clamp(
                    0.0,
                    1.0,
                  ),
                )
                .toColor(),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  Widget _buildDecorativeSymbols(Color primary, bool isVideo) {
    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (_, __) {
        return Stack(
          children: [
            Positioned(
              top: 60 + _floatAnim.value,
              right: -30,
              child: Opacity(
                opacity: 0.08,
                child: Icon(
                  isVideo ? Icons.videocam_rounded : Icons.phone_rounded,
                  size: 200,
                  color: Colors.white,
                ),
              ),
            ),
            Positioned(
              bottom: 100 - _floatAnim.value,
              left: -40,
              child: Opacity(
                opacity: 0.06,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 20),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 200 - _floatAnim.value * 0.5,
              left: 20,
              child: Opacity(
                opacity: 0.07,
                child: Icon(
                  Icons.signal_cellular_alt_rounded,
                  size: 80,
                  color: Colors.white,
                ),
              ),
            ),
            Positioned(
              top: 80,
              left: 30,
              child: Opacity(opacity: 0.10, child: _buildDotGrid(primary)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDotGrid(Color primary) {
    return SizedBox(
      width: 60,
      height: 60,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 16,
        itemBuilder:
            (_, __) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
      ),
    );
  }

  Widget _buildCallTypeBadge(bool isVideo, Color primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVideo ? Icons.videocam_rounded : Icons.phone_rounded,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            isVideo ? 'Video Call' : 'Voice Call',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarWithPulse(Color primary) {
    final lighterPrimary =
        HSLColor.fromColor(primary)
            .withLightness(
              (HSLColor.fromColor(primary).lightness + 0.2).clamp(0.0, 1.0),
            )
            .toColor();

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, child) {
        return SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: (1 - _pulseController.value).clamp(0.0, 0.15),
                child: Transform.scale(
                  scale: _pulse3.value,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: lighterPrimary.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
              Opacity(
                opacity: (1 - _pulseController.value * 0.7).clamp(0.0, 0.25),
                child: Transform.scale(
                  scale: _pulse2.value,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ),
              // Pulse ring 1 (innermost)
              Opacity(
                opacity: (1 - _pulseController.value * 0.5).clamp(0.0, 0.35),
                child: Transform.scale(
                  scale: _pulse1.value,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                ),
              ),
              // Avatar
              child!,
            ],
          ),
        );
      },
      child: Container(
        width: 130,
        height: 130,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.6),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipOval(
          child:
              widget.call.receiverAvatar.isNotEmpty
                  ? CachedNetworkImage(
                    imageUrl: widget.call.receiverAvatar,
                    fit: BoxFit.cover,
                    errorWidget:
                        (_, __, ___) =>
                            _defaultAvatar(widget.call.receiverName),
                  )
                  : _defaultAvatar(widget.call.receiverName),
        ),
      ),
    );
  }

  Widget _buildCallingDots() {
    return AnimatedBuilder(
      animation: _dotAnim,
      builder: (_, __) {
        final dots = '.' * (_dotAnim.value.toInt() + 1);
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.phone_forwarded_rounded,
              color: Colors.white60,
              size: 15,
            ),
            const SizedBox(width: 6),
            Text(
              widget.call.type == CallType.video
                  ? 'Calling (Video)$dots'
                  : 'Calling (Audio)$dots',
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

  Widget _buildCancelButton(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            context.read<CallCubit>().endCall(widget.call.callId);
            Navigator.pop(context);
          },
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.redAccent.shade700,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.call_end_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Cancel',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _defaultAvatar(String name) {
    return Container(
      color: Colors.white.withValues(alpha: 0.2),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 52,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
