import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repository/stickers_repository.dart';
import 'sticker_send_picker_state.dart';

class StickerSendPickerCubit extends Cubit<StickerSendPickerState> {
  StickerSendPickerCubit({StickersRepository? repository})
    : _repository = repository ?? StickersRepository.instance,
      super(StickerSendPickerLoading()) {
    load();
  }

  final StickersRepository _repository;

  Future<void> load() async {
    emit(StickerSendPickerLoading());
    try {
      final downloadedIds = await _repository.getDownloadedPackIds();
      if (downloadedIds.isEmpty) {
        emit(StickerSendPickerEmpty());
        return;
      }

      final allPacks = await _repository.fetchPacks();
      final downloadedPacks =
          allPacks.where((p) => downloadedIds.contains(p.id)).toList();

      if (downloadedPacks.isEmpty) {
        emit(StickerSendPickerEmpty());
        return;
      }

      emit(
        StickerSendPickerLoaded(
          downloadedPacks: downloadedPacks,
          selectedIndex: 0,
          stickersByPack: const {},
          isLoadingSelectedPack: true,
        ),
      );
      await _loadStickersForSelectedPack();
    } catch (e) {
      emit(StickerSendPickerError(e.toString()));
    }
  }

  Future<void> selectPack(int index) async {
    final current = state;
    if (current is! StickerSendPickerLoaded || index == current.selectedIndex) {
      return;
    }
    emit(current.copyWith(selectedIndex: index, isLoadingSelectedPack: true));
    await _loadStickersForSelectedPack();
  }

  Future<void> _loadStickersForSelectedPack() async {
    final current = state;
    if (current is! StickerSendPickerLoaded) return;

    final packId = current.selectedPack.id;
    if (current.stickersByPack.containsKey(packId)) {
      emit(current.copyWith(isLoadingSelectedPack: false));
      return;
    }

    try {
      final stickers = await _repository.fetchStickers(packId);
      final latest = state;
      if (latest is! StickerSendPickerLoaded) return;
      emit(
        latest.copyWith(
          stickersByPack: {...latest.stickersByPack, packId: stickers},
          isLoadingSelectedPack: false,
        ),
      );
    } catch (_) {
      final latest = state;
      if (latest is StickerSendPickerLoaded) {
        emit(latest.copyWith(isLoadingSelectedPack: false));
      }
    }
  }
}
