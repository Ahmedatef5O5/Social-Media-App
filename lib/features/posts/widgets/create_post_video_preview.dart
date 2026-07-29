import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../core/attachment/widgets/transfer_ring.dart';
import '../../../core/utilities/file_size_formatter.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../../../core/widgets/vertical_volume_indicator.dart';
import '../../../core/widgets/video_progress_slider.dart';
import '../../single_chats/helper/glass_icon_btn.dart';
import '../../single_chats/widgets/full_screen_media_view.dart';

class CreatePostVideoPreview extends StatefulWidget {
  final String videoPath;
  final int? fileSizeBytes;
  final VoidCallback onRemove;

  const CreatePostVideoPreview({
    super.key,
    required this.videoPath,
    this.fileSizeBytes,
    required this.onRemove,
  });

  @override
  State<CreatePostVideoPreview> createState() => _CreatePostVideoPreviewState();
}

class _CreatePostVideoPreviewState extends State<CreatePostVideoPreview>
    with SingleTickerProviderStateMixin {
  late final VideoPlayerController _controller;
  bool _isInitialized = false;

  static const double _volumeDragRangePixels = 200;
  final ValueNotifier<double> _volumeNotifier = ValueNotifier<double>(100);
  int _lastAppliedVolumePercent = -1;
  double _lastNonZeroVolume = 1.0;
  Timer? _volumeFadeTimer;
  late final AnimationController _volumeIndicatorController =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 250),
      );

  @override
  void initState() {
    super.initState();
    _controller =
        VideoPlayerController.file(File(widget.videoPath))
          ..addListener(_onControllerUpdate)
          ..initialize().then((_) {
            if (!mounted) return;
            setState(() => _isInitialized = true);
          });
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _volumeFadeTimer?.cancel();
    _volumeIndicatorController.dispose();
    _volumeNotifier.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    _controller.value.isPlaying ? _controller.pause() : _controller.play();
  }

  void _toggleMute() {
    if (_controller.value.volume > 0) {
      _lastNonZeroVolume = _controller.value.volume;
      _controller.setVolume(0);
      _volumeNotifier.value = 0;
    } else {
      final restored = _lastNonZeroVolume <= 0 ? 1.0 : _lastNonZeroVolume;
      _controller.setVolume(restored);
      _volumeNotifier.value = restored * 100;
    }
    _lastAppliedVolumePercent = _volumeNotifier.value.round();
    _flashVolumeIndicator();
  }

  void _onVolumeDragUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta ?? 0;
    final changePercent = -delta / _volumeDragRangePixels * 100;
    final newValue = (_volumeNotifier.value + changePercent).clamp(0.0, 100.0);
    _volumeNotifier.value = newValue;

    final rounded = newValue.round();
    if (rounded != _lastAppliedVolumePercent) {
      _lastAppliedVolumePercent = rounded;
      _controller.setVolume(rounded / 100);
      if (rounded > 0) _lastNonZeroVolume = rounded / 100;
    }
    _flashVolumeIndicator();
  }

  void _flashVolumeIndicator() {
    _volumeFadeTimer?.cancel();
    if (_volumeIndicatorController.status != AnimationStatus.completed) {
      _volumeIndicatorController.forward();
    }
  }

  void _onVolumeDragEnd(DragEndDetails details) {
    _volumeFadeTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) _volumeIndicatorController.reverse();
    });
  }

  void _openFullScreen() {
    Navigator.of(context, rootNavigator: true)
        .push(
          MaterialPageRoute(
            builder:
                (_) => FullScreenMediaView(
                  videoUrl: widget.videoPath,
                  isLocal: true,
                  controller: _controller,
                  showActions: false,
                ),
          ),
        )
        .then((_) {
          if (mounted) setState(() {});
        });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.black,
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: _isInitialized ? _controller.value.aspectRatio : 16 / 9,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 8,
              left: 50,
              child: GlassPillBadge(
                leading: const Icon(
                  Icons.videocam_outlined,
                  size: 14,
                  color: Colors.white,
                ),
                caption: formatMediaFileSize(widget.fileSizeBytes),
              ),
            ),
            if (_isInitialized)
              VideoPlayer(_controller)
            else
              const CustomLoadingIndicator(),

            if (_isInitialized)
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  color: Colors.transparent,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: _controller.value.isPlaying ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: GlassIconButton(
                        size: 60,
                        iconSize: 32,
                        icon:
                            _controller.value.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                        onTap: _togglePlayPause,
                      ),
                    ),
                  ),
                ),
              ),

            if (_isInitialized)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: 0.5,
                    heightFactor: 1,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onVerticalDragUpdate: _onVolumeDragUpdate,
                      onVerticalDragEnd: _onVolumeDragEnd,
                    ),
                  ),
                ),
              ),

            if (_isInitialized)
              Positioned(
                left: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: VerticalVolumeIndicator(
                    volume: _volumeNotifier,
                    opacity: _volumeIndicatorController,
                  ),
                ),
              ),

            Positioned(
              top: 8,
              left: 8,
              child: GlassIconButton(
                size: 34,
                iconSize: 16,
                icon:
                    !_isInitialized
                        ? Icons.volume_up_rounded
                        : _controller.value.volume <= 0
                        ? Icons.volume_off_rounded
                        : _controller.value.volume < 0.5
                        ? Icons.volume_down_rounded
                        : Icons.volume_up_rounded,
                onTap: _isInitialized ? _toggleMute : null,
              ),
            ),

            Positioned(
              top: 8,
              right: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GlassIconButton(
                    size: 34,
                    iconSize: 16,
                    icon: Icons.fullscreen_rounded,
                    onTap: _isInitialized ? _openFullScreen : null,
                  ),
                  const SizedBox(width: 8),
                  GlassIconButton(
                    size: 34,
                    iconSize: 16,
                    icon: Icons.close_rounded,
                    onTap: widget.onRemove,
                  ),
                ],
              ),
            ),

            if (_isInitialized)
              Positioned(
                bottom: 6,
                left: 10,
                right: 10,
                child: VideoProgressSlider(controller: _controller),
              ),
          ],
        ),
      ),
    );
  }
}
