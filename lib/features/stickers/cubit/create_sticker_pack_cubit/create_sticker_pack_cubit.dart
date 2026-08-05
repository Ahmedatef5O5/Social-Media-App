import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/core/services/file_picker_services.dart';
import 'package:social_media_app/core/supabase/supabase_provider.dart';
import 'package:social_media_app/core/toast/app_toast.dart';
import 'package:social_media_app/features/social_graph/services/friendship_services.dart';
import '../../../../core/cache/repository/media_cache_repository.dart';
import '../../../../core/services/cloudinary_storage_services.dart';
import '../../../../core/services/media_cleanup_service.dart';
import '../../model/sticker_pack_privacy.dart';
import '../../repository/stickers_repository.dart';
import 'create_sticker_pack_state.dart';

class CreateStickerPackCubit extends Cubit<CreateStickerPackState> {
  final StickersRepository _repository;
  final FilePickerServices _filePicker;
  final MediaCacheRepository _mediaCache;
  CancelToken? _uploadCancelToken;

  CreateStickerPackCubit({
    StickersRepository? repository,
    FilePickerServices? filePickerServices,
    required MediaCacheRepository mediaCacheRepository,
    this.onReadyToUpload,
  }) : _repository = repository ?? StickersRepository.instance,
       _filePicker = filePickerServices ?? FilePickerServices(),
       _mediaCache = mediaCacheRepository,
       super(CreateStickerPackLoading()) {
    _checkQuota();
  }

  final void Function({
    required String title,
    required List<XFile> images,
    required StickerPackPrivacy privacy,
    required Set<String> friendIds,
  })?
  onReadyToUpload;

  Future<void> _checkQuota() async {
    emit(CreateStickerPackLoading());
    try {
      final myPacks = await _repository.fetchMyPacks();
      if (myPacks.length >= 3) {
        emit(CreateStickerPackQuotaBlocked(myPacks: myPacks));
      } else {
        emit(CreateStickerPackForm());
      }
    } catch (e) {
      emit(CreateStickerPackError(e.toString()));
    }
  }

  Future<void> deleteAndRetry(String packId) async {
    final current = state;
    if (current is! CreateStickerPackQuotaBlocked) return;
    emit(current.copyWith(isDeleting: true));
    try {
      await _repository.deleteMyPack(packId);
      await _checkQuota();
    } catch (_) {
      AppToast.error('Could not delete the pack, please try again.');
      emit(current.copyWith(isDeleting: false));
    }
  }

  void setTitle(String title) {
    final current = state;
    if (current is! CreateStickerPackForm) return;
    emit(current.copyWith(title: title));
  }

  void setPrivacy(StickerPackPrivacy privacy) {
    final current = state;
    if (current is! CreateStickerPackForm) return;
    emit(
      current.copyWith(
        privacy: privacy,
        selectedFriendIds:
            privacy == StickerPackPrivacy.friends
                ? current.selectedFriendIds
                : {},
      ),
    );
    if (privacy == StickerPackPrivacy.friends) _loadFriendsIfNeeded();
  }

  Future<void> _loadFriendsIfNeeded() async {
    final current = state;
    if (current is! CreateStickerPackForm || current.allFriends.isNotEmpty) {
      return;
    }
    try {
      final friends = await FriendshipServices().getFriends(
        SupabaseProvider.id,
      );
      final latest = state;
      if (latest is CreateStickerPackForm) {
        emit(latest.copyWith(allFriends: friends));
      }
    } catch (_) {
      // Silently ignore — the sheet will just show empty and the user can reopen it.
    }
  }

  void toggleFriend(String userId) {
    final current = state;
    if (current is! CreateStickerPackForm) return;
    final updated = {...current.selectedFriendIds};
    if (!updated.add(userId)) updated.remove(userId);
    emit(current.copyWith(selectedFriendIds: updated));
  }

  Future<void> pickImages() async {
    final current = state;
    if (current is! CreateStickerPackForm) return;

    List<XFile> picked;
    try {
      picked = await _filePicker.pickMultipleImagesFromGallery();
    } catch (_) {
      AppToast.error('Could not open the gallery, please try again.');
      return;
    }
    if (picked.isEmpty) return;

    final remainingSlots =
        CreateStickerPackForm.maxStickers - current.images.length;
    if (remainingSlots <= 0) {
      AppToast.warning(
        'This pack already has the maximum of '
        '${CreateStickerPackForm.maxStickers} stickers.',
      );
      return;
    }
    if (picked.length > remainingSlots) {
      AppToast.warning(
        'Only the first $remainingSlots image(s) were added — '
        'a pack can hold at most ${CreateStickerPackForm.maxStickers} stickers.',
      );
      picked = picked.take(remainingSlots).toList();
    }

    int addedSize = 0;
    for (final file in picked) {
      addedSize += await file.length();
    }
    final newTotalSize = current.totalSizeBytes + addedSize;

    if (newTotalSize > CreateStickerPackForm.maxTotalSizeBytes) {
      AppToast.warning(
        'This selection pushes the pack past the 25 MB limit — '
        'pick fewer or smaller images.',
      );
      return;
    }

    emit(
      current.copyWith(
        images: [...current.images, ...picked],
        totalSizeBytes: newTotalSize,
      ),
    );
  }

