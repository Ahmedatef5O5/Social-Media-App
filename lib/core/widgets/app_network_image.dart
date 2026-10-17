import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import '../cache/utils/cloudinary_url_extensions.dart';
import 'image_sizing.dart';

/// Drop-in for the `CachedNetworkImage` call sites that fill a tile, grid cell
/// or card. Reads its on-screen size from layout constraints, then:
///  * asks the CDN for a matching rendition (Cloudinary image + video poster),
///  * caps the decoded bitmap through `memCacheWidth`.
///
/// Only the parameters those call sites actually use are exposed.
class AppNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final PlaceholderWidgetBuilder? placeholder;
  final LoadingErrorWidgetBuilder? errorWidget;
  final Map<String, String>? httpHeaders;
  final void Function(Object)? errorListener;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
    this.httpHeaders,
    this.errorListener,
  });

  @override
  Widget build(BuildContext context) {
    // If explicit dimensions are already provided, bypass LayoutBuilder completely
    // to avoid breaking ancestor widgets calculating intrinsic dimensions.
    if (width != null && height != null) {
      final px = ImageSizing.targetPixelWidth(width: width, height: height);
      final url = imageUrl
          .cloudinarySizedImageUrl(px)
          .cloudinarySizedVideoThumbnailUrl(px);

      return CachedNetworkImage(
        imageUrl: url,
        memCacheWidth: px,
        width: width,
        height: height,
        fit: fit,
        placeholder: placeholder,
        errorWidget: errorWidget,
        httpHeaders: httpHeaders,
        errorListener: errorListener,
      );
    }

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
        final url = imageUrl
            .cloudinarySizedImageUrl(px)
            .cloudinarySizedVideoThumbnailUrl(px);

        return CachedNetworkImage(
          imageUrl: url,
          memCacheWidth: px,
          width: width,
          height: height,
          fit: fit,
          placeholder: placeholder,
          errorWidget: errorWidget,
          httpHeaders: httpHeaders,
          errorListener: errorListener,
        );
      },
    );
  }
}
