import 'package:flutter/material.dart';
import '../model/gif_result_model.dart';

class GifItem extends StatelessWidget {
  final GifResult gif;

  const GifItem({super.key, required this.gif});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(gif),
        child: Image.network(gif.previewUrl, fit: BoxFit.cover),
      ),
    );
  }
}
