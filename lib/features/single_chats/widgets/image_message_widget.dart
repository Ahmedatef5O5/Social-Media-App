import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/core/attachment/widgets/media_download_gate.dart';
import 'package:social_media_app/core/attachment/widgets/media_loading_placeholder.dart';
import 'package:social_media_app/core/cache/utils/cloudinary_url_extensions.dart';
import 'package:social_media_app/core/widgets/cached_cloudinary_image.dart';
import 'package:social_media_app/features/single_chats/widgets/full_screen_media_view.dart';
import '../../../core/widgets/app_file_image.dart';

class ImageMessageWidget extends StatelessWidget {
  final String imageUrl;
  final String? caption;
  final bool isMe;
  final int? fileSizeBytes;

  const ImageMessageWidget({
    super.key,
    required this.imageUrl,
    this.caption,
    required this.isMe,
    this.fileSizeBytes,
  });

  @override
  Widget build(BuildContext context) {
    const preferredWidth = 305.0;
    const preferredHeight = 250.0;
    final borderRadius = BorderRadiusDirectional.only(
      topStart: const Radius.circular(18),
      topEnd: const Radius.circular(18),
      bottomStart: Radius.circular(isMe ? 18 : 0),
      bottomEnd: Radius.circular(isMe ? 0 : 18),
    ).resolve(Directionality.of(context));
    final bool isLocalFile = !imageUrl.startsWith('http');

    if (isLocalFile) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: AppFileImage(
          file: File(imageUrl),
          width: preferredWidth,
          height: preferredHeight,
          fit: BoxFit.cover,
        ),
      );
    }
    return MediaDownloadGate(
      secureUrl: imageUrl,
      fileSizeBytes: fileSizeBytes,
      borderRadius: borderRadius,
      previewBuilder:
          (context) => CachedNetworkImage(
            imageUrl: imageUrl.cloudinaryLowResPreviewUrl,
            width: preferredWidth,
            height: preferredHeight,
            fit: BoxFit.cover,
            placeholder:
                (context, _) => MediaLoadingPlaceholder(
                  width: preferredWidth,
                  height: preferredHeight,
                  borderRadius: borderRadius,
                ),
            errorWidget:
                (context, _, __) => MediaLoadingPlaceholder(
                  width: preferredWidth,
                  height: preferredHeight,
                  isError: true,
                  borderRadius: borderRadius,
                ),
          ),
      completedBuilder:
          (context, localPath) => GestureDetector(
            onTap:
                () => Navigator.push(
                  context,
                  PageRouteBuilder(
                    opaque: false,
                    pageBuilder:
                        (_, __, ___) => FullScreenMediaView(
                          imageUrl: imageUrl,
                          caption: caption,
                        ),
                    transitionsBuilder: (
                      context,
                      animation,
                      secondaryAnimation,
                      child,
                    ) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                  ),
                ),
            child: CachedCloudinaryImage(
              secureUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder:
                  (context) => MediaLoadingPlaceholder(
                    width: preferredWidth,
                    height: preferredHeight,
                    borderRadius: borderRadius,
                  ),
              errorWidget:
                  (context, error) => SizedBox(
                    width: preferredWidth,
                    height: preferredHeight,
                    child: const Center(child: Icon(Icons.error)),
                  ),
            ),
          ),
    );
  }
}
