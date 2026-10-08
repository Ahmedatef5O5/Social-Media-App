import 'dart:io';
import 'package:flutter/widgets.dart';
import 'image_sizing.dart';

/// Drop-in for `Image.file` on previews of user-picked / pending-upload files.
///
/// A camera photo can be 12MP (~48MB decoded). This reads the painted size
/// from layout constraints and decodes at a matching bucket via `cacheWidth`.
/// Do NOT use it for full-screen, zoomable viewers: those need full detail.
class AppFileImage extends StatelessWidget {
  final File file;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final ImageErrorWidgetBuilder? errorBuilder;

  const AppFileImage({
    super.key,
    required this.file,
    this.width,
    this.height,
    this.fit,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final px = ImageSizing.targetPixelWidth(
          width:
              width ??
              (constraints.hasBoundedWidth ? constraints.maxWidth : null),
          height:
              height ??
              (constraints.hasBoundedHeight ? constraints.maxHeight : null),
        );
        return Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          cacheWidth: px,
          errorBuilder: errorBuilder,
        );
      },
    );
  }
}
