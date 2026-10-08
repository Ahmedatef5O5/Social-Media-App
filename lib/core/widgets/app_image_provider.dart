import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/painting.dart';
import '../cache/utils/cloudinary_url_extensions.dart';
import 'image_sizing.dart';

/// Size-aware replacements for `CachedNetworkImageProvider(url)`,
/// `NetworkImage(url)` and `FileImage(file)`.
///
/// Each provider is wrapped in [ResizeImage] so the decoded bitmap matches the
/// painted size, and Cloudinary URLs are rewritten so the CDN also sends a
/// matching rendition (see `CloudinaryUrlX.cloudinarySizedImageUrl`).
class AppImageProvider {
  const AppImageProvider._();

  /// For `CircleAvatar(radius: r, backgroundImage: ...)`.
  static ImageProvider avatar(String url, {required double radius}) =>
      network(url, width: radius * 2, height: radius * 2);

  /// [width]/[height] are logical sizes; `double.infinity` = full screen width.
  static ImageProvider network(String url, {double? width, double? height}) {
    final px = ImageSizing.targetPixelWidth(width: width, height: height);
    return ResizeImage(
      CachedNetworkImageProvider(url.cloudinarySizedImageUrl(px)),
      width: px,
    );
  }

  /// For user-picked files (a camera photo can be 12MP = ~48MB decoded).
  static ImageProvider file(File file, {double? width, double? height}) {
    final px = ImageSizing.targetPixelWidth(width: width, height: height);
    return ResizeImage(FileImage(file), width: px);
  }
}
