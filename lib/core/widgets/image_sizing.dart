import 'dart:math' as math;
import 'dart:ui' show PlatformDispatcher;

/// Decides how many physical pixels of width an image really needs, so that
/// both the CDN download and the decoded bitmap stay proportional to what is
/// painted instead of to the uploaded original.
class ImageSizing {
  const ImageSizing._();

  /// Fixed ladder (physical px). Snapping to a small set keeps the number of
  /// derived Cloudinary assets bounded and maximises CDN cache hits.
  /// 1280 matches the upload cap (`c_limit,w_1280`), so it never upscales.
  static const List<int> widthBuckets = [
    96,
    160,
    256,
    384,
    512,
    720,
    1080,
    1280,
  ];

  static const double _maxDevicePixelRatio = 3.0;
  static const double _fallbackScreenLogicalWidth = 411.0;

  /// Smallest bucket that covers [pixels]; the largest bucket otherwise.
  static int bucketFor(double pixels) {
    for (final bucket in widthBuckets) {
      if (pixels <= bucket) return bucket;
    }
    return widthBuckets.last;
  }

  /// [width]/[height] are the logical sizes the widget will be painted at.
  /// `null`, NaN, zero or negative = unknown. `double.infinity` = "fill the
  /// parent", treated as the full screen width.
  ///
  /// With both axes known the larger one wins, so a `BoxFit.cover` box never
  /// ends up decoded below what its longer side needs.
  static int targetPixelWidth({
    double? width,
    double? height,
    double? devicePixelRatio,
    double? screenLogicalWidth,
  }) {
    final view = PlatformDispatcher.instance.views.firstOrNull;
    final dpr =
        (devicePixelRatio ?? view?.devicePixelRatio ?? 2.0)
            .clamp(1.0, _maxDevicePixelRatio)
            .toDouble();
    final screenWidth =
        screenLogicalWidth ??
        (view == null
            ? _fallbackScreenLogicalWidth
            : view.physicalSize.width / view.devicePixelRatio);

    double? resolve(double? value) {
      if (value == null || value.isNaN || value <= 0) return null;
      if (value.isInfinite) return screenWidth;
      return value;
    }

    final w = resolve(width);
    final h = resolve(height);
    final logical =
        (w == null && h == null) ? screenWidth : math.max(w ?? 0, h ?? 0);
    return bucketFor(logical * dpr);
  }
}
