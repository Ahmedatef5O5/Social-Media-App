import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/cache/repository/media_cache_repository.dart';
import '../../../../core/errors/supabase_error_mapper.dart';
import '../../repository/stickers_repository.dart';
import 'sticker_packs_state.dart';

class StickerPacksCubit extends Cubit<StickerPacksState> {
  StickerPacksCubit({
    StickersRepository? repository,
    required MediaCacheRepository mediaCacheRepository,
  }) : _repository = repository ?? StickersRepository.instance,
       _mediaCache = mediaCacheRepository,
       super(StickerPacksLoading()) {
    loadPacks();
  }

  final StickersRepository _repository;
  final MediaCacheRepository _mediaCache;
  final Map<String, CancelToken> _activeDownloads = {};

  Future<void> loadPacks() async {
    emit(StickerPacksLoading());
    try {
      final packs = await _repository.fetchPacks();
      final downloaded = await _repository.getDownloadedPackIds();
      emit(StickerPacksLoaded(packs: packs, downloadedPackIds: downloaded));
    } catch (e) {
      emit(StickerPacksError(SupabaseErrorMapper.toUserMessage(e)));
    }
  }

  Future<void> togglePackDownloaded(String packId) async {
    final current = state;
    if (current is! StickerPacksLoaded) return;

    if (current.downloadedPackIds.contains(packId)) {
      await _removePack(packId);
    } else {
      await _downloadPack(packId);
    }
  }

  Future<void> _downloadPack(String packId) async {
    try {
      final stickers = await _repository.fetchStickers(packId);
      final totalWeight = stickers.fold<int>(0, (sum, s) => sum + s.sizeBytes);
      final fileProgress = <String, double>{};

      void report() {
        final overall =
            totalWeight > 0
                ? stickers.fold<double>(0, (sum, s) {
                  return sum +
                      (s.sizeBytes / totalWeight) *
                          (fileProgress[s.imageUrl] ?? 0);
                })
                : (fileProgress.values.isEmpty
                    ? 0.0
                    : fileProgress.values.fold<double>(0, (a, b) => a + b) /
                        stickers.length);

        final latest = state;
        if (latest is StickerPacksLoaded) {
          emit(
            latest.copyWith(
              downloadProgress: {...latest.downloadProgress, packId: overall},
            ),
          );
        }
      }

      final cancelToken = CancelToken();
      _activeDownloads[packId] = cancelToken;

      const concurrency = 5;
      for (var i = 0; i < stickers.length; i += concurrency) {
        final batch = stickers.skip(i).take(concurrency);
        await Future.wait(
          batch.map((sticker) async {
            await _mediaCache.resolveLocalPath(
              sticker.imageUrl,
              cancelToken: cancelToken,
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

      _activeDownloads.remove(packId);
      await _repository.markPackDownloaded(packId);

      final updatedIds = await _repository.getDownloadedPackIds();
      final latest = state;
      if (latest is StickerPacksLoaded) {
        final progress = {...latest.downloadProgress}..remove(packId);
        emit(
          latest.copyWith(
            downloadedPackIds: updatedIds,
            downloadProgress: progress,
          ),
        );
      }
    } catch (_) {
      _activeDownloads.remove(packId);
      final latest = state;
      if (latest is StickerPacksLoaded) {
        final progress = {...latest.downloadProgress}..remove(packId);
        emit(latest.copyWith(downloadProgress: progress));
      }
    }
  }

  Future<void> _removePack(String packId) async {
    await _repository.removeDownloadedPack(packId);
    try {
      final stickers = await _repository.fetchStickers(packId);
      for (final s in stickers) {
        unawaited(_mediaCache.invalidate(s.imageUrl));
      }
    } catch (e) {
      debugPrint(
        '[StickerPacksCubit] failed to fetch stickers for cache invalidation: $e',
      );
    }

    final updated = await _repository.getDownloadedPackIds();
    final latest = state;
    if (latest is StickerPacksLoaded) {
      emit(latest.copyWith(downloadedPackIds: updated));
    }
  }

  void cancelDownload(String packId) {
    final token = _activeDownloads.remove(packId);
    if (token == null || token.isCancelled) return;
    token.cancel('user_cancelled');

    final latest = state;
    if (latest is StickerPacksLoaded) {
      final progress = {...latest.downloadProgress}..remove(packId);
      emit(latest.copyWith(downloadProgress: progress));
    }
  }

  @override
  Future<void> close() {
    for (final token in _activeDownloads.values) {
      token.cancel();
    }
    return super.close();
  }
}
