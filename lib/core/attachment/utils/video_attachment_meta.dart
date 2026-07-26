import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;

class VideoAttachmentMeta {
  final int durationSeconds;
  final File? thumbnailFile;
  const VideoAttachmentMeta({required this.durationSeconds, this.thumbnailFile});
}

Future<VideoAttachmentMeta> extractVideoAttachmentMeta(File videoFile) async {
  int duration = 0;
  try {
    final controller = VideoPlayerController.file(videoFile);
    await controller.initialize();
    duration = controller.value.duration.inSeconds;
    await controller.dispose();
  } catch (_) {
  }

  File? thumbnailFile;
  try {
    final dir = await getTemporaryDirectory();
    final thumbPath = await vt.VideoThumbnail.thumbnailFile(
      video: videoFile.path,
      thumbnailPath: dir.path,
      imageFormat: vt.ImageFormat.JPEG,
      maxWidth: 320,
      quality: 60,
    );
    if (thumbPath != null) thumbnailFile = File(thumbPath);
  } catch (_) {}

  return VideoAttachmentMeta(durationSeconds: duration, thumbnailFile: thumbnailFile);
}