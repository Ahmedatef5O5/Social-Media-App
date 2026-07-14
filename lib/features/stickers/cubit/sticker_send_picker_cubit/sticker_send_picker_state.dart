import '../../model/sticker_model.dart';
import '../../model/sticker_pack_model.dart';

abstract class StickerSendPickerState {}

class StickerSendPickerLoading extends StickerSendPickerState {}

/// No packs downloaded yet — show a CTA to open the browser sheet.
class StickerSendPickerEmpty extends StickerSendPickerState {}

class StickerSendPickerLoaded extends StickerSendPickerState {
  final List<StickerPackModel> downloadedPacks;
  final int selectedIndex;
  final Map<String, List<StickerModel>> stickersByPack; // cache per pack
  final bool isLoadingSelectedPack;

  StickerSendPickerLoaded({
    required this.downloadedPacks,
    required this.selectedIndex,
    required this.stickersByPack,
    required this.isLoadingSelectedPack,
  });

  StickerPackModel get selectedPack => downloadedPacks[selectedIndex];
  List<StickerModel> get selectedStickers =>
      stickersByPack[selectedPack.id] ?? const [];

  StickerSendPickerLoaded copyWith({
    int? selectedIndex,
    Map<String, List<StickerModel>>? stickersByPack,
    bool? isLoadingSelectedPack,
  }) {
    return StickerSendPickerLoaded(
      downloadedPacks: downloadedPacks,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      stickersByPack: stickersByPack ?? this.stickersByPack,
      isLoadingSelectedPack:
          isLoadingSelectedPack ?? this.isLoadingSelectedPack,
    );
  }
}

class StickerSendPickerError extends StickerSendPickerState {
  final String message;
  StickerSendPickerError(this.message);
}
