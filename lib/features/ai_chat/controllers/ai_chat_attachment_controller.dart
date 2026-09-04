import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:image/image.dart' as img;
import '../../../core/attachment/attachment_sheet/attachment_kind.dart';
import '../../../core/attachment/attachment_sheet/picked_attachment.dart';
import 'package:flutter/foundation.dart';
import '../../../core/cache/repository/media_cache_repository.dart';
import '../../../core/services/cloudinary_storage_services.dart';
import '../../../core/toast/app_toast.dart';
import '../cubits/ai_chat_cubit/ai_chat_cubit.dart';
import '../models/ai_chat_message.dart';

class AiChatAttachmentController extends ChangeNotifier {
  final MediaCacheRepository mediaCache;
  final AiChatCubit? Function() activeCubit;
  final bool Function() ensureDepsReady;
  final Future<AiChatCubit> Function(String firstMessage) createSession;
  final VoidCallback onBeforeSend;
  final bool Function() isMounted;
  final VoidCallback? onStaged;

  AiChatAttachmentController({
    required this.mediaCache,
    required this.activeCubit,
    required this.ensureDepsReady,
    required this.createSession,
    required this.onBeforeSend,
    required this.isMounted,
    this.onStaged,
  });

  static const int maxFileSizeBytes =
      20 * 1024 * 1024; // matches Gemini's own inline-PDF cap

