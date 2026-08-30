import 'dart:ui' as ui;
import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NotificationAvatarBuilder {
  final Map<String, Uint8List> _avatarCache = {};
  static const _defaultCacheKey = '__default__';

  Future<Uint8List> getAvatarBitmap(String? avatarUrl) async {
    final cacheKey =
        (avatarUrl == null || avatarUrl.isEmpty) ? _defaultCacheKey : avatarUrl;
    if (_avatarCache.containsKey(cacheKey)) {
      return _avatarCache[cacheKey]!;
    }
    if (avatarUrl == null || avatarUrl.isEmpty) {
      final def = await defaultBitmap();
      _avatarCache[cacheKey] = def;
      return def;
    }

    final bytes = await fetchBitmap(avatarUrl);
    if (bytes != null) {
      _avatarCache[cacheKey] = bytes;
      return bytes;
    }

    final defFallback = await defaultBitmap();
    _avatarCache[cacheKey] = defFallback;
    return defFallback;
  }

  Future<Uint8List> buildLetterAvatar(String name) async {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(100, 100);

    final paint = Paint()..color = const Color(0xFF1E88E5);
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      paint,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 50,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final xOffset = (size.width - textPainter.width) / 2;
    final yOffset = (size.height - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(xOffset, yOffset));

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List?> fetchBitmap(String url) async {
    try {
      final response = await dio_pkg.Dio().get<List<int>>(
        url,
        options: dio_pkg.Options(responseType: dio_pkg.ResponseType.bytes),
      );
      if (response.data == null) return null;
      final raw = Uint8List.fromList(response.data!);
      return await _cropToCircle(raw);
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List> defaultBitmap() async {
    try {
      final data = await rootBundle.load(
        'assets/images/no_profile_picture.png',
      );
      return await _cropToCircle(data.buffer.asUint8List());
    } catch (_) {
      return Uint8List.fromList([
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0x00,
        0x00,
        0x00,
        0x0D,
        0x49,
        0x48,
        0x44,
        0x52,
        0x00,
        0x00,
        0x00,
        0x01,
        0x00,
        0x00,
        0x00,
        0x01,
        0x08,
        0x06,
        0x00,
        0x00,
        0x00,
        0x1F,
        0x15,
        0xC4,
        0x89,
        0x00,
        0x00,
        0x00,
        0x0D,
        0x49,
        0x44,
        0x41,
        0x54,
        0x78,
        0xDA,
        0x63,
        0x64,
        0x60,
        0x60,
        0x60,
        0x00,
        0x00,
        0x00,
        0x05,
        0x00,
        0x01,
        0x22,
        0x28,
        0x28,
        0x23,
        0x00,
        0x00,
        0x00,
        0x00,
        0x49,
        0x45,
        0x4E,
        0x44,
        0xAE,
        0x42,
        0x60,
        0x82,
      ]);
    }
  }

  Future<Uint8List> _cropToCircle(
    Uint8List sourceBytes, {
    int size = 160,
  }) async {
    final codec = await ui.instantiateImageCodec(sourceBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final outputSize = size.toDouble();

    canvas.clipPath(
      Path()..addOval(Rect.fromLTWH(0, 0, outputSize, outputSize)),
    );

    final srcSize = image.width < image.height ? image.width : image.height;
    final srcRect = Rect.fromLTWH(
      (image.width - srcSize) / 2,
      (image.height - srcSize) / 2,
      srcSize.toDouble(),
      srcSize.toDouble(),
    );
    canvas.drawImageRect(
      image,
      srcRect,
      Rect.fromLTWH(0, 0, outputSize, outputSize),
      Paint()..filterQuality = FilterQuality.high,
    );

    final picture = recorder.endRecording();
    final circularImage = await picture.toImage(size, size);
    final byteData = await circularImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData!.buffer.asUint8List();
  }
}
