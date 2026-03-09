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
    return Stack(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            image: DecorationImage(
              image: FileImage(File(imagePath)),
              fit: BoxFit.cover,
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
