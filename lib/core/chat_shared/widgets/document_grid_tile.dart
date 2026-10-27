import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../cache/repository/media_cache_repository.dart';
import '../../helpers/bidi_text_helper.dart';
import '../../helpers/file_icon_helper.dart';
import '../../supabase/supabase_provider.dart';
import '../../utilities/file_size_formatter.dart';
import '../models/shared_media_item.dart';

class DocumentGridTile extends StatelessWidget {
  final SharedMediaItem item;
  final VoidCallback? onTap;

  const DocumentGridTile({super.key, required this.item, this.onTap});

  static String extractExtension(String name, String? url) {
    final target = name.contains('.') ? name : (url ?? '');
    if (target.contains('.')) {
      return target.substring(target.lastIndexOf('.') + 1).toLowerCase();
    }
    return 'file';
  }

  static Future<void> openFile(String? url) async {
    if (url != null && url.isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.primaryColor;

    final fileName =
        item.fileName ?? (item.text.isNotEmpty ? item.text : 'Document');
    final ext = extractExtension(fileName, item.fileUrl);
    final (fileIcon, iconAccent) = FileIconHelper.getIconAndColor(ext, primary);

    final dotIndex = fileName.lastIndexOf('.');
    final baseName =
        dotIndex != -1 ? fileName.substring(0, dotIndex) : fileName;
    final extPart = dotIndex != -1 ? fileName.substring(dotIndex + 1) : '';
    final isArabic =
        BidiTextHelper.detectDirection(baseName) == TextDirection.rtl;
    final displayName =
        isArabic && extPart.isNotEmpty ? '$baseName .$extPart' : fileName;

    final sizeStr = formatMediaFileSize(item.fileSizeBytes);

    return InkWell(
      onTap: onTap ?? () => openFile(item.fileUrl),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color:
              isDark
                  ? iconAccent.withValues(alpha: 0.14)
                  : iconAccent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: iconAccent.withValues(alpha: isDark ? 0.35 : 0.22),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Builder(
              builder: (context) {
                final isMe = item.senderId == SupabaseProvider.id;
                final url = item.fileUrl ?? '';
                final isDownloaded =
                    isMe ||
                    !url.startsWith('http') ||
                    context.read<MediaCacheRepository>().resolveLocalPathSync(
                          url,
                        ) !=
                        null;

                return Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color:
                        isDownloaded
                            ? (isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.white)
                            : iconAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child:
                      isDownloaded
                          ? FaIcon(fileIcon, color: iconAccent, size: 20)
                          : Icon(
                            Icons.arrow_downward_rounded,
                            color: iconAccent,
                            size: 20,
                          ),
                );
              },
            ),
            const SizedBox(height: 6),
            Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: isArabic ? TextAlign.right : TextAlign.left,
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color:
                    isDark
                        ? Colors.white
                        : (iconAccent.computeLuminance() < 0.45
                            ? iconAccent
                            : theme.colorScheme.onSurface),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: iconAccent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    ext.toUpperCase(),
                    style: TextStyle(
                      color: iconAccent,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (sizeStr.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    sizeStr,
                    textDirection: TextDirection.ltr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.75,
                      ),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
