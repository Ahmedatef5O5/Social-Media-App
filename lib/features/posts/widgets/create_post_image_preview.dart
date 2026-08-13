import 'dart:io';
import 'package:flutter/material.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import '../../../core/attachment/widgets/transfer_ring.dart';
import '../../../core/utilities/file_size_formatter.dart';
import '../../../core/widgets/full_screen_image_viewer.dart';

class CreatePostImagePreview extends StatelessWidget {
  final String imagePath;
  final int? fileSizeBytes;
  final VoidCallback onRemove;

  const CreatePostImagePreview({
    super.key,
    required this.imagePath,
    this.fileSizeBytes,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final bool fileExists = File(imagePath).existsSync();
    final String heroTag = 'post_preview_$imagePath';

    if (!fileExists) {
      return Container(
        height: MediaQuery.sizeOf(context).height * 0.35,
        decoration: BoxDecoration(
          color: AppColors.grey7.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Stack(
          children: [
            const Center(
              child: Icon(Icons.broken_image, size: 50, color: AppColors.grey),
            ),
            Positioned(
              right: 5,
              top: 5,
              child: IconButton(
                onPressed: onRemove,
                icon: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.grey1,
                    shape: BoxShape.circle,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(2.0),
                    child: Icon(
                      Icons.close_outlined,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),

            if (fileSizeBytes != null && fileSizeBytes! > 0)
              Positioned(
                left: 12,
                bottom: 22,
                child: GlassPillBadge(
                  leading: const Icon(
                    Icons.photo_outlined,
                    size: 14,
                    color: Colors.white,
                  ),
                  caption: formatMediaFileSize(fileSizeBytes),
                ),
              ),
          ],
        ),
      );
    }
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                settings: RouteSettings(
                  arguments: {
                    'url': imagePath,
                    'tag': heroTag,
                    'isLocalFile': true,
                  },
                ),
                builder: (context) => const FullScreenImageViewer(),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.grey7.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Hero(
                tag: heroTag,
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.contain,

                  errorBuilder:
                      (context, error, stackTrace) => const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 50,
                          color: AppColors.grey,
                        ),
                      ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 5,
          top: 15,
          child: IconButton(
            onPressed: onRemove,
            icon: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(Icons.close_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
        ),
        if (fileSizeBytes != null && fileSizeBytes! > 0)
          Positioned(
            right: 12,
            bottom: 22,
            child: GlassPillBadge(
              leading: const Icon(
                Icons.photo_outlined,
                size: 14,
                color: Colors.white,
              ),
              caption: formatMediaFileSize(fileSizeBytes),
            ),
          ),
      ],
    );
  }
}
