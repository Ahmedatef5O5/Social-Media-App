import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/design/tokens/typography.dart';
import 'package:social_media_app/core/helpers/emoji_helper.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/core/widgets/cached_cloudinary_image.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import 'package:social_media_app/features/posts/cubits/posts_cubit/posts_cubit.dart';
import 'package:social_media_app/features/posts/models/post_model.dart';
import 'package:social_media_app/features/posts/widgets/post_interactions_row.dart';
import 'package:social_media_app/features/posts/widgets/post_txt_content_widget.dart';
import '../helpers/safe_navigator.dart';
import '../services/gallery_services.dart';

class FullScreenImageViewer extends StatefulWidget {
  const FullScreenImageViewer({super.key});

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  final TransformationController _transformationController =
      TransformationController();

  double _dragOffset = 0;
  bool _isSaving = false;
  bool _isZoomed = false;

  /// Toggled by a single tap on the image (only wired when the viewer is
  /// showing a Post's image, i.e. `postId != null`). Hides/shows the header,
  /// caption and PostInteractionsRow together, leaving just the image.
  bool _overlaysHidden = false;

  final _closeGuard = SingleFireGuard();

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_handleTransformChanged);
  }

  void _handleTransformChanged() {
    final bool zoomed =
        _transformationController.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _isZoomed) {
      setState(() => _isZoomed = zoomed);
    }
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else {
      _transformationController.value = Matrix4.identity()..scale(2.0);
    }
    setState(() {});
  }

  /// Single-tap toggle for all chrome (header / caption / interactions row).
  /// Only ever wired to `onTap` alongside `onDoubleTap` on the SAME
  /// GestureDetector, so Flutter's own tap-vs-double-tap disambiguation
  /// (~300ms `kDoubleTapTimeout`) keeps this from ever firing on a double
  /// tap meant for zoom — no manual debouncing needed.
  void _toggleAllOverlays() {
    setState(() => _overlaysHidden = !_overlaysHidden);
  }

  void _close() {
    if (_closeGuard.tryFire()) {
      context.safePop();
    }
  }

  @override
  void dispose() {
    _transformationController.removeListener(_handleTransformChanged);
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    final String imageUrl = args['url'];
    final String heroTag = args['tag'] ?? imageUrl;
    final bool isAsset = args['isAsset'] ?? false;
    final bool isLocalFile = args['isLocalFile'] ?? false;
    final String? staticCaption = args['caption'];
    final String? postId = args['postId'] as String?;

    final bool headerVisible = _dragOffset == 0 && !_overlaysHidden;
    final bool showBottomOverlays =
        postId != null && _dragOffset == 0 && !_isZoomed && !_overlaysHidden;

    return GestureDetector(
      onScaleUpdate: (details) {
        if (_transformationController.value.getMaxScaleOnAxis() <= 1.0) {
          setState(() {
            _dragOffset += details.focalPointDelta.dy;
          });
        }
      },

      onScaleEnd: (details) {
        final velocity = details.velocity.pixelsPerSecond.dy;

        if (_dragOffset.abs() > 100 || velocity.abs() > 250) {
          _close();
        } else {
          setState(() {
            _dragOffset = 0;
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.black.withValues(
          alpha: (1.0 - (_dragOffset.abs() / 500)).clamp(0.0, 1.0),
        ),
        body: Stack(
          alignment: Alignment.center,
          children: [
            SafeArea(
              child: Column(
                children: [
                  IgnorePointer(
                    ignoring: !headerVisible,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: headerVisible ? 1.0 : 0.0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.close,
                                color: AppColors.white,
                                size: 28,
                              ),
                            ),

                            if (!isAsset && !isLocalFile)
                              _isSaving
                                  ? const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CustomLoadingIndicator(
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                  : PopupMenuButton<String>(
                                    color: Colors.white,
                                    icon: const Icon(
                                      Icons.more_vert,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                    offset: const Offset(
                                      -24,
                                      kToolbarHeight - 12,
                                    ),
                                    onSelected: (value) async {
                                      if (value == 'save') {
                                        setState(() => _isSaving = true);

                                        await GalleryServices.saveMediaToGallery(
                                          context: context,
                                          url: imageUrl,
                                          isVideo: false,
                                        );

                                        if (mounted) {
                                          setState(() => _isSaving = false);
                                        }
                                      }
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
                                                  style: TextStyle(
                                                    color: Colors.black45,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Transform.translate(
                        offset: Offset(0, _dragOffset),
                        child: GestureDetector(
                          onTap: postId != null ? _toggleAllOverlays : null,
                          onDoubleTap: _handleDoubleTap,
                          child: InteractiveViewer(
                            transformationController: _transformationController,
                            clipBehavior: Clip.none,
                            minScale: 1.0,
                            maxScale: 4.0,
                            child: Hero(
                              tag: heroTag,
                              child:
                                  isAsset
                                      ? Image.asset(
                                        imageUrl,
                                        fit: BoxFit.contain,
                                        width: double.infinity,
                                      )
                                      : isLocalFile
                                      ? Image.file(
                                        File(imageUrl),
                                        fit: BoxFit.contain,
                                        width: double.infinity,
                                      )
                                      : CachedCloudinaryImage(
                                        secureUrl: imageUrl,
                                        fit: BoxFit.contain,
                                        width: double.infinity,
                                      ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Gap(postId != null ? 100 : 20),
                ],
              ),
            ),

            // Legacy static caption — only for viewer usages with NO postId
            // (e.g. chat attachment / local file preview). Left completely
            // untouched by the new drag/zoom/tap-to-hide behavior below,
            // since those only apply to the Post-image path.
            if (postId == null &&
                staticCaption != null &&
                staticCaption.isNotEmpty)
              Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  child: Text(
                    EmojiHelper.normalize(staticCaption),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      fontFamily: null,
                      fontFamilyFallback: AppTypography.fontFallback,
                    ),
                  ),
                ),
              ),

            // Post-image path: caption + PostInteractionsRow, grouped as ONE
            // unit, sharing the exact same visibility lifecycle (drag / zoom
            // / tap-to-hide-overlays).
            if (postId != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  offset: showBottomOverlays ? Offset.zero : const Offset(0, 1),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: showBottomOverlays ? 1.0 : 0.0,
                    child: IgnorePointer(
                      ignoring: !showBottomOverlays,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.85),
                              Colors.black.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.only(top: 28),
                        child: SafeArea(
                          top: false,
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              textTheme: Theme.of(context).textTheme.apply(
                                bodyColor: Colors.white,
                                displayColor: Colors.white,
                              ),
                              colorScheme: Theme.of(
                                context,
                              ).colorScheme.copyWith(outline: Colors.white70),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _ViewerPostCaption(postId: postId),
                                PostInteractionsRow(postId: postId),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Renders the SAME caption widget used in the feed (`PostTxtContentWidget`
/// — direction detection, mentions, links, see more/less), sourced live from
/// `PostsCubit` (not a static route arg) so edits/updates stay in sync while
/// the viewer is open. Renders nothing if the post can't be found or has no
/// caption text (PostTxtContentWidget itself collapses to SizedBox.shrink).
class _ViewerPostCaption extends StatelessWidget {
  const _ViewerPostCaption({required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostsCubit, PostsState>(
      buildWhen: (previous, current) {
        if (previous is PostsLoaded && current is PostsLoaded) {
          final oldPost = previous.posts.findById(postId);
          final newPost = current.posts.findById(postId);
          return oldPost?.text != newPost?.text ||
              oldPost?.mentions.length != newPost?.mentions.length;
        }
        return true;
      },
      builder: (context, state) {
        final PostModel? livePost =
            state is PostsLoaded ? state.posts.findById(postId) : null;

        if (livePost == null) return const SizedBox.shrink();

        return PostTxtContentWidget(post: livePost);
      },
    );
  }
}
