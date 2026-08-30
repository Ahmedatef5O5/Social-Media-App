import '../../models/sticker_pack_model.dart';

abstract class StickerPacksState {}

class StickerPacksLoading extends StickerPacksState {}

class StickerPacksLoaded extends StickerPacksState {
  final List<StickerPackModel> packs;
  final Set<String> downloadedPackIds;
  final Map<String, double> downloadProgress;

  StickerPacksLoaded({
    required this.packs,
    required this.downloadedPackIds,
    this.downloadProgress = const {},
  });

  StickerPacksLoaded copyWith({
    List<StickerPackModel>? packs,
    Set<String>? downloadedPackIds,
    Map<String, double>? downloadProgress,
    Map<String, int>? packSizeBytes,
  }) {
    return StickerPacksLoaded(
      packs: packs ?? this.packs,
      downloadedPackIds: downloadedPackIds ?? this.downloadedPackIds,
      downloadProgress: downloadProgress ?? this.downloadProgress,
    );
  }
}

class StickerPacksError extends StickerPacksState {
  final String message;
  StickerPacksError(this.message);
}
