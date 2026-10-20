import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/app_file_image.dart';
import '../../../core/widgets/full_screen_image_viewer.dart';
import '../helpers/media_size_badge.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class CreatePostImagePreview extends StatelessWidget {
  final String imagePath;
  final int? fileSizeBytes;
  final VoidCallback onRemove;

  /// Opens the (optional) image editor. Resolves to the edited file path, or
  /// null if the user discarded the edit. Also handed to the full-screen
  /// viewer so the user can edit from there too.
  final Future<String?> Function()? onEdit;

  const CreatePostImagePreview({
    super.key,
    required this.imagePath,
    this.fileSizeBytes,
    required this.onRemove,
    this.onEdit,
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
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Stack(
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
                        'isEditable': onEdit != null,
                        'onEdit': onEdit,
                      },
                    ),
                    builder: (context) => const FullScreenImageViewer(),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                decoration: BoxDecoration(
                  color: AppColors.grey7.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Hero(
                    tag: heroTag,
                    child: AppFileImage(
                      file: File(imagePath),
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
            if (onEdit != null)
              Positioned(
                right: 5,
                top: 15,
                child: IconButton(
                  tooltip: context.l10n.edit,
                  onPressed: () => onEdit!(),
                  icon: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 18,
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
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (fileSizeBytes != null && fileSizeBytes! > 0)
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 2),
            child: MediaSizeBadge(
              fileSizeBytes: fileSizeBytes,
              icon: Icons.photo_outlined,
            ),
          ),
      ],
    );
  }
}
