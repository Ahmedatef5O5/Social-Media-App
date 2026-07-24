import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FileMessageBubble extends StatelessWidget {
  final String fileUrl;
  final String? fileName;
  final int? fileSizeBytes;
  final bool isMe;

  const FileMessageBubble({
    super.key,
    required this.fileUrl,
    this.fileName,
    this.fileSizeBytes,
    this.isMe = false,
  });

  String _formatSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final fg = isMe ? Colors.white : primary;
    final bg =
        isMe
            ? Colors.white.withValues(alpha: 0.16)
            : primary.withValues(alpha: 0.1);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap:
          () => launchUrl(
            Uri.parse(fileUrl),
            mode: LaunchMode.externalApplication,
          ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file_rounded, color: fg),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fileName ?? 'File',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _formatSize(fileSizeBytes),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: fg.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
