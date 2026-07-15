import 'package:flutter/material.dart';
import '../cubit/sticker_send_picker_cubit/sticker_send_picker_state.dart';
import 'sticker_thumbnail.dart';

class StickerGridItem extends StatelessWidget {
  const StickerGridItem({super.key, required this.loaded});

  final StickerSendPickerLoaded loaded;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: loaded.selectedStickers.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        final sticker = loaded.selectedStickers[index];
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).pop(sticker),
          child: StickerThumbnail(sticker: sticker),
        );
      },
    );
  }
}
