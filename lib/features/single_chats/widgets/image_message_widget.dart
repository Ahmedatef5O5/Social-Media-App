import 'package:social_media_app/core/widgets/cached_cloudinary_image.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/features/single_chats/widgets/full_screen_media_view.dart';
import '../../../core/widgets/custom_loading_indicator.dart';

class ImageMessageWidget extends StatelessWidget {
  final String imageUrl;
  final String? caption;
  final bool isMe;

  const ImageMessageWidget({
    super.key,
    required this.imageUrl,
    this.caption,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    const double preferredWidth = 305.0;
    const double preferredHeight = 250.0;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    FullScreenMediaView(imageUrl: imageUrl, caption: caption),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(isMe ? 18 : 0),
          bottomRight: Radius.circular(isMe ? 0 : 18),
        ),

        child: CachedCloudinaryImage(
          secureUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder:
              (context) => Container(
                width: preferredWidth,
                height: preferredHeight,
                color: Colors.grey[200],
                child: const CustomLoadingIndicator(),
              ),
          errorWidget:
              (context, error) => SizedBox(
                width: preferredWidth,
                height: preferredHeight,
                child: Center(child: const Icon(Icons.error)),
              ),
        ),
      ),
    );
  }
}
