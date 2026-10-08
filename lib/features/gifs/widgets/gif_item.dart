import 'package:flutter/material.dart';
import '../../../core/widgets/app_network_image.dart';
import '../models/gif_result_model.dart';

class GifItem extends StatelessWidget {
  final GifResult gif;

  const GifItem({super.key, required this.gif});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(gif),
        child: AppNetworkImage(imageUrl: gif.previewUrl, fit: BoxFit.cover),
      ),
    );
  }
}
