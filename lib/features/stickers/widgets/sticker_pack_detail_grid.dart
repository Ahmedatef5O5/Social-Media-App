import 'package:flutter/material.dart';
import '../cubit/sticker_pack_detail_cubit/sticker_pack_detail_state.dart';
import 'sticker_thumbnail.dart';

class StickerPackDetailGrid extends StatelessWidget {
  final StickerPackDetailLoaded loaded;
  final ThemeData theme;
  const StickerPackDetailGrid({
    super.key,
    required this.loaded,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GridView.builder(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: loaded.stickers.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemBuilder: (context, index) {
          final sticker = loaded.stickers[index];
          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.25,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: StickerThumbnail(sticker: sticker),
              ),
            ),
          );
        },
      ),
    );
  }
}
