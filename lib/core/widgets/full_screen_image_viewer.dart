import 'dart:io';
import 'package:social_media_app/core/widgets/cached_cloudinary_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
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
  final _closeGuard = SingleFireGuard();

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else {
      _transformationController.value = Matrix4.identity()..scale(2.0);
    }
    setState(() {});
  }

  void _close() {
    if (_closeGuard.tryFire()) {
      context.safePop();
    }
  }

  @override
  void dispose() {
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
    final String? caption = args['caption'];
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
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _dragOffset == 0 ? 1.0 : 0.0,
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
                  Expanded(
                    child: Center(
                      child: Transform.translate(
                        offset: Offset(0, _dragOffset),
                        child: GestureDetector(
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
                  const Gap(20),
                ],
              ),
            ),
            if (caption != null && caption.isNotEmpty)
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
                    caption,
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
              ),
          ],
        ),
      ),
    );
  }
}
