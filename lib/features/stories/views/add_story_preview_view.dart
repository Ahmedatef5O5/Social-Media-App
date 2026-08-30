import 'dart:io';
import 'package:flutter/material.dart';
import 'package:social_media_app/features/social_graph/helpers/privacy_picker_helper.dart';
import 'package:social_media_app/features/social_graph/views/audience_picker_view.dart';
import 'package:social_media_app/features/social_graph/widgets/privacy_chip.dart';
import 'package:video_player/video_player.dart';
import 'package:social_media_app/features/auth/data/models/user_data.dart';
import '../../../core/helpers/safe_navigator.dart';
import '../../../core/mentions/widgets/mention_aware_text_field.dart';
import '../../../core/mentions/widgets/mention_text_editing_controller.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../../ai_assistant/entities/ai_action_type.dart';
import '../../ai_assistant/entities/ai_request_context.dart';
import '../../ai_assistant/widgets/ai_action_icon.dart';
import '../../settings/repository/settings_repository.dart';
import '../../social_graph/models/content_privacy.dart';
import '../cubits/stories_cubit/stories_cubit.dart';

class AddStoryPreviewView extends StatefulWidget {
  final File file;
  final bool isVideo;
  final Duration? videoDuration;
  final StoriesCubit storiesCubit;
  final UserData currentUser;

  const AddStoryPreviewView({
    super.key,
    required this.file,
    required this.isVideo,
    this.videoDuration,
    required this.storiesCubit,
    required this.currentUser,
  });

  @override
  State<AddStoryPreviewView> createState() => _AddStoryPreviewViewState();
}

class _AddStoryPreviewViewState extends State<AddStoryPreviewView> {
  final _shareGuard = SingleFireGuard();
  final MentionTextEditingController _captionController =
      MentionTextEditingController();
  final FocusNode _captionFocusNode = FocusNode();

  VideoPlayerController? _videoController;
  bool _videoInitialised = false;
  bool _videoError = false;
  bool _isPlaying = true;

  late ContentPrivacy _selectedPrivacy =
      SettingsRepository.instance.defaultStoryPrivacy;
  Set<String> _selectedViewerIds = {};

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

  Future<void> _pickPrivacy() async {
    final result = await pickContentPrivacy(
      context,
      currentPrivacy: _selectedPrivacy,
      currentViewerIds: _selectedViewerIds,
    );
    if (result == null) return;
    if (!mounted) return;
    setState(() {
      _selectedPrivacy = result.privacy;
      _selectedViewerIds = result.allowedViewerIds;
    });
  }

  Future<void> _shareStory(BuildContext context, StoriesCubit cubit) async {
    if (!_shareGuard.tryFire()) return;
    FocusScope.of(context).unfocus();

    final caption =
        _captionController.text.trim().isEmpty
            ? null
            : _captionController.text.trim();
    final mentions = _captionController.validMentions;

    if (_selectedPrivacy == ContentPrivacy.private &&
        _selectedViewerIds.isEmpty) {
      final selected = await Navigator.of(
        context,
        rootNavigator: true,
      ).push<Set<String>>(
        MaterialPageRoute(builder: (_) => const AudiencePickerView()),
      );
      if (selected == null || selected.isEmpty) {
        _shareGuard.reset();
        return;
      }
      if (!context.mounted) return;
      setState(() => _selectedViewerIds = selected);
    }

    if (_videoController != null && _videoController!.value.isPlaying) {
      _videoController!.pause();
    }

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (widget.isVideo) {
      cubit.addVideoStoryWithCaption(
        file: widget.file,
        user: widget.currentUser,
        caption: caption,
        mentions: mentions,
        videoDuration: widget.videoDuration,
        privacy: _selectedPrivacy,
        allowedViewerIds: _selectedViewerIds.toList(),
      );
    } else {
      cubit.addStoryWithCaption(
        file: widget.file,
        user: widget.currentUser,
        caption: caption,
        mentions: mentions,
        privacy: _selectedPrivacy,
        allowedViewerIds: _selectedViewerIds.toList(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: _buildAppBar(context),
        body: Stack(
          children: [
            Positioned.fill(child: _buildMediaPreview()),

            if (widget.isVideo && widget.videoDuration != null)
              Positioned(
                top: 12,
                right: 12,
                child: _DurationBadge(duration: widget.videoDuration!),
              ),

            if (widget.isVideo && _videoInitialised)
              Center(
                child: GestureDetector(
                  onTap: _togglePlayPause,
                  child: AnimatedOpacity(
                    opacity: _isPlaying ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
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

            Positioned(
              bottom: 20,
              left: 12,
              right: 12,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: _buildCaptionField()),
                  const SizedBox(width: 8),
                  Container(
                    margin: const EdgeInsets.only(bottom: 2),
                    child: ElevatedButton(
                      onPressed:
                          () => _shareStory(context, widget.storiesCubit),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'Share',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
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

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black,
      leading: IconButton(
        icon: const Icon(Icons.close, color: AppColors.white),
        onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
      ),
      title: Text(
        widget.isVideo ? 'Video Preview' : 'Photo Preview',
        style: const TextStyle(color: AppColors.white, fontSize: 16),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: PrivacyChip(privacy: _selectedPrivacy, onTap: _pickPrivacy),
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
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _captionController,
      builder: (context, value, child) {
        final int length = value.text.length;
        final bool hasText = length > 0;

        return Stack(
          children: [
            MentionAwareTextField(
              controller: _captionController,
              focusNode: _captionFocusNode,
              enabled: true,
              hintText: 'Add a caption...',
              style: const TextStyle(color: AppColors.white),
              maxLines: 3,
              minLines: 1,
              maxLength: 150,
              decoration: InputDecoration(
                hintText: 'Add a caption...',
                hintStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.black54,
                counterText: '',
                contentPadding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 10,
                  bottom: hasText ? 24 : 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: AiActionIcon(
                  controller: _captionController,
                  surface: AiSurfaceType.story,
                  generationAction: AiActionType.autocompleteCaption,
                  actionContext: AiActionContext.storyCreation,
                  hasMediaAttached: true,
                  targetMediaType:
                      widget.isVideo
                          ? AiTargetMediaType.video
                          : AiTargetMediaType.image,
                  imageBytesProvider:
                      widget.isVideo ? null : () => widget.file.readAsBytes(),
                ),
              ),
            ),

            if (hasText)
              Positioned(
                bottom: 8,
                right: 16,
                child: Text(
                  '$length/150',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

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
