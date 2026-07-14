import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repository/stickers_repository.dart';
import 'sticker_pack_detail_state.dart';

class StickerPackDetailCubit extends Cubit<StickerPackDetailState> {
  StickerPackDetailCubit({required this.packId, StickersRepository? repository})
    : _repository = repository ?? StickersRepository.instance,
      super(StickerPackDetailLoading()) {
    load();
  }

  final String packId;
  final StickersRepository _repository;

  Future<void> load() async {
    emit(StickerPackDetailLoading());
    try {
      final stickers = await _repository.fetchStickers(packId);
      final downloadedIds = await _repository.getDownloadedPackIds();
      emit(
        StickerPackDetailLoaded(
          stickers: stickers,
          isDownloaded: downloadedIds.contains(packId),
        ),
      );
    } catch (e) {
      emit(StickerPackDetailError(e.toString()));
    }
  }

  Future<void> toggleDownloaded() async {
    final current = state;
    if (current is! StickerPackDetailLoaded) return;

    if (current.isDownloaded) {
      await _repository.removeDownloadedPack(packId);
    } else {
      await _repository.markPackDownloaded(packId);
    }
    emit(
      StickerPackDetailLoaded(
        stickers: current.stickers,
        isDownloaded: !current.isDownloaded,
      ),
    );
  }
}
