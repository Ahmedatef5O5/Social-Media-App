import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:social_media_app/core/media_editor/media_editor_models.dart';
import 'package:social_media_app/core/media_editor/views/app_image_editor_view.dart';
import 'package:social_media_app/core/media_editor/views/app_video_trim_view.dart';
import 'package:social_media_app/core/services/media_cleanup_service.dart';
import 'package:social_media_app/core/toast/app_toast.dart';
export 'package:social_media_app/core/media_editor/media_editor_models.dart';

/// Single entry point every staging screen uses.

class MediaEditorService {
  MediaEditorService._();

  /// Opens the image editor for [source]. Returns the edited file (a tracked
  /// temp file) or `null` when the user discarded the edit.
  static Future<File?> editImage(
    BuildContext context,
    File source, {
    MediaEditorPreset preset = MediaEditorPreset.free,
  }) async {
    if (!await source.exists()) {
      AppToast.error('Image file not found.');
      return null;
    }
    MediaCleanupService.instance.purgeStaleTempFiles();

    if (!context.mounted) return null;
    final bytes = await Navigator.of(
      context,
      rootNavigator: true,
    ).push<Uint8List>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AppImageEditorView(file: source, preset: preset),
      ),
    );
    if (bytes == null || bytes.isEmpty) return null;

    try {
      return await MediaCleanupService.instance.createTempFile(
        bytes,
        extension: _sniffImageExtension(bytes),
      );
    } catch (e) {
      debugPrint('[MediaEditorService] could not save edited image: $e');
      AppToast.error('Could not save your edit. Please try again.');
      return null;
    }
  }

  /// Opens the trim screen for [source]. Returns the trimmed clip or `null`
  /// when the user cancelled or changed nothing.
  static Future<TrimmedVideo?> trimVideo(
    BuildContext context,
    File source, {
    Duration? maxDuration,
  }) async {
    if (!await source.exists()) {
      AppToast.error('Video file not found.');
      return null;
    }
    MediaCleanupService.instance.purgeStaleTempFiles();

    if (!context.mounted) return null;
    return Navigator.of(context, rootNavigator: true).push<TrimmedVideo>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder:
            (_) => AppVideoTrimView(file: source, maxDuration: maxDuration),
      ),
    );
  }

  static String _sniffImageExtension(Uint8List b) {
    if (b.length > 12 &&
        b[0] == 0x89 &&
        b[1] == 0x50 &&
        b[2] == 0x4E &&
        b[3] == 0x47) {
      return 'png';
    }
    if (b.length > 12 &&
        b[0] == 0x52 && // R
        b[1] == 0x49 && // I
        b[2] == 0x46 && // F
        b[3] == 0x46 && // F
        b[8] == 0x57 && // W
        b[9] == 0x45 && // E
        b[10] == 0x42 && // B
        b[11] == 0x50) {
      // P
      return 'webp';
    }
    return 'jpg';
  }
}
