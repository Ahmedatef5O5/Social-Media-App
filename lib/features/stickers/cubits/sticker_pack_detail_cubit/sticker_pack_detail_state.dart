import '../../models/sticker_model.dart';

abstract class StickerPackDetailState {}

class StickerPackDetailLoading extends StickerPackDetailState {}

class StickerPackDetailLoaded extends StickerPackDetailState {
  final List<StickerModel> stickers;
  final bool isDownloaded;
  final double? downloadProgress;

  StickerPackDetailLoaded({
    required this.stickers,
    required this.isDownloaded,
    this.downloadProgress,
  });

  StickerPackDetailLoaded copyWith({
    bool? isDownloaded,
    double? downloadProgress,
    bool clearProgress = false,
  }) {
    return StickerPackDetailLoaded(
      stickers: stickers,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      downloadProgress:
          clearProgress ? null : (downloadProgress ?? this.downloadProgress),
    );
  }
}

class StickerPackDetailError extends StickerPackDetailState {
  final String message;
  StickerPackDetailError(this.message);
}