  static const Set<String> _imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
    'heif',
    'gif',
    'bmp',
  };

  static const Set<String> _textExtensions = {
    'txt',
    'md',
    'json',
    'csv',
    'tsv',
    'html',
    'htm',
    'xml',
    'yaml',
    'yml',
    'dart',
    'js',
    'ts',
    'py',
    'java',
    'c',
    'cpp',
    'cs',
    'sql',
    'sh',
    'log',
    'ini',
    'env',
    'rtf',
  };

  File? stagedMediaFile;
  AiChatMediaType? stagedMediaType;
  String? stagedFileName;
  int? stagedFileSizeBytes;
  String? stagedRemoteImageUrl;

  bool isUploadingImage = false;
  bool isSendingVoice = false;
  bool isSendingFile = false;

  final Map<String, dio_pkg.CancelToken> _uploadCancelTokens = {};

  bool looksLikeImage(String nameOrPath) {
    final dot = nameOrPath.lastIndexOf('.');
    if (dot == -1 || dot == nameOrPath.length - 1) return false;
    return _imageExtensions.contains(
      nameOrPath.substring(dot + 1).toLowerCase(),
    );
  }

  void handleAttachmentPicked(PickedAttachment attachment) {
    if (attachment.kind == AttachmentKind.image &&
        attachment.localFile != null) {
      stageImage(attachment.localFile!, fileName: attachment.fileName);
      return;
    }
    if (attachment.kind == AttachmentKind.file &&
        attachment.localFile != null) {
      final looksImage = looksLikeImage(
        attachment.fileName ?? attachment.localFile!.path,
      );
      if (looksImage) {
        stageImage(attachment.localFile!, fileName: attachment.fileName);
        return;
      }
      stageFile(attachment.localFile!, attachment.fileName ?? 'file');
      return;
    }
    AppToast.info('Sharing this with Syncra is coming soon.');
  }

  Future<void> stageImage(
    File file, {
    String? remoteImageUrl,
    String? fileName,
  }) async {
    if (!await file.exists()) {
      AppToast.error('Image file not found. Please try picking it again.');
      return;
    }
    final sizeBytes = await file.length();
    if (!isMounted()) return;
    stagedMediaFile = file;
    stagedMediaType = AiChatMediaType.image;
    stagedFileName = fileName ?? 'Photo';
    stagedFileSizeBytes = sizeBytes;
    stagedRemoteImageUrl = remoteImageUrl;
    notifyListeners();
    onStaged?.call();
  }

  Future<void> stageFile(File file, String fileName) async {
    if (!await file.exists()) {
      AppToast.error('File not found. Please try picking it again.');
      return;
    }
    final sizeBytes = await file.length();
    if (sizeBytes > maxFileSizeBytes) {
      AppToast.error("Files larger than 20MB aren't supported yet.");
      return;
    }
    if (!isMounted()) return;
    stagedMediaFile = file;
    stagedMediaType = AiChatMediaType.file;
    stagedFileName = fileName;
    stagedFileSizeBytes = sizeBytes;
    stagedRemoteImageUrl = null;
    notifyListeners();
    onStaged?.call();
  }

  void removeStagedMedia() {
    stagedMediaFile = null;
    stagedMediaType = null;
    stagedFileName = null;
    stagedFileSizeBytes = null;
    stagedRemoteImageUrl = null;
    notifyListeners();
  }

  Future<void> sendStagedMedia({required String caption}) async {
    if (stagedMediaFile == null) return;
    final file = stagedMediaFile!;
    final type = stagedMediaType!;
    final fileName = stagedFileName;
    final fileSizeBytes = stagedFileSizeBytes;
    final remoteImageUrl = stagedRemoteImageUrl;
    removeStagedMedia();

    if (type == AiChatMediaType.image) {
      await sendImage(file, caption: caption, remoteImageUrl: remoteImageUrl);
    } else {
      await sendFile(
        file,
        fileName: fileName ?? 'file',
        fileSizeBytes: fileSizeBytes ?? await file.length(),
        caption: caption,
      );
    }
  }

  Future<void> sendVoice(File file, int durationSeconds) async {
    if (isSendingVoice) return;
    if (!await file.exists()) {
      AppToast.error('Voice message not found. Please try recording again.');
      return;
    }
    if (!isMounted()) return;

    onBeforeSend();
    if (!ensureDepsReady()) return;

    isSendingVoice = true;
    notifyListeners();

    var cubit = activeCubit();
    if (cubit == null) {
      try {
        cubit = await createSession('🎤 Voice message');
      } catch (_) {
        if (isMounted()) {
          AppToast.error('Failed to send the voice message. Please try again.');
          isSendingVoice = false;
          notifyListeners();
        }
        return;
      }
    }

    final fileSizeBytes = await file.length();
    final tempId = cubit.beginOptimisticMediaMessage(
      mediaType: AiChatMediaType.voice,
      localFilePath: file.path,
      fileSizeBytes: fileSizeBytes,
      durationSeconds: durationSeconds,
    );
    final cancelToken = dio_pkg.CancelToken();
    _uploadCancelTokens[tempId] = cancelToken;

    try {
      final uploadResult = await CloudinaryStorageServices.instance
          .uploadFile(
            file,
            'ai_chat',
            'voice',
            cancelToken: cancelToken,
            onProgress: (progress) {
              cubit?.updateOptimisticProgress(tempId, progress);
            },
          )
          .timeout(
            const Duration(seconds: 90),
            onTimeout: () => throw Exception('Upload timed out'),
          );
      _uploadCancelTokens.remove(tempId);

      if (!isMounted()) return;
      await cubit.sendMessage(
        text: '',
        mediaType: 'voice',
        mediaUrl: uploadResult.secureUrl,
        fileSizeBytes: fileSizeBytes,
        durationSeconds: durationSeconds,
        targetMediaType: 'voice_record',
        replacingMessageId: tempId,
      );
    } catch (e) {
      _uploadCancelTokens.remove(tempId);
      cubit.removeOptimisticMessage(tempId);
      if (e is dio_pkg.DioException &&
          dio_pkg.DioExceptionType.cancel == e.type) {
        return;
      }
      if (e.toString().contains('UploadCanceledException')) {
        return;
      }
      if (isMounted()) {
        AppToast.error('Failed to send the voice message. Please try again.');
      }
    } finally {
      if (isMounted()) {
        isSendingVoice = false;
        notifyListeners();
      }
    }
  }

  Future<void> sendFile(
    File file, {
    required String fileName,
    required int fileSizeBytes,
    required String caption,
  }) async {
    if (isSendingFile) return;
    onBeforeSend();
    if (!ensureDepsReady()) return;

    isSendingFile = true;
    notifyListeners();

    var cubit = activeCubit();
    if (cubit == null) {
      try {
        cubit = await createSession(caption.isEmpty ? fileName : caption);
      } catch (_) {
        if (isMounted()) {
          AppToast.error('Failed to send the file. Please try again.');
          isSendingFile = false;
          notifyListeners();
        }
        return;
      }
    }

    final tempId = cubit.beginOptimisticMediaMessage(
      mediaType: AiChatMediaType.file,
      caption: caption,
      localFilePath: file.path,
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
    );

    try {
      final extension =
          fileName.contains('.')
              ? fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase()
              : '';

      String? textContent;
      String? documentBase64;
      String? targetMediaType;
      final cancelToken = dio_pkg.CancelToken();
      _uploadCancelTokens[tempId] = cancelToken;

      if (_textExtensions.contains(extension)) {
        try {
          final bytes = await file.readAsBytes();
          // compute() keeps large-file text extraction off the UI thread.
          final raw = await compute(_extractPlainText, bytes);
          if (raw != null && raw.isNotEmpty) {
            textContent =
                raw.length > 25000
                    ? '${raw.substring(0, 25000)}\n\n[...The remaining text has been truncated due to its large size...]'
                    : raw;
          } else {
            targetMediaType = 'document';
          }
        } catch (_) {
          targetMediaType = 'document';
        }
      } else if (extension == 'docx' || extension == 'doc') {
        try {
          final bytes = await file.readAsBytes();
          final extracted = await compute(_extractDocxText, bytes);
          if (extracted != null && extracted.isNotEmpty) {
            textContent =
                extracted.length > 25000
                    ? '${extracted.substring(0, 25000)}\n\n[...The remaining text has been truncated...]'
                    : extracted;
          } else {
            targetMediaType = 'document';
          }
        } catch (_) {
          targetMediaType = 'document';
        }
      } else if (extension == 'xlsx' || extension == 'xls') {
        try {
          final bytes = await file.readAsBytes();
          final extracted = await compute(_extractXlsxText, bytes);
          if (extracted != null && extracted.isNotEmpty) {
            textContent =
                extracted.length > 25000
                    ? '${extracted.substring(0, 25000)}\n\n[...The remaining data has been truncated...]'
                    : extracted;
          } else {
            targetMediaType = 'document';
          }
        } catch (_) {
          targetMediaType = 'document';
        }
      } else if (extension == 'pdf') {
        final bytes = await file.readAsBytes();
        documentBase64 = await compute(base64Encode, bytes);
      } else {
        targetMediaType = 'document';
      }

      final uploadResult = await CloudinaryStorageServices.instance
          .uploadFile(
            file,
            'ai_chat',
            'files',
            cancelToken: cancelToken,
            onProgress: (progress) {
              cubit?.updateOptimisticProgress(tempId, progress);
            },
          )
          .timeout(
            const Duration(seconds: 180),
            onTimeout: () => throw Exception('Upload timed out'),
          );
      _uploadCancelTokens.remove(tempId);

      if (!isMounted()) return;
      await mediaCache.adoptUploadedFile(uploadResult.secureUrl, file);

      if (!isMounted()) return;
      await cubit.sendMessage(
        text: caption,
        mediaType: 'file',
        mediaUrl: uploadResult.secureUrl,
        fileName: fileName,
        fileSizeBytes: fileSizeBytes,
        textContent: textContent,
        documentBase64: documentBase64,
        targetMediaType: targetMediaType,
        replacingMessageId: tempId,
      );
    } catch (e) {
      _uploadCancelTokens.remove(tempId);
      cubit.removeOptimisticMessage(tempId);
      if (e is dio_pkg.DioException &&
          dio_pkg.DioExceptionType.cancel == e.type) {
        return;
      }
      if (e.toString().contains('UploadCanceledException')) {
        return;
      }
      if (isMounted()) AppToast.error('Failed to upload. Please try again.');
    } finally {
      if (isMounted()) {
        isSendingFile = false;
        notifyListeners();
      }
    }
  }

  Future<void> sendImage(
    File file, {
    String? caption,
    String? remoteImageUrl,
  }) async {
    if (isUploadingImage) return;
    onBeforeSend();
    if (!ensureDepsReady()) return;
    if (!await file.exists()) {
      AppToast.error('Image file not found. Please try picking it again.');
      return;
    }
    if (!isMounted()) return;

    isUploadingImage = true;
    notifyListeners();

    final resolvedCaption = caption ?? '';

    var cubit = activeCubit();
    if (cubit == null) {
      try {
        cubit = await createSession(
          resolvedCaption.isEmpty ? '📷 Photo' : resolvedCaption,
        );
      } catch (_) {
        if (isMounted()) {
          AppToast.error('Failed to send the photo. Please try again.');
          isUploadingImage = false;
          notifyListeners();
        }
        return;
      }
    }

    final fileSizeBytes = await file.length();
    final tempId = cubit.beginOptimisticMediaMessage(
      mediaType: AiChatMediaType.image,
      caption: resolvedCaption,
      localFilePath: file.path,
      fileSizeBytes: fileSizeBytes,
    );

    final cancelToken = dio_pkg.CancelToken();
    _uploadCancelTokens[tempId] = cancelToken;
    try {
      final bytes = await file.readAsBytes();
      final imageBase64 = await compute(_downscaleAndEncodeImage, bytes);
      final String finalUrl;
      if (remoteImageUrl != null) {
        finalUrl = remoteImageUrl;
      } else {
        final uploadResult = await CloudinaryStorageServices.instance
            .uploadFile(
              file,
              'ai_chat',
              'images',
              cancelToken: cancelToken,
              onProgress: (progress) {
                cubit?.updateOptimisticProgress(tempId, progress);
              },
            )
            .timeout(
              const Duration(seconds: 90),
              onTimeout: () => throw Exception('Upload timed out'),
            );
        _uploadCancelTokens.remove(tempId);
        finalUrl = uploadResult.secureUrl;

        if (!isMounted()) return;
        await mediaCache.adoptUploadedFile(finalUrl, file);
      }

      if (!isMounted()) return;
      await cubit.sendMessage(
        text: resolvedCaption,
        mediaType: 'image',
        mediaUrl: finalUrl,
        fileSizeBytes: bytes.length,
        imageBase64: imageBase64,
        replacingMessageId: tempId,
      );
    } catch (e) {
      _uploadCancelTokens.remove(tempId);
      cubit.removeOptimisticMessage(tempId);
      if (e is dio_pkg.DioException &&
          dio_pkg.DioExceptionType.cancel == e.type) {
        return;
      }
      if (e.toString().contains('UploadCanceledException')) {
        return;
      }
      if (isMounted()) {
        AppToast.error('Failed to send the photo. Please try again.');
      }
    } finally {
      if (isMounted()) {
        isUploadingImage = false;
        notifyListeners();
      }
    }
  }

  void cancelUpload(String messageId) {
    _uploadCancelTokens[messageId]?.cancel('user_cancelled');
    _uploadCancelTokens.remove(messageId);
    activeCubit()?.removeOptimisticMessage(messageId);
  }

  @override
  void dispose() {
    for (final token in _uploadCancelTokens.values) {
      token.cancel('view_disposed');
    }
    _uploadCancelTokens.clear();
    super.dispose();
  }
}

