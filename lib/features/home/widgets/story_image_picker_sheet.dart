import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';

enum StoryPickType { text, image, video }

class StoryImagePickerSheet extends StatelessWidget {
  final Function(ImageSource? source, StoryPickType type) onSelected;

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
          _buildOption(
            context,
            icon: Icons.text_fields,
            color: Theme.of(context).primaryColor,
            title: 'Text Story',
            onTap: () => onSelected(null, StoryPickType.text),
          ),
          _buildOption(
            context,
            icon: Icons.photo_library,
            color: Theme.of(context).primaryColor,
            title: 'Photo from Gallery',
            onTap: () => onSelected(ImageSource.gallery, StoryPickType.image),
          ),
          _buildOption(
            context,
            icon: Icons.camera_alt,
            color: Colors.green,
            title: 'Take a Photo',
            onTap: () => onSelected(ImageSource.camera, StoryPickType.image),
          ),
          _buildOption(
            context,
            icon: Icons.video_library_outlined,
            color: Colors.deepOrange,
            title: 'Video from Gallery',
            subtitle: 'Max 60 seconds',
            onTap: () => onSelected(ImageSource.gallery, StoryPickType.video),
          ),
          _buildOption(
            context,
            icon: Icons.videocam_outlined,
            color: Colors.red,
            title: 'Record a Video',
            subtitle: 'Max 60 seconds',
            onTap: () => onSelected(ImageSource.camera, StoryPickType.video),
          ),
        ],
      ),
    );
  }
}

Widget _buildOption(
  BuildContext context, {
  required IconData icon,
  required Color color,
  required String title,
  String? subtitle,
  required VoidCallback onTap,
}) {
  return ListTile(
    leading: Icon(icon, color: color),
    title: Text(title),
    subtitle:
        subtitle != null
            ? Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            )
            : null,
    onTap: onTap,
  );
}
