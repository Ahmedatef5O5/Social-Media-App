import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/themes/app_colors.dart';

class ImagePickerBottomSheet extends StatelessWidget {
  final String title;
  final Function(ImageSource source) onImageSelected;

  const ImagePickerBottomSheet({
    super.key,
    required this.title,
    required this.onImageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 18,
            ),
          ),
          Gap(20),
          ListTile(
            leading: const Icon(
              Icons.photo_library,
              color: AppColors.primaryColor,
            ),
            title: const Text('Choose from Gallery'),
            onTap: () => onImageSelected(ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Colors.green),
            title: const Text('Take a Photo'),
            onTap: () => onImageSelected(ImageSource.camera),
          ),
        ],
      ),
    );
  }
}