  Future<void> removeImage(int index) async {
    final current = state;
    if (current is! CreateStickerPackForm) return;
    final removed = current.images[index];
    final removedSize = await removed.length();
    final updated = [...current.images]..removeAt(index);
    emit(
      current.copyWith(
        images: updated,
        totalSizeBytes: (current.totalSizeBytes - removedSize).clamp(
          0,
          1 << 62,
        ),
      ),
    );
  }

  Future<void> submit() async {
    final current = state;
    if (current is! CreateStickerPackForm) return;

    if (current.title.trim().isEmpty) {
      AppToast.warning('Give your pack a name first.');
      return;
    }
    if (current.images.isEmpty) {
      AppToast.warning('Add at least one sticker.');
      return;
    }
    if (current.privacy == StickerPackPrivacy.friends &&
        current.selectedFriendIds.isEmpty) {
      AppToast.warning(
        'Pick at least one friend, or change the privacy setting.',
      );
      return;
    }

    emit(current.copyWith(isSubmitting: true));
    try {
      final myPacks = await _repository.fetchMyPacks();
      if (myPacks.length >= 3) {
        emit(CreateStickerPackQuotaBlocked(myPacks: myPacks));
        return;
      }
    } catch (_) {
      emit(current.copyWith(isSubmitting: false));
      AppToast.error('Could not verify your pack quota, please try again.');
      return;
    }

    await _uploadAndCreatePack(current);
  }

  Future<void> _uploadAndCreatePack(CreateStickerPackForm form) async {
    final sizes = <int>[];
    for (final image in form.images) {
      sizes.add(await image.length());
    }
    final totalBytes = sizes.fold<int>(0, (a, b) => a + b);
    final completedFlags = List<bool>.filled(form.images.length, false);
    int sentBeforeCurrentFile = 0;
    _uploadCancelToken = CancelToken();

    emit(
      CreateStickerPackUploading(
        title: form.title.trim(),
        privacy: form.privacy,
        images: form.images,
        completedFlags: List<bool>.from(completedFlags),
        uploadedBytes: 0,
        totalBytes: totalBytes,
      ),
    );

    final uploaded = <Map<String, dynamic>>[];
    final uploadedPublicIds = <String>[];
    try {
      for (var i = 0; i < form.images.length; i++) {
        final image = form.images[i];
        final result = await CloudinaryStorageServices.instance.uploadFile(
          File(image.path),
          'stickers',
          'user_${SupabaseProvider.id}',
          filePrefix: 'sticker_',
          cancelToken: _uploadCancelToken,
          onProgressBytes: (sent, total) {
            final latest = state;
            if (latest is CreateStickerPackUploading) {
              emit(
                latest.copyWith(uploadedBytes: sentBeforeCurrentFile + sent),
              );
            }
          },
        );

        sentBeforeCurrentFile += sizes[i];
        completedFlags[i] = true;
        uploadedPublicIds.add(result.publicId);

        uploaded.add({
          'image_url': result.secureUrl,
          'is_animated': false,
          'format': image.path.split('.').last.toLowerCase(),
          'size_bytes': sizes[i],
        });

        final latest = state;
        if (latest is CreateStickerPackUploading) {
          emit(
            latest.copyWith(
              completedFlags: List<bool>.from(completedFlags),
              uploadedBytes: sentBeforeCurrentFile,
            ),
          );
        }
      }

      final pack = await _repository.createUserPack(
        title: form.title.trim(),
        privacy: form.privacy,
        stickers: uploaded,
        friendIds: form.selectedFriendIds,
      );
      await _repository.markPackDownloaded(pack.id);

      for (var i = 0; i < form.images.length; i++) {
        unawaited(
          _mediaCache.adoptUploadedFile(
            uploaded[i]['image_url'] as String,
            File(form.images[i].path),
          ),
        );
      }

      emit(CreateStickerPackSuccess(pack));
    } catch (e) {
      if (e is UploadCanceledException) {
        if (uploadedPublicIds.isNotEmpty) {
          unawaited(
            MediaCleanupService.instance.deleteRawAssets(
              publicIds: List<String>.from(uploadedPublicIds),
              resourceType: 'image',
            ),
          );
        }
        AppToast.warning('Upload cancelled.');
        emit(form.copyWith(isSubmitting: false));
      } else {
        AppToast.error('Could not create the pack, please try again.');
        emit(form.copyWith(isSubmitting: false));
      }
    }
  }

  void cancelUpload() {
    _uploadCancelToken?.cancel('user_cancelled');
  }
}
