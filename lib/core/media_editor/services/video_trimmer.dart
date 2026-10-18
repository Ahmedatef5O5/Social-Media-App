import 'dart:io';
import 'package:pro_video_editor/pro_video_editor.dart';
import 'package:social_media_app/core/services/media_cleanup_service.dart';

class VideoTrimmer {
  VideoTrimmer._();

  static Future<File> trim({
    required File source,
    required Duration start,
    required Duration end,
  }) async {
    final outPath = await MediaCleanupService.instance.createTempPath('mp4');
    try {
      final data = VideoRenderData(
        videoSegments: [
          VideoSegment(
            video: EditorVideo.file(source),
            startTime: start,
            endTime: end,
          ),
        ],
      );
      await ProVideoEditor.instance.renderVideoToFile(outPath, data);

      final out = File(outPath);
      if (!await out.exists() || await out.length() == 0) {
        throw StateError('video_trim_empty_output');
      }
      return out;
    } catch (_) {
      await MediaCleanupService.instance.deleteTempFile(File(outPath));
      rethrow;
    }
  }
}
