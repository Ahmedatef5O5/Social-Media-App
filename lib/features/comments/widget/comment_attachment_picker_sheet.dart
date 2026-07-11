import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/services/file_picker_services.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/features/comments/model/comment_attachment_draft.dart';
import 'package:social_media_app/features/comments/model/comment_type.dart';
import 'package:social_media_app/features/comments/widget/comment_gif_picker_sheet.dart';
import 'package:social_media_app/features/comments/widget/comment_sticker_picker_sheet.dart';
import 'package:social_media_app/features/comments/widget/comment_voice_recorder_sheet.dart';

class CommentAttachmentPickerSheet extends StatelessWidget {
  const CommentAttachmentPickerSheet({super.key});

  static Future<CommentAttachmentDraft?> show(BuildContext context) {
    return showModalBottomSheet<CommentAttachmentDraft?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CommentAttachmentPickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = <_AttachmentOption>[
      _AttachmentOption(
        icon: Icons.image_rounded,
        label: 'Gallery',
        color: Colors.purple,
        onTap: () => _pickImage(context),
      ),
      _AttachmentOption(
        icon: Icons.videocam_rounded,
        label: 'Video',
        color: Colors.redAccent,
        onTap: () => _pickVideo(context),
      ),
      _AttachmentOption(
        icon: Icons.insert_drive_file_rounded,
        label: 'File',
        color: Colors.blueAccent,
        onTap: () => _pickFile(context),
      ),
      _AttachmentOption(
        icon: Icons.mic_rounded,
        label: 'Voice',
        color: Colors.orange,
        onTap: () => _recordVoice(context),
      ),
      _AttachmentOption(
        icon: Icons.gif_box_rounded,
        label: 'GIF',
        color: Colors.teal,
        onTap: () => _pickGif(context),
      ),
      _AttachmentOption(
        icon: Icons.emoji_emotions_rounded,
        label: 'Sticker',
        color: Colors.pinkAccent,
        onTap: () => _pickSticker(context),
      ),
    ];

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey5,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const Gap(18),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 8,
              children: options.map((o) => _buildOption(context, o)).toList(),
            ),
            const Gap(8),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, _AttachmentOption option) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: option.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: option.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(option.icon, color: option.color, size: 26),
          ),
          const Gap(6),
          Text(
            option.label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final nav = Navigator.of(context);
    final file = await FilePickerServices().pickImageFromGallery();
    if (file == null) return;
    nav.pop(
      CommentAttachmentDraft(
        type: CommentType.image,
        localFile: File(file.path),
        fileName: file.name,
      ),
    );
  }

  Future<void> _pickVideo(BuildContext context) async {
    final nav = Navigator.of(context);
    final file = await FilePickerServices().pickVideoFromGallery();
    if (file == null) return;
    nav.pop(
      CommentAttachmentDraft(
        type: CommentType.video,
        localFile: File(file.path),
        fileName: file.name,
      ),
    );
  }

  Future<void> _pickFile(BuildContext context) async {
    final nav = Navigator.of(context);
    final file = await FilePickerServices().pickFile();
    if (file == null) return;
    final size = await File(file.path).length();
    nav.pop(
      CommentAttachmentDraft(
        type: CommentType.file,
        localFile: File(file.path),
        fileName: file.name,
        fileSizeBytes: size,
      ),
    );
  }

  Future<void> _recordVoice(BuildContext context) async {
    final nav = Navigator.of(context);
    final draft = await showModalBottomSheet<CommentAttachmentDraft?>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const CommentVoiceRecorderSheet(),
    );
    if (draft != null) nav.pop(draft);
  }

  Future<void> _pickGif(BuildContext context) async {
    final nav = Navigator.of(context);
    final draft = await showModalBottomSheet<CommentAttachmentDraft?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CommentGifPickerSheet(),
    );
    if (draft != null) nav.pop(draft);
  }

  Future<void> _pickSticker(BuildContext context) async {
    final nav = Navigator.of(context);
    final draft = await showModalBottomSheet<CommentAttachmentDraft?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CommentStickerPickerSheet(),
    );
    if (draft != null) nav.pop(draft);
  }
}

class _AttachmentOption {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _AttachmentOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
