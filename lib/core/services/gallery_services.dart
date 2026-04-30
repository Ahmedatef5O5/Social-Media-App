import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Saved to gallery successfully! ✅',
              style: TextStyle(color: Colors.white),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        if (e is GalException && e.type == GalExceptionType.accessDenied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please allow storage access from settings ⚙️'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save: $e ❌'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
