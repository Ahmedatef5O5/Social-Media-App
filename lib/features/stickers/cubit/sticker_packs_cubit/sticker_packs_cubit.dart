import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repository/stickers_repository.dart';
import 'sticker_packs_state.dart';

class StickerPacksCubit extends Cubit<StickerPacksState> {
  StickerPacksCubit({StickersRepository? repository})
    : _repository = repository ?? StickersRepository.instance,
      super(StickerPacksLoading()) {
    loadPacks();
  }

  final StickersRepository _repository;

  Future<void> loadPacks() async {
    emit(StickerPacksLoading());
    try {
      final packs = await _repository.fetchPacks();
      final downloaded = await _repository.getDownloadedPackIds();
      emit(StickerPacksLoaded(packs: packs, downloadedPackIds: downloaded));
    } catch (e) {
      emit(StickerPacksError(e.toString()));
    }
  }

  Future<void> togglePackDownloaded(String packId) async {
    final current = state;
    if (current is! StickerPacksLoaded) return;

    final isDownloaded = current.downloadedPackIds.contains(packId);
    if (isDownloaded) {
      await _repository.removeDownloadedPack(packId);
    } else {
      await _repository.markPackDownloaded(packId);
    }

    final updated = await _repository.getDownloadedPackIds();
    emit(StickerPacksLoaded(packs: current.packs, downloadedPackIds: updated));
  }
}
