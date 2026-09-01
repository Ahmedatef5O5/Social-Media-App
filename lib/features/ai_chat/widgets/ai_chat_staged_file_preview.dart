import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import '../../../core/helpers/chat_helper.dart';
import '../../../core/helpers/file_icon_helper.dart';

class AiChatStagedFilePreview extends StatelessWidget {
  final String fileName;
  final int fileSizeBytes;
  final VoidCallback onRemove;
  final File? imageFile;
  final VoidCallback? onTapLeading;

  const AiChatStagedFilePreview({
    super.key,
    required this.fileName,
    required this.fileSizeBytes,
    required this.onRemove,
    this.imageFile,
    this.onTapLeading,
  });

  String get _extension {
    final dot = fileName.lastIndexOf('.');
    if (dot == -1 || dot == fileName.length - 1) return '';
    return fileName.substring(dot + 1).toUpperCase();
  }

  String get _formattedSize {
    final kb = fileSizeBytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final ext = _extension;
    final primary = Theme.of(context).primaryColor;
    final (fileIcon, iconAccent) = FileIconHelper.getIconAndColor(ext, primary);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTapLeading,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child:
                  imageFile != null
                      ? Image.file(
                        imageFile!,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                      )
                      : Container(
                        width: 36,
                        height: 36,
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.12),

                        child: Center(
                          child: FaIcon(fileIcon, color: iconAccent, size: 25),
                        ),
                      ),
            ),
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: ChatHelper.getTextDirection(fileName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  _extension.isEmpty
                      ? _formattedSize
                      : '$_extension · $_formattedSize',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.close_rounded, size: 18, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
