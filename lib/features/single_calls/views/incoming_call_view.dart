import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/widgets/calls/call_avatar_backdrop.dart';
import '../../../core/widgets/calls/call_layout_metrics.dart';
import '../../../core/widgets/calls/calls.dart';
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

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnim;

  StreamSubscription? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _playRingtone();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _shakeAnim = Tween<double>(begin: -3, end: 3).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _listenToCallStatus();
  }

  void _listenToCallStatus() {
    final signaling = context.read<CallCubit>().signalingService;

    _statusSubscription = signaling.callStatusStream(widget.call.callId).listen(
      (data) {
        if (!mounted || data.isEmpty) return;

        final updatedCall = CallModel.fromMap(data.first);
        if (updatedCall.status == CallStatus.ended ||
            updatedCall.status == CallStatus.rejected) {
          _closeScreen();
        }
      },
    );
  }

  void _closeScreen() {
    _audioPlayer.stop();
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  Future<void> _playRingtone() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/incoming_ring.mp3'));
    } catch (e) {
      debugPrint('[IncomingCallView] failed to play ringtone: $e');
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _audioPlayer.stop();
    _audioPlayer.dispose();
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
          CallAvatarBackdrop(
            avatarUrl: widget.call.callerAvatar,
            baseColor: primary,
          ),
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
                              : Icons.phone_callback_rounded,
                      label:
                          isVideo
                              ? 'Incoming Video Call'
                              : 'Incoming Voice Call',
                      shake: _shakeAnim,
                    ),

                    SizedBox(height: metrics.midGap),

                    RippleAvatar(
                      avatarDiameter: metrics.avatarDiameter,
                      rippleColor: Colors.greenAccent,
                      avatar: CallAvatarImage(
                        imageUrl: widget.call.callerAvatar,
                        fallbackLabel: widget.call.callerName,
                        diameter: metrics.avatarDiameter,
                        borderColor: Colors.greenAccent,
                      ),
                    ),

                    SizedBox(height: metrics.midGap),

                    Text(
                      widget.call.callerName,
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

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 60),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GlassCallActionButton(
                            icon: Icons.call_end_rounded,
                            label: 'Decline',
                            color: Colors.redAccent.shade700,
                            size: metrics.buttonSize,
                            onTap: () {
                              context.read<CallCubit>().rejectCall(widget.call);
                              Navigator.pop(context);
                            },
                          ),
                          GlassCallActionButton(
                            icon:
                                isVideo
                                    ? Icons.videocam_rounded
                                    : Icons.call_rounded,
                            label: 'Accept',
                            color: Colors.green.shade600,
                            size: metrics.buttonSize,
                            emphasized: true,
                            onTap:
                                () => context.read<CallCubit>().acceptCall(
                                  widget.call,
                                ),
                          ),
                        ],
                      ),
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
}
