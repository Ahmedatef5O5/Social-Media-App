import 'dart:async';
import 'dart:io';
import 'package:social_media_app/core/helpers/media_duration_badge.dart';
import 'package:social_media_app/core/widgets/cached_cloudinary_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/single_chats/helper/glass_icon_btn.dart';
import 'package:video_player/video_player.dart';
import '../../../core/cache/repository/media_cache_repository.dart';
import '../../../core/services/gallery_services.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../../../core/widgets/vertical_volume_indicator.dart';
import '../../../core/widgets/video_progress_slider.dart';

class FullScreenMediaView extends StatefulWidget {
  final String? imageUrl;
  final String? videoUrl;
  final String? caption;
  final bool isLocal;
  final bool showActions;
  final VideoPlayerController? controller;

  const FullScreenMediaView({
    super.key,
    this.imageUrl,
    this.videoUrl,
    this.caption,
    this.isLocal = false,
    this.showActions = true,
    this.controller,
  });

  @override
  State<FullScreenMediaView> createState() => _FullScreenMediaViewState();
}

class _FullScreenMediaViewState extends State<FullScreenMediaView>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _isExternalController = false;
  bool _showControls = true;
  double _playbackSpeed = 1.0;
  double _dragOffset = 0;
  double _lastNonZeroVolume = 1.0;

  final TransformationController _transformationController =
      TransformationController();

  static const double _volumeDragRangePixels = 260;
  final ValueNotifier<double> _volumeNotifier = ValueNotifier<double>(100);
  int _lastAppliedVolumePercent = -1;
  Timer? _volumeFadeTimer;
  late final AnimationController _volumeIndicatorController =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 250),
      );

  bool get _hasReadyVideo =>
      widget.videoUrl != null &&
      _videoController != null &&
      _videoController!.value.isInitialized;

  bool _showLeftSeek = false;
  bool _showRightSeek = false;
  Timer? _seekTimer;

  void _handleDoubleTapSeek(bool forward) {
    _seekRelative(Duration(seconds: forward ? 5 : -5));
    setState(() {
      if (forward) {
        _showRightSeek = true;
        _showLeftSeek = false;
      } else {
        _showLeftSeek = true;
        _showRightSeek = false;
      }
    });
    _seekTimer?.cancel();
    _seekTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showLeftSeek = false;
          _showRightSeek = false;
        });
      }
    });
  }

  void _changeSpeed() {
    setState(() {
      if (_playbackSpeed == 1.0) {
        _playbackSpeed = 1.5;
      } else if (_playbackSpeed == 1.5) {
        _playbackSpeed = 2.0;
      } else if (_playbackSpeed == 2.0) {
        _playbackSpeed = 0.5;
      } else {
        _playbackSpeed = 1.0;
      }
      _videoController?.setPlaybackSpeed(_playbackSpeed);
    });
  }

  void _seekRelative(Duration offset) {
    _videoController?.seekTo(_videoController!.value.position + offset);
  }

  void _toggleMute() {
    final controller = _videoController;
    if (controller == null) return;
    if (controller.value.volume > 0) {
      _lastNonZeroVolume = controller.value.volume;
      controller.setVolume(0);
      _volumeNotifier.value = 0;
    } else {
      final restored = _lastNonZeroVolume <= 0 ? 1.0 : _lastNonZeroVolume;
      controller.setVolume(restored);
      _volumeNotifier.value = restored * 100;
    }
    _lastAppliedVolumePercent = _volumeNotifier.value.round();
    _flashVolumeIndicator();
  }

  void _onVolumeDragUpdate(DragUpdateDetails details) {
    final controller = _videoController;
    if (controller == null) return;

    final delta = details.primaryDelta ?? 0;
    final changePercent = -delta / _volumeDragRangePixels * 100;
    final newValue = (_volumeNotifier.value + changePercent).clamp(0.0, 100.0);
    _volumeNotifier.value = newValue;

    final roundedPercent = newValue.round();
    if (roundedPercent != _lastAppliedVolumePercent) {
      _lastAppliedVolumePercent = roundedPercent;
      controller.setVolume(roundedPercent / 100);
      _lastNonZeroVolume =
          roundedPercent > 0 ? roundedPercent / 100 : _lastNonZeroVolume;
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
    _volumeFadeTimer?.cancel();
    _volumeFadeTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) _volumeIndicatorController.reverse();
    });
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _videoController = widget.controller;
      _isExternalController = true;
      _videoController!.addListener(_onControllerUpdate);
      _volumeNotifier.value = (_videoController!.value.volume * 100).clamp(
        0,
        100,
      );
      if (!_videoController!.value.isPlaying) {
        _videoController!.play();
      }
      _hideControlsAfterDelay();
    } else if (widget.videoUrl != null) {
      _initializeVideo(widget.videoUrl!);
    }
  }

  Future<void> _initializeVideo(String videoUrl) async {
    if (widget.isLocal) {
      _videoController = VideoPlayerController.file(File(videoUrl));
    } else {
      final localPath = await context
          .read<MediaCacheRepository>()
          .resolveLocalPath(videoUrl);
      _videoController =
          localPath != null
              ? VideoPlayerController.file(File(localPath))
              : VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    }
    await _videoController!.initialize();
    if (!mounted) return;

    _videoController!.addListener(_onControllerUpdate);
    _volumeNotifier.value = (_videoController!.value.volume * 100).clamp(
      0,
      100,
    );
    setState(() {});
    _videoController!.play();
    _hideControlsAfterDelay();
  }

  void _hideControlsAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && (_videoController?.value.isPlaying ?? false)) {
        setState(() => _showControls = false);
      }
    });
  }

  @override
  void dispose() {
    _seekTimer?.cancel();
    _videoController?.removeListener(_onControllerUpdate);
    if (!_isExternalController) {
      _videoController?.pause();
      _videoController?.dispose();
    }
    _volumeFadeTimer?.cancel();
    _volumeIndicatorController.dispose();
    _volumeNotifier.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else {
      _transformationController.value = Matrix4.identity()..scale(2.0);
    }
    setState(() {});
  }

  bool _isSaving = false;

  Future<void> _saveMediaToGallery() async {
    final url = widget.imageUrl ?? widget.videoUrl;
    if (url == null) return;
    setState(() => _isSaving = true);
    await GalleryServices.saveMediaToGallery(
      context: context,
      url: url,
      isVideo: widget.videoUrl != null,
    );
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final enableDismissDrag = widget.videoUrl == null;

    return GestureDetector(
      onScaleUpdate:
          enableDismissDrag
              ? (details) {
                if (_transformationController.value.getMaxScaleOnAxis() <=
                    1.0) {
                  setState(() => _dragOffset += details.focalPointDelta.dy);
                }
              }
              : null,
      onScaleEnd:
          enableDismissDrag
              ? (details) {
                if (_dragOffset.abs() > 150) {
                  Navigator.pop(context);
                } else {
                  setState(() => _dragOffset = 0);
                }
              }
              : null,
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() => _showControls = !_showControls);
        if (_showControls) _hideControlsAfterDelay();
      },
      child: Scaffold(
        backgroundColor: Colors.black.withValues(
          alpha: (.95 - (_dragOffset.abs() / 500)).clamp(0.0, 1.0),
        ),
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
          leadingWidth: _hasReadyVideo ? 100 : 56,
          leading: IgnorePointer(
            ignoring: _hasReadyVideo && !_showControls,
            child: AnimatedOpacity(
              opacity: (_hasReadyVideo && !_showControls) ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              child:
                  (_hasReadyVideo && widget.showActions)
                      ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const BackButton(color: Colors.white),
                          GlassIconButton(
                            size: 28,
                            iconSize: 15,
                            icon:
                                _videoController!.value.volume <= 0
                                    ? Icons.volume_off_rounded
                                    : _videoController!.value.volume < 0.5
                                    ? Icons.volume_down_rounded
                                    : Icons.volume_up_rounded,
                            onTap: _toggleMute,
                          ),
                        ],
                      )
                      : const BackButton(color: Colors.white),
            ),
          ),
          actions: [
            IgnorePointer(
              ignoring: _hasReadyVideo && !_showControls,
              child: AnimatedOpacity(
                opacity: (_hasReadyVideo && !_showControls) ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Row(
                  children: [
                    if (_hasReadyVideo && widget.showActions)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Center(
                          child: MediaDurationBadge(
                            seconds: _videoController!.value.duration.inSeconds,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (widget.showActions && widget.imageUrl != null)
              _isSaving
                  ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CustomLoadingIndicator(color: Colors.white),
                    ),
                  )
                  : PopupMenuButton<String>(
                    color: Colors.white,
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    offset: const Offset(-24, kToolbarHeight - 12),
                    onSelected: (value) {
                      if (value == 'save') _saveMediaToGallery();
                    },
                    itemBuilder:
                        (_) => [
                          const PopupMenuItem(
                            value: 'save',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.download,
                                  size: 18,
                                  color: Colors.black45,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Save to gallery',
                                  style: TextStyle(color: Colors.black45),
                                ),
                              ],
                            ),
                          ),
                        ],
                  ),
            if (widget.showActions && _hasReadyVideo && _showControls)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: TextButton(
                  onPressed: _changeSpeed,
                  child: Text(
                    "${_playbackSpeed}x",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: Stack(
          alignment: Alignment.center,
          children: [
            Transform.translate(
              offset: Offset(0, _dragOffset),
              child: _buildMainContent(),
            ),
            if (_hasReadyVideo) _buildVolumeGestureZone(),
            if (_hasReadyVideo) _buildVideoOverlay(),
            if (_hasReadyVideo) _buildVolumeIndicator(),
            if (widget.caption != null && widget.caption!.isNotEmpty)
              _buildCaption(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (widget.imageUrl != null) {
      return Center(
        child: GestureDetector(
          onDoubleTap: _handleDoubleTap,
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.5,
            maxScale: 4.0,
            child:
                widget.isLocal
                    ? Image.file(File(widget.imageUrl!), fit: BoxFit.contain)
                    : CachedCloudinaryImage(
                      secureUrl: widget.imageUrl!,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (context) => const CustomLoadingIndicator(),
                      errorWidget:
                          (context, error) => const Icon(
                            Icons.broken_image,
                            color: Colors.white,
                            size: 50,
                          ),
                    ),
          ),
        ),
      );
    } else if (_videoController != null &&
        _videoController!.value.isInitialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
      );
    }
    return const CustomLoadingIndicator();
  }

  Widget _buildVolumeGestureZone() {
    return Positioned.fill(
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
    );
  }

  Widget _buildVolumeIndicator() {
    return Positioned(
      left: 28,
      top: 0,
      bottom: 0,
      child: Center(
        child: FadeTransition(
          opacity: _volumeIndicatorController,
          child: IgnorePointer(
            child: VerticalVolumeIndicator(
              volume: _volumeNotifier,
              opacity: _volumeIndicatorController,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoOverlay() {
    return Stack(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onDoubleTap: () => _handleDoubleTapSeek(false),
                child:
                    _showLeftSeek
                        ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          alignment: Alignment.center,
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.fast_rewind_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                              SizedBox(height: 8),
                              Text(
                                '-5 sec',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                        : const SizedBox.expand(),
              ),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onDoubleTap: () => _handleDoubleTapSeek(true),
                child:
                    _showRightSeek
                        ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          alignment: Alignment.center,
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.fast_forward_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                              SizedBox(height: 8),
                              Text(
                                '+5 sec',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                        : const SizedBox.expand(),
              ),
            ),
          ],
        ),

        IgnorePointer(
          ignoring: !_showControls,
          child: AnimatedOpacity(
            opacity: _showControls ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Stack(
              children: [
                Container(color: Colors.black38),
                Center(
                  child: GlassIconButton(
                    icon:
                        _videoController!.value.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                    size: 58,
                    iconSize: 30,
                    onTap: () {
                      _videoController!.value.isPlaying
                          ? _videoController!.pause()
                          : _videoController!.play();
                      _hideControlsAfterDelay();
                    },
                  ),
                ),
                Positioned(
                  bottom: 24,
                  left: 20,
                  right: 20,
                  child: Column(
                    children: [
                      VideoProgressSlider(controller: _videoController!),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTimeText(_videoController!.value.position),
                          _buildTimeText(
                            _videoController!.value.duration,
                            isUnknown:
                                _videoController!.value.duration <=
                                Duration.zero,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeText(Duration duration, {bool isUnknown = false}) {
    if (isUnknown) {
      return const Text(
        '--:--',
        style: TextStyle(color: Colors.white, fontSize: 12),
      );
    }
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return Text(
      "$minutes:$seconds",
      style: const TextStyle(color: Colors.white, fontSize: 12),
    );
  }

  Widget _buildCaption() {
    return Positioned(
      bottom: widget.videoUrl != null ? 90 : 40,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Text(
          widget.caption!,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
