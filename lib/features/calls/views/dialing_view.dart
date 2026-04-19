import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/call_cubit.dart';
import '../model/call_model.dart';

class DialingView extends StatefulWidget {
  final CallModel call;

  const DialingView({super.key, required this.call});

  @override
  State<DialingView> createState() => _DialingViewState();
}

class _DialingViewState extends State<DialingView> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _playRingtone();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),

            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 3),
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

            const SizedBox(height: 24),

            Text(
              widget.call.receiverName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.call.type == CallType.video
                      ? Icons.videocam
                      : Icons.call,
                  color: Colors.white54,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.call.type == CallType.video
                      ? "Calling (Video)..."
                      : "Calling (Audio)...",
                  style: const TextStyle(color: Colors.white54, fontSize: 16),
                ),
              ],
            ),

            const Spacer(),

            Column(
              children: [
                GestureDetector(
                  onTap: () {
                    context.read<CallCubit>().endCall(widget.call.callId);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.call_end,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _defaultAvatar(String name) {
    return Container(
      color: Colors.grey.shade800,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
