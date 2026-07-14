import '../../model/sticker_model.dart';

abstract class StickerPackDetailState {}

class StickerPackDetailLoading extends StickerPackDetailState {}

class StickerPackDetailLoaded extends StickerPackDetailState {
  final List<StickerModel> stickers;
  final bool isDownloaded;

  StickerPackDetailLoaded({required this.stickers, required this.isDownloaded});
}

class StickerPackDetailError extends StickerPackDetailState {
  final String message;
  StickerPackDetailError(this.message);
}
