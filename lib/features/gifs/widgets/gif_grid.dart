import 'package:flutter/material.dart';
import '../model/gif_result_model.dart';
import 'gif_item.dart';

class GifGrid extends StatelessWidget {
  final List<GifResult> _results;
  final ScrollController? scrollController;

  const GifGrid({
    super.key,
    required List<GifResult> results,
    this.scrollController,
  }) : _results = results;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: scrollController,
      itemCount: _results.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) {
        final gif = _results[index];
        return GifItem(gif: gif);
      },
    );
  }
}
