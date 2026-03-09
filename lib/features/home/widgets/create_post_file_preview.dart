import 'package:flutter/material.dart';

class CreatePostFilePreview extends StatelessWidget {
  final String fileName;
  final VoidCallback onRemove;

  const CreatePostFilePreview({
    super.key,
    required this.fileName,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file, color: Colors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 20),
          ),
        ],
      ),
    );
  }
}
