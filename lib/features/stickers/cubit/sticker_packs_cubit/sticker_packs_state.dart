import '../../model/sticker_pack_model.dart';

abstract class StickerPacksState {}

class StickerPacksLoading extends StickerPacksState {}

class StickerPacksLoaded extends StickerPacksState {
  final List<StickerPackModel> packs;
  final Set<String> downloadedPackIds;

  StickerPacksLoaded({required this.packs, required this.downloadedPackIds});
}

class StickerPacksError extends StickerPacksState {
  final String message;
  StickerPacksError(this.message);
}
