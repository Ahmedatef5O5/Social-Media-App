import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/themes/app_colors.dart';

class FullScreenImageViewer extends StatefulWidget {
  const FullScreenImageViewer({super.key});

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  final TransformationController _transformationController =
      TransformationController();

  double _dragOffset = 0;

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else {
      _transformationController.value = Matrix4.identity()..scale(2.0);
    }
    setState(() {});
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
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (_transformationController.value.getMaxScaleOnAxis() <= 1.0) {
          setState(() {
            _dragOffset += details.delta.dy;
          });
        }
      },

      onVerticalDragEnd: (details) {
        if (_dragOffset.abs() > 150 ||
            details.velocity.pixelsPerSecond.dy.abs() > 800) {
          Navigator.pop(context);
        } else {
          setState(() {
            _dragOffset = 0;
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.black.withValues(
          alpha: (.95 - (_dragOffset.abs() / 500)).clamp(0.0, 1.0),
        ),
        body: SafeArea(
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

                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.more_vert,
                          color: AppColors.white,
                          size: 28,
                        ),
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
                                  : CachedNetworkImage(
                                    imageUrl: imageUrl,
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
      ),
    );
  }
}
