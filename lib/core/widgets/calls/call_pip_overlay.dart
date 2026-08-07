import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livekit_client/livekit_client.dart';
import '../../services/active_call/call_navigation_helper.dart';
import '../../services/active_call/cubit/active_call_session_cubit.dart';
import '../../services/active_call/pip/call_pip_cubit.dart';
import '../../services/active_call/pip/call_pip_state.dart';

class CallPipOverlay extends StatefulWidget {
  const CallPipOverlay({super.key});

  @override
  State<CallPipOverlay> createState() => _CallPipOverlayState();
}

class _CallPipOverlayState extends State<CallPipOverlay> {
  Offset? _position;
  static const _bubbleWidth = 120.0;
  static const _bubbleHeight = 160.0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CallPipCubit, CallPipState>(
      builder: (context, pip) {
        if (!pip.isMinimized || pip.room == null || !pip.isVideo) {
          return const SizedBox.shrink();
        }

        final screenSize = MediaQuery.of(context).size;
        _position ??= Offset(
          screenSize.width - _bubbleWidth - 16,
          screenSize.height * 0.35,
        );

        return Positioned(
          left: _position!.dx,
          top: _position!.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                final next = _position! + details.delta;
                _position = Offset(
                  next.dx.clamp(0, screenSize.width - _bubbleWidth),
                  next.dy.clamp(0, screenSize.height - _bubbleHeight),
                );
              });
            },
            onTap: () {
              // Tapping the bubble must ONLY maximize — never touch the
              // connection. Mirrors ActiveCallHeaderWidget's expand logic
              // via the shared helper so both stay in sync.
              final session = context.read<ActiveCallSessionCubit>().state;
              if (session == null) return;
              CallNavigationHelper.expandActiveCall(
                context.read<CallPipCubit>(),
                session,
              );
            },
            child: Material(
              elevation: 10,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: _bubbleWidth,
                height: _bubbleHeight,
                child:
                    pip.previewTrack != null
                        ? VideoTrackRenderer(pip.previewTrack!)
                        : Container(
                          color: Colors.black87,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.videocam_off_rounded,
                            color: Colors.white54,
                          ),
                        ),
              ),
            ),
          ),
        );
      },
    );
  }
}
