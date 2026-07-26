import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import '../toast/app_toast.dart';

class GalleryServices {
  static Future<void> saveMediaToGallery({
    required BuildContext context,
    required String url,
    required bool isVideo,
  }) async {
    try {
      if (!await Gal.hasAccess()) {
        await Gal.requestAccess();
      }

      final tempDir = await getTemporaryDirectory();
      final extension = isVideo ? 'mp4' : 'jpg';
      final savePath =
          '${tempDir.path}/temp_media_${DateTime.now().millisecondsSinceEpoch}.$extension';

      await Dio().download(url, savePath);

      if (isVideo) {
        await Gal.putVideo(savePath);
      } else {
        await Gal.putImage(savePath);
      }

      if (context.mounted) {
        AppToast.success('Saved to gallery successfully! ✅');
      }
    } catch (e) {
      if (context.mounted) {
        if (e is GalException && e.type == GalExceptionType.accessDenied) {
          AppToast.warning('Please allow storage access from settings ⚙️');
        } else {
          AppToast.error('Failed to save: $e ❌');
        }
      }
    }
  }
}
