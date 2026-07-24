import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/services/file_picker_services.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/features/gifs/model/gif_result_model.dart';
import 'package:social_media_app/features/gifs/widgets/gif_picker_sheet.dart';
import 'package:social_media_app/features/stickers/model/sticker_model.dart';
import 'package:social_media_app/features/stickers/widgets/sticker_send_picker_sheet.dart';
import 'attachment_kind.dart';
import 'picked_attachment.dart';

class AttachmentPickerSheet extends StatelessWidget {
  final bool showVoiceOption;
  final bool showFileOption;
  final bool showCameraOption;
  final Future<PickedAttachment?> Function(BuildContext context)? onRecordVoice;

  const AttachmentPickerSheet({
    super.key,
    this.showVoiceOption = true,
    this.showFileOption = true,
    this.showCameraOption = false,
    this.onRecordVoice,
  });

  static Future<PickedAttachment?> show(
    BuildContext context, {
    bool showVoiceOption = true,
    bool showFileOption = true,
    bool showCameraOption = false,
    Future<PickedAttachment?> Function(BuildContext context)? onRecordVoice,
  }) {
    return showModalBottomSheet<PickedAttachment?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => AttachmentPickerSheet(
            showVoiceOption: showVoiceOption,
            showFileOption: showFileOption,
            showCameraOption: showCameraOption,
            onRecordVoice: onRecordVoice,
          ),
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
      if (showFileOption)
        _AttachmentOption(
          icon: Icons.insert_drive_file_rounded,
          label: 'File',
          color: Colors.blueAccent,
          onTap: () => _pickFile(context),
        ),
      if (showVoiceOption)
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
      if (showCameraOption)
        _AttachmentOption(
          icon: Icons.camera_alt_rounded,
          label: 'Camera',
          color: Colors.green,
          onTap: () => _takePhoto(context),
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
      PickedAttachment(
        kind: AttachmentKind.image,
        localFile: File(file.path),
        fileName: file.name,
      ),
    );
  }

  Future<void> _takePhoto(BuildContext context) async {
    final nav = Navigator.of(context);
    final file = await FilePickerServices().takePhotoByCamera();
    if (file == null) return;
    nav.pop(
      PickedAttachment(
        kind: AttachmentKind.image,
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
      PickedAttachment(
        kind: AttachmentKind.video,
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
      PickedAttachment(
        kind: AttachmentKind.file,
        localFile: File(file.path),
        fileName: file.name,
        fileSizeBytes: size,
      ),
    );
  }

  Future<void> _recordVoice(BuildContext context) async {
    if (onRecordVoice == null) return;
    final nav = Navigator.of(context);
    final picked = await onRecordVoice!(context);
    if (picked != null) nav.pop(picked);
  }

  Future<void> _pickGif(BuildContext context) async {
    final nav = Navigator.of(context);
    final gif = await showModalBottomSheet<GifResult?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const GifPickerSheet(),
    );
    if (gif != null) {
      nav.pop(
        PickedAttachment(kind: AttachmentKind.gif, remoteUrl: gif.sendUrl),
      );
    }
  }

  Future<void> _pickSticker(BuildContext context) async {
    final nav = Navigator.of(context);
    final sticker = await showModalBottomSheet<StickerModel?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const StickerSendPickerSheet(),
    );
    if (sticker != null) {
      nav.pop(
        PickedAttachment(
          kind: AttachmentKind.sticker,
          remoteUrl: sticker.imageUrl,
        ),
      );
    }
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