// ============================================================================
// Top-Level Data Extraction Functions (Run in Isolates via compute)
// ============================================================================

String _downscaleAndEncodeImage(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return base64Encode(bytes);

  final needsResize = decoded.width > 1024 || decoded.height > 1024;
  final resized =
      needsResize
          ? img.copyResize(
            decoded,
            width: decoded.width >= decoded.height ? 1024 : null,
            height: decoded.height > decoded.width ? 1024 : null,
          )
          : decoded;

  return base64Encode(img.encodeJpg(resized, quality: 85));
}

String? _extractPlainText(Uint8List bytes) {
  try {
    return utf8.decode(bytes, allowMalformed: true);
  } catch (e) {
    return null;
  }
}

String? _extractDocxText(Uint8List bytes) {
  try {
    final archive = ZipDecoder().decodeBytes(bytes);
    final documentFile = archive.findFile('word/document.xml');
    if (documentFile == null) return null;

    final xmlContent = utf8.decode(
      documentFile.content as List<int>,
      allowMalformed: true,
    );
    final regex = RegExp(r'<w:t(?:\s+[^>]*)?>([^<]*)</w:t>');
    final matches = regex.allMatches(xmlContent);
    final text = matches.map((m) => m.group(1) ?? '').join(' ');
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  } catch (e) {
    debugPrint('Docx extraction error: $e');
    return null;
  }
}

String? _extractXlsxText(Uint8List bytes) {
  try {
    final archive = ZipDecoder().decodeBytes(bytes);
    final buffer = StringBuffer();

    final sharedStringsFile = archive.findFile('xl/sharedStrings.xml');
    if (sharedStringsFile != null) {
      final xmlContent = utf8.decode(
        sharedStringsFile.content as List<int>,
        allowMalformed: true,
      );
      final regex = RegExp(r'<t(?:\s+[^>]*)?>([^<]*)</t>');
      for (final match in regex.allMatches(xmlContent)) {
        buffer.write('${match.group(1)} | ');
      }
    }

    final sheetFile = archive.findFile('xl/worksheets/sheet1.xml');
    if (sheetFile != null) {
      final xmlContent = utf8.decode(
        sheetFile.content as List<int>,
        allowMalformed: true,
      );
      final regex = RegExp(r'<v>([^<]*)</v>');
      for (final match in regex.allMatches(xmlContent)) {
        final val = match.group(1) ?? '';
        if (double.tryParse(val) != null) buffer.write('$val | ');
      }
    }

    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  } catch (e) {
    debugPrint('Xlsx extraction error: $e');
    return null;
  }
}
