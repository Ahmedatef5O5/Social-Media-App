import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/helpers/chat_helper.dart';

class ChatStagedFilePreview extends StatelessWidget {
  final String fileName;
  final int fileSizeBytes;
  final VoidCallback onRemove;
  final File? imageFile;
  final VoidCallback? onTapLeading;

  const ChatStagedFilePreview({
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

  (FaIconData, Color) _getFileIconAndColor(String ext, Color defaultColor) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return (FontAwesomeIcons.solidFilePdf, const Color(0xFFE5252A));
      case 'doc':
      case 'docx':
        return (FontAwesomeIcons.solidFileWord, const Color(0xFF185ABD));
      case 'xls':
      case 'xlsx':
      case 'csv':
        return (FontAwesomeIcons.solidFileExcel, const Color(0xFF217346));
      case 'ppt':
      case 'pptx':
        return (FontAwesomeIcons.solidFilePowerpoint, const Color(0xFFD24726));
      case 'txt':
      case 'rtf':
        return (FontAwesomeIcons.solidFileLines, const Color(0xFF2E7D52));
      case 'md':
        return (FontAwesomeIcons.solidFileLines, const Color(0xFF3B82F6));
      case 'json':
      case 'dart':
      case 'py':
      case 'js':
      case 'ts':
      case 'html':
      case 'css':
        return (FontAwesomeIcons.solidFileCode, const Color(0xFF00B4D8));
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
        return (FontAwesomeIcons.solidFileZipper, const Color(0xFFF59E0B));
      case 'mp3':
      case 'wav':
      case 'm4a':
      case 'ogg':
        return (FontAwesomeIcons.solidFileAudio, const Color(0xFF9333EA));
      case 'mp4':
      case 'avi':
      case 'mkv':
        return (FontAwesomeIcons.solidFileVideo, const Color(0xFFE11D48));
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'webp':
        return (FontAwesomeIcons.solidFileImage, const Color(0xFF059669));
      default:
        return (FontAwesomeIcons.solidFile, defaultColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = _extension;
    final primary = Theme.of(context).primaryColor;
    final (fileIcon, iconAccent) = _getFileIconAndColor(ext, primary);

    return Container(
      margin: const EdgeInsets.only(bottom: 6, left: 16, right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.14)
                  : Colors.black.withValues(alpha: 0.08),
        ),
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
                        color: primary.withValues(alpha: 0.12),
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
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  _extension.isEmpty
                      ? _formattedSize
                      : '$_extension · $_formattedSize',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onRemove,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: Theme.of(
                  context,
                ).iconTheme.color?.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
