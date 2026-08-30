import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/cache/repository/media_cache_repository.dart';
import '../../../../core/errors/supabase_error_mapper.dart';
import '../../repository/stickers_repository.dart';
import 'sticker_pack_detail_state.dart';

class StickerPackDetailCubit extends Cubit<StickerPackDetailState> {
  final String packId;
  final StickersRepository _repository;
  final MediaCacheRepository _mediaCache;
  CancelToken? _cancelToken;

  StickerPackDetailCubit({
    required this.packId,
    StickersRepository? repository,
    required MediaCacheRepository mediaCacheRepository,
  }) : _repository = repository ?? StickersRepository.instance,
       _mediaCache = mediaCacheRepository,
       super(StickerPackDetailLoading()) {
    load();
  }

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
      emit(StickerPackDetailError(SupabaseErrorMapper.toUserMessage(e)));
    }
  }

  Future<void> toggleDownloaded() async {
    final current = state;
    if (current is! StickerPackDetailLoaded) return;

    if (current.isDownloaded) {
      await _repository.removeDownloadedPack(packId);
      for (final s in current.stickers) {
        unawaited(_mediaCache.invalidate(s.imageUrl));
      }
      emit(current.copyWith(isDownloaded: false));
      return;
    }
    await _download(current);
  }

  Future<void> _download(StickerPackDetailLoaded current) async {
    final totalWeight = current.stickers.fold<int>(
      0,
      (sum, s) => sum + s.sizeBytes,
    );
    final fileProgress = <String, double>{};
    _cancelToken = CancelToken();

    void report() {
      final overall =
          totalWeight > 0
              ? current.stickers.fold<double>(
                0,
                (sum, s) =>
                    sum +
                    (s.sizeBytes / totalWeight) *
                        (fileProgress[s.imageUrl] ?? 0),
              )
              : (fileProgress.values.isEmpty
                  ? 0.0
                  : fileProgress.values.fold<double>(0, (a, b) => a + b) /
                      current.stickers.length);
      final latest = state;
      if (latest is StickerPackDetailLoaded) {
        emit(latest.copyWith(downloadProgress: overall));
      }
    }

    try {
      const concurrency = 5;
      for (var i = 0; i < current.stickers.length; i += concurrency) {
        final batch = current.stickers.skip(i).take(concurrency);
        await Future.wait(
          batch.map((sticker) async {
            await _mediaCache.resolveLocalPath(
              sticker.imageUrl,
              cancelToken: _cancelToken,
              onProgress: (p) {
                fileProgress[sticker.imageUrl] = p;
                report();
              },
            );
            fileProgress[sticker.imageUrl] = 1.0;
            report();
          }),
        );
      }
      await _repository.markPackDownloaded(packId);
      final latest = state;
      if (latest is StickerPackDetailLoaded) {
        emit(latest.copyWith(isDownloaded: true, clearProgress: true));
      }
    } catch (_) {
      final latest = state;
      if (latest is StickerPackDetailLoaded) {
        emit(latest.copyWith(clearProgress: true));
      }
    }
  }

  void cancelDownload() {
    if (_cancelToken == null || _cancelToken!.isCancelled) return;
    _cancelToken!.cancel('user_cancelled');

    final latest = state;
    if (latest is StickerPackDetailLoaded) {
      emit(latest.copyWith(clearProgress: true));
    }
  }

  @override
  Future<void> close() {
    _cancelToken?.cancel();
    return super.close();
  }
}
