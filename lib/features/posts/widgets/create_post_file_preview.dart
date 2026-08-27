import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:social_media_app/core/helpers/chat_helper.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import '../../../core/utilities/file_size_formatter.dart';

class CreatePostFilePreview extends StatelessWidget {
  final String fileName;
  final int? fileSizeBytes;
  final VoidCallback onRemove;

  const CreatePostFilePreview({
    super.key,
    required this.fileName,
    this.fileSizeBytes,
    required this.onRemove,
  });

  String _getFileExtension() {
    if (fileName.contains('.')) {
      return fileName.substring(fileName.lastIndexOf('.') + 1).toUpperCase();
    }
    return 'FILE';
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
      case 'pyw':
      case 'js':
      case 'ts':
      case 'html':
      case 'htm':
      case 'css':
      case 'xml':
      case 'yaml':
      case 'yml':
      case 'java':
      case 'kt':
      case 'kts':
      case 'c':
      case 'cpp':
      case 'cc':
      case 'cxx':
      case 'h':
      case 'hpp':
      case 'cs':
      case 'swift':
      case 'go':
      case 'rb':
      case 'rs':
      case 'sql':
      case 'sh':
      case 'bat':
      case 'env':
        return (FontAwesomeIcons.solidFileCode, const Color(0xFF00B4D8));
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return (FontAwesomeIcons.solidFileZipper, const Color(0xFFF59E0B));
      case 'mp3':
      case 'wav':
      case 'm4a':
      case 'aac':
      case 'ogg':
        return (FontAwesomeIcons.solidFileAudio, const Color(0xFF9333EA));
      case 'mp4':
      case 'avi':
      case 'mkv':
      case 'mov':
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.primaryColor;
    final ext = _getFileExtension();
    final (fileIcon, iconAccent) = _getFileIconAndColor(ext, primary);

    final sizeStr =
        fileSizeBytes != null && fileSizeBytes! > 0
            ? formatMediaFileSize(fileSizeBytes)
            : '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:
            isDark
                ? iconAccent.withValues(alpha: 0.12)
                : iconAccent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: iconAccent.withValues(alpha: isDark ? 0.3 : 0.18),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: FaIcon(fileIcon, color: iconAccent, size: 22),
          ),
          const SizedBox(width: 12),
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
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: iconAccent.withValues(
                          alpha: isDark ? 0.25 : 0.14,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        ext,
                        style: TextStyle(
                          color: isDark ? Colors.white : iconAccent,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    if (sizeStr.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        sizeStr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.white70 : AppColors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.cancel, color: AppColors.grey, size: 22),
            splashRadius: 18,
          ),
        ],
      ),
    );
  }
}
