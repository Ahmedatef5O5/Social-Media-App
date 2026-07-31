import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'playback_time_display.dart';

class DraggableProgressBar extends StatefulWidget {
  final VideoPlayerController controller;
  final ValueListenable<bool> showOverlays;
  final VoidCallback onScrubStart;
  final VoidCallback onScrubEnd;

  const DraggableProgressBar({
    super.key,
    required this.controller,
    required this.showOverlays,
    required this.onScrubStart,
    required this.onScrubEnd,
  });

  @override
  State<DraggableProgressBar> createState() => _DraggableProgressBarState();
}

class _DraggableProgressBarState extends State<DraggableProgressBar> {
  static const double _thinHeight = 1.5;
  static const double _thickHeight = 4.0;
  static const double _hitTargetHeight = 28.0;
  static const double _dotSize = 12.0;

  bool _isDragging = false;
  Duration _dragPosition = Duration.zero;
  bool _wasPlayingBeforeDrag = false;

  Duration get _duration => widget.controller.value.duration;

  double _fractionFromDx(double dx, double width) {
    if (width <= 0) return 0;
    return (dx / width).clamp(0.0, 1.0);
  }

  void _handleDragStart(DragStartDetails details, double width) {
    if (_duration == Duration.zero) return;
    _wasPlayingBeforeDrag = widget.controller.value.isPlaying;
    widget.controller.pause();
    setState(() {
      _isDragging = true;
      _dragPosition = widget.controller.value.position;
    });
    widget.onScrubStart();
  }

  void _handleDragUpdate(DragUpdateDetails details, double width) {
    if (_duration == Duration.zero) return;
    final fraction = _fractionFromDx(details.localPosition.dx, width);
    setState(() => _dragPosition = _duration * fraction);
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_duration == Duration.zero) return;
    widget.controller.seekTo(_dragPosition);
    if (_wasPlayingBeforeDrag) widget.controller.play();
    setState(() => _isDragging = false);
    widget.onScrubEnd();
  }

  void _handleTapSeek(TapUpDetails details, double width) {
    if (_duration == Duration.zero) return;
    final fraction = _fractionFromDx(details.localPosition.dx, width);
    widget.controller.seekTo(_duration * fraction);
    widget.onScrubStart();
    widget.onScrubEnd();
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) d = Duration.zero;
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    final ss = seconds.toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:$ss';
    }
    return '$minutes:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (d) => _handleDragStart(d, width),
          onHorizontalDragUpdate: (d) => _handleDragUpdate(d, width),
          onHorizontalDragEnd: _handleDragEnd,
          onTapUp: (d) => _handleTapSeek(d, width),
          child: SizedBox(
            height: _hitTargetHeight,
            width: width,
            child: ValueListenableBuilder<bool>(
              valueListenable: widget.showOverlays,
              builder: (context, overlaysVisible, _) {
                final bool active = _isDragging || overlaysVisible;
                final double barHeight = active ? _thickHeight : _thinHeight;

                return AnimatedBuilder(
                  animation: widget.controller,
                  builder: (context, __) {
                    final duration = _duration;
                    final position =
                        _isDragging
                            ? _dragPosition
                            : widget.controller.value.position;

                    final durationMs = duration.inMilliseconds;
                    final positionMs = position.inMilliseconds;

                    final fraction =
                        durationMs > 0
                            ? (positionMs / durationMs).clamp(0.0, 1.0)
                            : 0.0;

                    final dotLeft = (fraction * width - _dotSize / 2).clamp(
                      0.0,
                      width - _dotSize,
                    );

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            height: barHeight,
                            child: Stack(
                              children: [
                                Container(
                                  color: Colors.white.withValues(
                                    alpha: active ? 0.24 : 0.15,
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: fraction,
                                  child: Container(
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (active)
                          Positioned(
                            left: dotLeft,
                            bottom: (barHeight / 2) - (_dotSize / 2),
                            child: Container(
                              width: _dotSize,
                              height: _dotSize,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black45,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),

                        if (_isDragging)
                          Positioned(
                            left: (dotLeft - 30).clamp(0.0, width - 90),
                            bottom: _hitTargetHeight + 6,
                            child: PlaybackTimeDisplay(
                              text:
                                  '${_formatDuration(position)} / ${_formatDuration(duration)}',
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
