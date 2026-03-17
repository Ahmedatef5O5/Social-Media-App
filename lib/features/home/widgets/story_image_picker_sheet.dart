import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/themes/app_colors.dart';

enum StoryType { text, image }

class StoryImagePickerSheet extends StatelessWidget {
  final Function(ImageSource? source, StoryType type) onSelected;

  const StoryImagePickerSheet({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Add to Story',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(),
          ),
          const Gap(20),
          _buildBottomSheetOption(
            context,
            icon: Icons.text_fields,
            color: AppColors.primaryColor,
            title: 'Text Story',
            onTap: () => onSelected(null, StoryType.text),
          ),

          _buildBottomSheetOption(
            context,
            icon: Icons.photo_library,
            color: AppColors.primaryColor,
            title: 'Gallery',
            onTap: () => onSelected(ImageSource.gallery, StoryType.image),
          ),
          _buildBottomSheetOption(
            context,
            icon: Icons.camera_alt,
            color: Colors.green,
            title: 'Take a Photo',
            onTap: () => onSelected(ImageSource.camera, StoryType.image),
          ),
        ],
      ),
    );
  }
}

Widget _buildBottomSheetOption(
  BuildContext context, {
  required IconData icon,
  required Color color,
  required String title,
  required VoidCallback onTap,
}) {
  return ListTile(
    leading: Icon(icon, color: color),
    title: Text(title),
    onTap: onTap,
  );
}
