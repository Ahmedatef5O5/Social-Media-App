import 'dart:io';
import 'package:social_media_app/features/comments/model/comment_type.dart';

class CommentAttachmentDraft {
  final CommentType type;
  final File? localFile;
  final String? remoteUrl;
  final String? fileName;
  final int? fileSizeBytes;
  final int? durationSeconds;

  const CommentAttachmentDraft({
    required this.type,
    this.localFile,
    this.remoteUrl,
    this.fileName,
    this.fileSizeBytes,
    this.durationSeconds,
  });

  bool get needsUpload => localFile != null;

  CommentAttachmentDraft copyWith({
    CommentType? type,
    File? localFile,
    String? remoteUrl,
    String? fileName,
    int? fileSizeBytes,
    int? durationSeconds,
  }) {
    return CommentAttachmentDraft(
      type: type ?? this.type,
      localFile: localFile ?? this.localFile,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      fileName: fileName ?? this.fileName,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }
}
