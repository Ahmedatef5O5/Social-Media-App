import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../core/themes/app_colors.dart';
import '../cubits/posts_cubit/posts_cubit.dart';
import '../helpers/dismissible_video_overlay.dart';
import '../helpers/draggable_progress_bar.dart';
import '../helpers/fade_dismiss_widget.dart';
import '../helpers/post_video_header_widget.dart';
import '../helpers/right_interactions_post_video_column.dart';
import '../helpers/shared_video_controller_handle.dart';
import '../helpers/top_and_bottom_overlays.dart';
import '../helpers/video_duration_display.dart';
import '../helpers/video_post_author_and_caption.dart';
import '../models/post_model.dart';

class FullScreenVideoPostView extends StatefulWidget {
  final PostModel post;
  final SharedVideoControllerHandle handle;
  final PostsCubit postsCubit;
  final String currentUserId;

  const FullScreenVideoPostView({
    super.key,
    required this.post,
    required this.handle,
    required this.postsCubit,
    required this.currentUserId,
  });

  @override
  State<FullScreenVideoPostView> createState() =>
      _FullScreenVideoPostViewState();
}

class _FullScreenVideoPostViewState extends State<FullScreenVideoPostView> {
  static const _autoHideDelay = Duration(seconds: 6);
  static const _fadeDuration = Duration(milliseconds: 250);

  static const double _rightColumnBottomWithCaption = 55;
  static const double _rightColumnBottomNoCaption = 48;

  bool _wasPlaying = false;
  double _dragOffset = 0.0;
  bool _isDragging = false;

  VideoPlayerController get _controller => widget.handle.controller;
  final ValueNotifier<bool> _showOverlays = ValueNotifier<bool>(true);
  Timer? _autoHideTimer;

  @override
  void initState() {
    super.initState();
    widget.handle.acquire();
    _controller.addListener(_handlePlaybackTick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.setVolume(1.0);
        if (!_controller.value.isPlaying) {
          _controller.play();
        }
        _startAutoHideTimer();
      }
    });
  }

  void _handlePlaybackTick() {
    final isPlaying = _controller.value.isPlaying;
    if (isPlaying && !_wasPlaying) {
      _startAutoHideTimer();
    } else if (!isPlaying && _wasPlaying) {
      _autoHideTimer?.cancel();
    }
    _wasPlaying = isPlaying;
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    _controller.removeListener(_handlePlaybackTick);
    _showOverlays.dispose();
    widget.handle.release();
    super.dispose();
  }

  void _startAutoHideTimer() {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(_autoHideDelay, () {
      if (mounted && _controller.value.isPlaying) {
        _showOverlays.value = false;
      }
    });
  }

  void _handleBodyTap() {
    if (_showOverlays.value) {
      _autoHideTimer?.cancel();
      _showOverlays.value = false;
    } else {
      _showOverlays.value = true;
      _startAutoHideTimer();
    }
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _isDragging = true;
      _dragOffset += details.primaryDelta!;
    });
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    if (_dragOffset.abs() > 150 ||
        details.velocity.pixelsPerSecond.dy.abs() > 300) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _isDragging = false;
        _dragOffset = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black.withValues(
        alpha: (1.0 - (_dragOffset.abs() / 500)).clamp(0.0, 1.0),
      ),
      body: GestureDetector(
        onVerticalDragUpdate: _handleVerticalDragUpdate,
        onVerticalDragEnd: _handleVerticalDragEnd,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Transform.translate(
              offset: Offset(0, _dragOffset),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildFullBleedVideo(),

                  IgnorePointer(
                    ignoring: _isDragging,
                    child: AnimatedOpacity(
                      opacity: _isDragging ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _generateCenterPlayPauseWidget(),
                          TopOverlays(
                            showOverlays: _showOverlays,
                            fadeDuration: _fadeDuration,
                          ),
                          BottomOverlays(),
                          SafeArea(
                            child: Stack(
                              children: [
                                PostVideoHeaderWidget(
                                  showOverlays: _showOverlays,
                                  fadeDuration: _fadeDuration,
                                  controller: _controller,
                                  context: context,
                                ),
                                _buildBottomInfoRow(context),
                                _buildRightColumn(),
                              ],
                            ),
                          ),
                          VideoDurationDisplay(
                            showOverlays: _showOverlays,
                            fadeDuration: _fadeDuration,
                            controller: _controller,
                          ),
                          _buildDraggableProgressBar(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullBleedVideo() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleBodyTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final size = _controller.value.size;
          if (!_controller.value.isInitialized || size.width == 0) {
            return const SizedBox.expand();
          }
          return SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _generateCenterPlayPauseWidget() {
    return Center(
      child: ValueListenableBuilder<bool>(
        valueListenable: _showOverlays,
        builder: (context, visible, _) {
          return AnimatedOpacity(
            opacity: visible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !visible,
              child: GestureDetector(
                onTap: () {
                  if (_controller.value.isPlaying) {
                    _controller.pause();
                    _autoHideTimer?.cancel();
                  } else {
                    _controller.play();
                    _startAutoHideTimer();
                  }
                  setState(() {});
                },
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, __) {
                    return Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                      child: Icon(
                        _controller.value.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRightColumn() {
    final bool hasCaption = widget.post.text.trim().isNotEmpty;

    return DismissibleVideoOverlay(
      listenable: _showOverlays,
      fadeDuration: _fadeDuration,
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: EdgeInsets.only(
          right: 14,
          bottom:
              hasCaption
                  ? _rightColumnBottomWithCaption
                  : _rightColumnBottomNoCaption,
        ),
        child: RightInteractionsPostVideoColumn(
          post: widget.post,
          postsCubit: widget.postsCubit,
          videoController: _controller,
        ),
      ),
    );
  }

  Widget _buildBottomInfoRow(BuildContext context) {
    return Positioned(
      left: 0,
      right: 90,
      bottom: 45,
      child: Padding(
        padding: const EdgeInsets.only(left: 14, right: 10),
        child: FadeDismissWidget(
          listenable: _showOverlays,
          fadeDuration: _fadeDuration,
          child: VideoPostAuthorAndCaption(
            context,
            post: widget.post,
            postsCubit: widget.postsCubit,
            currentUserId: widget.currentUserId,
            controller: _controller,
          ),
        ),
      ),
    );
  }

  Widget _buildDraggableProgressBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: ValueListenableBuilder<bool>(
          valueListenable: _showOverlays,
          builder: (context, visible, child) {
            return AnimatedContainer(
              duration: _fadeDuration,
              padding: EdgeInsets.only(bottom: visible ? 12.0 : 0.0),
              child: child,
            );
          },
          child: DraggableProgressBar(
            controller: _controller,
            showOverlays: _showOverlays,
            onScrubStart: () {
              _autoHideTimer?.cancel();
              if (!_showOverlays.value) _showOverlays.value = true;
            },
            onScrubEnd: _startAutoHideTimer,
          ),
        ),
      ),
    );
  }
}
