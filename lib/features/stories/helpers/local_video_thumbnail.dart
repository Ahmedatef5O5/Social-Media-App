import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class LocalVideoThumbnail extends StatefulWidget {
  final String localPath;
  const LocalVideoThumbnail({super.key, required this.localPath});

  @override
  State<LocalVideoThumbnail> createState() => _LocalVideoThumbnailState();
}

class _LocalVideoThumbnailState extends State<LocalVideoThumbnail> {
  Uint8List? _bytes;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  @override
  void didUpdateWidget(covariant LocalVideoThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.localPath != widget.localPath) {
      _bytes = null;
      _failed = false;
      _generate();
    }
  }

  Future<void> _generate() async {
    try {
      final bytes = await VideoThumbnail.thumbnailData(
        video: widget.localPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 120,
        quality: 40,
      );
      if (!mounted) return;
      setState(() {
        if (bytes == null) {
          _failed = true;
        } else {
          _bytes = bytes;
        }
      });
    } catch (e) {
      debugPrint('MyStoryTile: local video thumbnail failed - $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes != null) {
      return Image.memory(
        _bytes!,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }
    if (_failed) return Container(color: Colors.grey.shade800);

    return Container(
      color: Colors.grey.shade800,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
      ),
    );
  }
}
