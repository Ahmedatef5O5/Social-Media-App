import 'dart:io';
import 'attachment_kind.dart';

class PickedAttachment {
  final AttachmentKind kind;
  final File? localFile;
  final String? remoteUrl;
  final String? fileName;
  final int? fileSizeBytes;
  final int? durationSeconds;
  final File? thumbnailFile;

  const PickedAttachment({
    required this.kind,
    this.localFile,
    this.remoteUrl,
    this.fileName,
    this.fileSizeBytes,
    this.durationSeconds,
    this.thumbnailFile,
  });
}
