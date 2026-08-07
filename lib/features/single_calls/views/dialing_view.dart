import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/widgets/calls/call_layout_metrics.dart';
import '../../../core/widgets/calls/calls.dart';
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

  late final AnimationController _dotController;
  late final Animation<double> _dotAnim;

  @override
  void initState() {
    super.initState();
    _playRingtone();

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
          CallGradientBackground(baseColor: primary),
          CallAmbientBackground(
            style: CallAmbientStyle.orbit,
            isVideo: isVideo,
          ),
          SafeArea(
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
                      label: isVideo ? 'Video Call' : 'Voice Call',
                    ),

                    SizedBox(height: metrics.midGap),

                    RippleAvatar(
                      avatarDiameter: metrics.avatarDiameter,
                      rippleColor: Colors.white,
                      avatar: CallAvatarImage(
                        imageUrl: widget.call.receiverAvatar,
                        fallbackLabel: widget.call.receiverName,
                        diameter: metrics.avatarDiameter,
                      ),
                    ),

                    SizedBox(height: metrics.midGap),

                    Text(
                      widget.call.receiverName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 10),
                    _buildCallingDots(isVideo),
                    const Spacer(),

                    GlassCallActionButton(
                      icon: Icons.call_end_rounded,
                      label: 'Cancel',
                      color: Colors.redAccent.shade700,
                      size: metrics.buttonSize,
                      onTap: () {
                        context.read<CallCubit>().endCall(widget.call.callId);
                        Navigator.pop(context);
                      },
                    ),

                    SizedBox(height: metrics.bottomGap),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallingDots(bool isVideo) {
    return AnimatedBuilder(
      animation: _dotAnim,
      builder: (_, __) {
        final dots = '.' * (_dotAnim.value.toInt() + 1);
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
              isVideo ? 'Calling (Video)$dots' : 'Calling (Audio)$dots',
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
