import 'dart:io';
import 'package:flutter/material.dart';
import 'package:social_media_app/core/themes/app_colors.dart';

class CreatePostImagePreview extends StatelessWidget {
  final String imagePath;
  final VoidCallback onRemove;

  const CreatePostImagePreview({
    super.key,
    required this.imagePath,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final bool fileExists = File(imagePath).existsSync();
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
    return Stack(
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 400, minHeight: 150),
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.grey7.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(15),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
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
    );
  }
}
