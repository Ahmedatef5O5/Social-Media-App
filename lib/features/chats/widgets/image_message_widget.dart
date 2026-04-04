import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/features/chats/widgets/full_screen_media_view.dart';
import '../../../core/widgets/custom_loading_indicator.dart';

class ImageMessageWidget extends StatelessWidget {
  final String imageUrl;
  final String? caption;

  const ImageMessageWidget({super.key, required this.imageUrl, this.caption});

  @override
  Widget build(BuildContext context) {
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
        borderRadius: BorderRadius.all(Radius.circular(22)),

        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          placeholder: (context, url) => const CustomLoadingIndicator(),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      ),
    );
  }
}
