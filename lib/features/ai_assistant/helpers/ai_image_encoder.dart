import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class AiImageEncoder {
  static const _maxDimension = 640;
  static const _jpegQuality = 70;

  static String? encodeForCaption(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    final needsResize =
        decoded.width > _maxDimension || decoded.height > _maxDimension;

    final resized =
        !needsResize
            ? decoded
            : img.copyResize(
              decoded,
              width: decoded.width >= decoded.height ? _maxDimension : null,
              height: decoded.height > decoded.width ? _maxDimension : null,
            );

    final jpegBytes = img.encodeJpg(resized, quality: _jpegQuality);
    return base64Encode(jpegBytes);
  }
}
