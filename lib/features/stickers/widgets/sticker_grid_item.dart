import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class StickerGridItem extends StatelessWidget {
  final List<XFile> images;
  final List<bool>? completedFlags;
  final VoidCallback? onAddTap;
  final void Function(int index, String path)? onImageTap;
  final void Function(int index)? onRemove;

  const StickerGridItem({
    super.key,
    required this.images,
    this.completedFlags,
    this.onAddTap,
    this.onImageTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUploading = completedFlags != null;
    final itemCount = images.length + (isUploading ? 0 : 1);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        if (!isUploading && index == images.length) {
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onAddTap,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add_photo_alternate_outlined),
            ),
          );
        }

        final image = images[index];
        final isDone = isUploading && completedFlags![index];

        return Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap:
                        onImageTap != null
                            ? () => onImageTap!(index, image.path)
                            : null,
                    child: Image.file(File(image.path), fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
            if (isUploading)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isDone ? 0 : 0.35,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            if (isUploading)
              Center(
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.elasticOut,
                  scale: isDone ? 1.0 : 0.0,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            if (!isUploading)
              Positioned(
                top: 2,
                right: 2,
                child: InkWell(
                  onTap: () => onRemove?.call(index),
                  child: const CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
