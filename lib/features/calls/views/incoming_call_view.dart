import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/single_call_cubit/call_cubit.dart';
import '../model/call_model.dart';

class IncomingCallView extends StatefulWidget {
  final CallModel call;

  const IncomingCallView({super.key, required this.call});

  @override
  State<IncomingCallView> createState() => _IncomingCallViewState();
}

class _IncomingCallViewState extends State<IncomingCallView>
    with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();

  late AnimationController _ringController;
  late AnimationController _floatController;
  late AnimationController _shakeController;

  late Animation<double> _ring1;
  late Animation<double> _ring2;
  late Animation<double> _ring3;
  late Animation<double> _floatAnim;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _playRingtone();
    _initAnimations();
  }

  void _initAnimations() {
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _ring1 = Tween<double>(begin: 1.0, end: 1.7).animate(
      CurvedAnimation(
        parent: _ringController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _ring2 = Tween<double>(begin: 1.0, end: 2.1).animate(
      CurvedAnimation(
        parent: _ringController,
        curve: const Interval(0.15, 0.75, curve: Curves.easeOut),
      ),
    );
    _ring3 = Tween<double>(begin: 1.0, end: 2.5).animate(
      CurvedAnimation(
        parent: _ringController,
        curve: const Interval(0.3, 0.9, curve: Curves.easeOut),
      ),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _shakeAnim = Tween<double>(begin: -3, end: 3).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  Future<void> _playRingtone() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/incoming_ring.mp3'));
    } catch (_) {}
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _ringController.dispose();
    _floatController.dispose();
    _shakeController.dispose();
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

          _buildDecorations(primary, isVideo),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 50),

                _buildIncomingBadge(isVideo),

                const SizedBox(height: 36),

                _buildAvatarWithRings(primary),

                const SizedBox(height: 24),

                // Name
                Text(
                  widget.call.callerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'is calling you...',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                ),

                const Spacer(),

                // Accept / Decline
                _buildActionButtons(context, isVideo),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(Color primary) {
    final darker =
        HSLColor.fromColor(primary)
            .withLightness(
              (HSLColor.fromColor(primary).lightness - 0.18).clamp(0.0, 1.0),
            )
            .toColor();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [primary, darker],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }

  Widget _buildDecorations(Color primary, bool isVideo) {
    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (_, __) {
        return Stack(
          children: [
            Positioned(
              top: 40 + _floatAnim.value,
              left: -20,
              child: Opacity(
                opacity: 0.08,
                child: Icon(
                  Icons.graphic_eq_rounded,
                  size: 160,
                  color: Colors.white,
                ),
              ),
            ),
            Positioned(
              bottom: 80 - _floatAnim.value,
              right: -50,
              child: Opacity(
                opacity: 0.07,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 22),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 220 + _floatAnim.value * 0.7,
              right: 30,
              child: Opacity(
                opacity: 0.09,
                child: Icon(
                  isVideo
                      ? Icons.videocam_rounded
                      : Icons.phone_in_talk_rounded,
                  size: 70,
                  color: Colors.white,
                ),
              ),
            ),
            Positioned(
              bottom: 160 + _floatAnim.value * 0.3,
              left: 20,
              child: Opacity(opacity: 0.09, child: _buildDotGrid()),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDotGrid() {
    return SizedBox(
      width: 55,
      height: 55,
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

  Widget _buildIncomingBadge(bool isVideo) {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (_, child) {
        return Transform.translate(
          offset: Offset(_shakeAnim.value * 0.4, 0),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _shakeAnim,
              builder:
                  (_, child) => Transform.rotate(
                    angle: _shakeAnim.value * 0.05,
                    child: child,
                  ),
              child: Icon(
                isVideo ? Icons.videocam_rounded : Icons.phone_callback_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isVideo ? 'Incoming Video Call' : 'Incoming Voice Call',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarWithRings(Color primary) {
    return AnimatedBuilder(
      animation: _ringController,
      builder: (_, child) {
        return SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ring 3
              Opacity(
                opacity: (1 - _ringController.value).clamp(0.0, 0.12),
                child: Transform.scale(
                  scale: _ring3.value,
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
              // Ring 2
              Opacity(
                opacity: (1 - _ringController.value * 0.7).clamp(0.0, 0.22),
                child: Transform.scale(
                  scale: _ring2.value,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                ),
              ),
              // Ring 1 (innermost)
              Opacity(
                opacity: (1 - _ringController.value * 0.5).clamp(0.0, 0.35),
                child: Transform.scale(
                  scale: _ring1.value,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
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
            color: Colors.greenAccent.withValues(alpha: 0.7),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipOval(
          child:
              widget.call.callerAvatar.isNotEmpty
                  ? CachedNetworkImage(
                    imageUrl: widget.call.callerAvatar,
                    fit: BoxFit.cover,
                    errorWidget:
                        (_, __, ___) => _defaultAvatar(widget.call.callerName),
                  )
                  : _defaultAvatar(widget.call.callerName),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isVideo) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.call_end_rounded,
            color: Colors.redAccent.shade700,
            label: 'Decline',
            shadowColor: Colors.red,
            onTap: () {
              context.read<CallCubit>().rejectCall(widget.call);
              Navigator.pop(context);
            },
          ),
          _buildActionButton(
            icon: isVideo ? Icons.videocam_rounded : Icons.call_rounded,
            color: Colors.green.shade600,
            label: 'Accept',
            shadowColor: Colors.green,
            onTap: () {
              context.read<CallCubit>().acceptCall(widget.call);
            },
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
                  color: shadowColor.withValues(alpha: 0.45),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 34),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
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
