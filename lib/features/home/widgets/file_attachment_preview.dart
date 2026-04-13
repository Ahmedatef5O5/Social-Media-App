import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/themes/app_colors.dart';

class FileAttachmentPreview extends StatelessWidget {
  final String url;

  const FileAttachmentPreview({super.key, required this.url});

  Future<void> _openFile() async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Color _getFileColor(String ext) {
    switch (ext) {
      case 'pdf':
        return Colors.redAccent;
      case 'doc':
      case 'docx':
        return Colors.blueAccent;
      case 'xls':
      case 'xlsx':
        return Colors.greenAccent;
      case 'zip':
      case 'rar':
        return Colors.orangeAccent;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _getFileIcon(String ext) {
    if (ext == 'pdf') return Icons.picture_as_pdf_rounded;
    if (['doc', 'docx'].contains(ext)) return Icons.description_rounded;
    if (['zip', 'rar'].contains(ext)) return Icons.inventory_2_rounded;
    if (['xls', 'xlsx'].contains(ext)) return Icons.table_chart_rounded;
    return Icons.insert_drive_file_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final fileName = url.split('/').last.split('?').first;
    final extension = fileName.split('.').last.toLowerCase();
    final fileColor = _getFileColor(extension);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: _openFile,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 80),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).scaffoldBackgroundColor.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.blueGrey1.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: fileColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    _getFileIcon(extension),
                    color: fileColor,
                    size: 30,
                  ),
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        //  color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const Gap(4),
                    Row(
                      children: [
                        Text(
                          extension.toUpperCase(),
                          style: TextStyle(
                            color: fileColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const Gap(8),
                        const CircleAvatar(
                          radius: 1.5,
                          backgroundColor: Colors.grey,
                        ),
                        const Gap(8),
                        const Text(
                          "Tap to view",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.blueGrey3.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
