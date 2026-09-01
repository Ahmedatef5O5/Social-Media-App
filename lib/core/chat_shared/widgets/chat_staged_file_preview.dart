import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:open_filex/open_filex.dart';
import 'package:social_media_app/core/helpers/chat_helper.dart';
import '../../helpers/file_icon_helper.dart';
import '../../toast/app_toast.dart';
import '../../router/app_routes.dart';

class ChatStagedFilePreview extends StatelessWidget {
  final String fileName;
  final int fileSizeBytes;
  final VoidCallback onRemove;
  final File? file;
  final File? imageFile;
  final VoidCallback? onTapLeading;

  const ChatStagedFilePreview({
    super.key,
    required this.fileName,
    required this.fileSizeBytes,
    required this.onRemove,
    this.file,
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

  Future<void> _openStagedMediaPreview(BuildContext context) async {
    final fileToOpen = file ?? imageFile;
    if (fileToOpen == null) return;

    final isImage = ['PNG', 'JPG', 'JPEG', 'WEBP', 'GIF'].contains(_extension);

    if (isImage) {
      await Navigator.of(context, rootNavigator: true).pushNamed(
        AppRoutes.fullScreenImageViewRoute,
        arguments: {'url': fileToOpen.path, 'isLocalFile': true},
      );
      return;
    }

    try {
      final result = await OpenFilex.open(fileToOpen.path);
      if (result.type != ResultType.done && context.mounted) {
        AppToast.error("Couldn't open that file.");
      }
    } catch (_) {
      if (context.mounted) AppToast.error("Couldn't open that file.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = _extension;
    final primary = Theme.of(context).primaryColor;
    final (fileIcon, iconAccent) = FileIconHelper.getIconAndColor(ext, primary);

    return GestureDetector(
      onTap: () => _openStagedMediaPreview(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
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
              onTap: onTapLeading ?? () => _openStagedMediaPreview(context),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child:
                    (imageFile != null ||
                            (file != null &&
                                [
                                  'PNG',
                                  'JPG',
                                  'JPEG',
                                  'WEBP',
                                  'GIF',
                                ].contains(ext)))
                        ? Image.file(
                          (imageFile ?? file)!,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                        )
                        : Container(
                          width: 36,
                          height: 36,
                          color: primary.withValues(alpha: 0.12),
                          child: Center(
                            child: FaIcon(
                              fileIcon,
                              color: iconAccent,
                              size: 25,
                            ),
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
      ),
    );
  }
}
