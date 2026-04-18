import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../../home/cubits/home_cubit/home_cubit.dart';

class AddStoryPreviewView extends StatefulWidget {
  final File file;
  final bool isVideo;
  final Duration? videoDuration;
  final HomeCubit homeCubit;

  const AddStoryPreviewView({
    super.key,
    required this.file,
    required this.isVideo,
    this.videoDuration,
    required this.homeCubit,
  });

  @override
  State<AddStoryPreviewView> createState() => _AddStoryPreviewViewState();
}

class _AddStoryPreviewViewState extends State<AddStoryPreviewView> {
  final TextEditingController _captionController = TextEditingController();

  VideoPlayerController? _videoController;
  bool _videoInitialised = false;
  bool _videoError = false;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) _initVideoController();
  }

  Future<void> _initVideoController() async {
    try {
      final controller = VideoPlayerController.file(widget.file);
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      _videoController = controller;
      controller.setLooping(true);
      controller.play();
      setState(() {
        _videoInitialised = true;
        _isPlaying = true;
      });
    } catch (_) {
      if (mounted) setState(() => _videoError = true);
    }
  }

  void _togglePlayPause() {
    if (_videoController == null) return;
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _isPlaying = false;
      } else {
        _videoController!.play();
        _isPlaying = true;
      }
    });
  }

  void _shareStory(BuildContext context, HomeCubit cubit) {
    final caption =
        _captionController.text.trim().isEmpty
            ? null
            : _captionController.text.trim();

    if (widget.isVideo) {
      cubit.addVideoStoryWithCaption(
        file: widget.file,
        user: cubit.currentUserData!,
        caption: caption,
      );
    } else {
      cubit.addStoryWithCaption(
        file: widget.file,
        user: cubit.currentUserData!,
        caption: caption,
      );
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.homeCubit,
      child: BlocConsumer<HomeCubit, HomeState>(
        listener: (context, state) {
          if (state is AddStorySuccess) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Story added successfully!',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall!.copyWith(color: AppColors.white),
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (state is AddStoryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AddStoryLoading;

          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Scaffold(
              backgroundColor: Colors.black,
              appBar: _buildAppBar(context, isLoading),
              body: Stack(
                children: [
                  // ── Media preview ──────────────────────────────────────
                  Positioned.fill(child: _buildMediaPreview()),

                  // ── Duration badge (video only) ────────────────────────
                  if (widget.isVideo && widget.videoDuration != null)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _DurationBadge(duration: widget.videoDuration!),
                    ),

                  // ── Play/Pause overlay (video only) ────────────────────
                  if (widget.isVideo && _videoInitialised)
                    Center(
                      child: GestureDetector(
                        onTap: _togglePlayPause,
                        child: AnimatedOpacity(
                          opacity: _isPlaying ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // ── Caption field ──────────────────────────────────────
                  Positioned(
                    bottom: 30,
                    left: 16,
                    right: 16,
                    child: _buildCaptionField(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, bool isLoading) {
    return AppBar(
      backgroundColor: Colors.black,
      leading: IconButton(
        icon: const Icon(Icons.close, color: AppColors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.isVideo ? 'Video Preview' : 'Photo Preview',
        style: const TextStyle(color: AppColors.white, fontSize: 16),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: TextButton(
            onPressed:
                isLoading ? null : () => _shareStory(context, widget.homeCubit),
            child:
                isLoading
                    ? const CustomLoadingIndicator(
                      radius: 10,
                      color: AppColors.white,
                    )
                    : Text(
                      'Share',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium!.copyWith(
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.95),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaPreview() {
    if (!widget.isVideo) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(widget.file, fit: BoxFit.contain),
      );
    }

    if (_videoError) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 12),
            Text(
              'Could not load video',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (!_videoInitialised) {
      return const Center(
        child: CustomLoadingIndicator(color: AppColors.white),
      );
    }

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Center(
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
      ),
    );
  }

  Widget _buildCaptionField() {
    return TextField(
      controller: _captionController,
      style: const TextStyle(color: AppColors.white),
      maxLines: 3,
      minLines: 1,
      maxLength: 150,
      decoration: InputDecoration(
        hintText: 'Add a caption...',
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.black54,
        counterStyle: const TextStyle(color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// ── Helper widget ────────────────────────────────────────────────────────────

class _DurationBadge extends StatelessWidget {
  final Duration duration;

  const _DurationBadge({required this.duration});

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam_outlined, color: Colors.white70, size: 14),
          const SizedBox(width: 4),
          Text(
            _format(duration),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
