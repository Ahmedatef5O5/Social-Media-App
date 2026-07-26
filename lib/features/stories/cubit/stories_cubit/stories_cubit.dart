import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'package:social_media_app/core/cache/constants/snapshot_keys.dart';
import 'package:social_media_app/core/cache/services/local_snapshot_store.dart';
import 'package:social_media_app/core/services/cloudinary_storage_services.dart';
import 'package:social_media_app/core/services/file_picker_services.dart';
import 'package:social_media_app/features/auth/data/models/user_data.dart';
import '../../../../core/connectivity/services/connectivity_banner_controller.dart';
import '../../../social_graph/models/content_privacy.dart';
import '../../model/story_model.dart';
import '../../services/stories_services.dart';
part 'stories_state.dart';

const Duration kMaxStoryVideoDuration = Duration(seconds: 60);
const int kMaxCachedStoriesSnapshot = 30;

class StoriesCubit extends Cubit<StoriesState> {
  final StoriesServices _storiesServices;

  StoriesCubit({StoriesServices? storiesServices})
    : _storiesServices = storiesServices ?? StoriesServices(),
      super(StoriesInitial());

  List<StoryModel> cachedStories = [];
  final filePickerServices = FilePickerServices();
  File? selectedStoryFile;
  File? _stableVideoFile;

  @override
  Future<void> close() {
    _cleanupStableVideo();
    return super.close();
  }

  // ── Story actions ──────────────────────────────────────────────────────────

  Future<void> addTextStory({
    required String text,
    required Color bgColor,
    required UserData user,
    ContentPrivacy privacy = ContentPrivacy.public,
    List<String> allowedViewerIds = const [],
  }) async {
    emit(AddStoryLoading());
    try {
      final storyId = const Uuid().v4();
      final newStory = StoryModel(
        id: storyId,
        contentText: text,
        backgroundColor: bgColor.toARGB32().toRadixString(16),
        authorId: user.id,
        authorName: user.name,
        createdAt: DateTime.now().toIso8601String(),
        imageUrl: null,
        privacyType: privacy,
      );
      await _storiesServices.createStory(newStory);
      if (privacy == ContentPrivacy.private && allowedViewerIds.isNotEmpty) {
        await _storiesServices.setStoryAllowedViewers(
          storyId,
          allowedViewerIds,
        );
      }
      await fetchStories();
      emit(AddStorySuccess());
      await Future.delayed(const Duration(milliseconds: 100));
      emit(StoriesLoaded(cachedStories, DateTime.now()));
    } catch (e) {
      debugPrint('Error adding text story: $e');
      final isOffline = await ConnectivityBannerController.notifyIfOffline();
      emit(AddStoryError(e.toString(), isConnectivityError: isOffline));
    }
  }

  Future<void> addStory({
    required File file,
    required UserData user,
    ContentPrivacy privacy = ContentPrivacy.public,
    List<String> allowedViewerIds = const [],
  }) async {
    emit(AddStoryLoading());
    try {
      final result = await _storiesServices.uploadStoryFile(file, user.id);
      final storyId = Uuid().v4();
      final newStory = StoryModel(
        id: storyId,
        imageUrl: result.secureUrl,
        imagePublicId: result.publicId,
        authorId: user.id,
        authorName: user.name,
        createdAt: DateTime.now().toIso8601String(),
      );
      await _storiesServices.createStory(newStory);
      if (privacy == ContentPrivacy.private && allowedViewerIds.isNotEmpty) {
        await _storiesServices.setStoryAllowedViewers(
          storyId,
          allowedViewerIds,
        );
      }
      await fetchStories();
      await Future.delayed(const Duration(milliseconds: 100));
      emit(StoriesLoaded(cachedStories, DateTime.now()));
    } catch (e) {
      debugPrint('Error adding story: $e');
      final isOffline = await ConnectivityBannerController.notifyIfOffline();
      emit(AddStoryError(e.toString(), isConnectivityError: isOffline));
    }
  }

  Future<void> deleteStory(String storyId) async {
    try {
      await _storiesServices.deleteStory(storyId);
      cachedStories = cachedStories.where((s) => s.id != storyId).toList();
      if (state is StoriesLoaded) {
        final updateStories =
            (state as StoriesLoaded).stories
                .where((s) => s.id != storyId)
                .toList();
        emit(StoriesLoaded(updateStories, DateTime.now()));
      } else {
        emit(StoriesLoaded(cachedStories, DateTime.now()));
      }
    } catch (e) {
      debugPrint('Error deleting story: $e');
    }
  }

  Future<void> pickAndAddStory({required ImageSource source}) async {
    try {
      final XFile? pickedFile =
          source == ImageSource.camera
              ? await filePickerServices.takePhotoByCamera()
              : await filePickerServices.pickImageFromGallery();

      if (pickedFile == null) return;

      final file = await _writeToAppDir(xFile: pickedFile, extension: 'jpg');
      selectedStoryFile = file;
      emit(StoryImagePicked(file: file));
    } catch (e) {
      debugPrint('Error in pickAndAddStory: $e');
      emit(AddStoryError(e.toString()));
    }
  }

  // TODO : Do not repeat this func addStory & addStoryWithCaption ... solve that  DRY

  Future<void> addStoryWithCaption({
    required File file,
    required UserData user,
    String? caption,
    ContentPrivacy privacy = ContentPrivacy.public,
    List<String> allowedViewerIds = const [],
  }) async {
    emit(AddStoryLoading());
    try {
      final result = await _storiesServices.uploadStoryFile(file, user.id);
      final storyId = const Uuid().v4();
      final newStory = StoryModel(
        id: storyId,
        imageUrl: result.secureUrl,
        imagePublicId: result.publicId,
        authorId: user.id,
        authorName: user.name,
        createdAt: DateTime.now().toIso8601String(),
        caption: caption,
        privacyType: privacy,
      );
      await _storiesServices.createStory(newStory);
      if (privacy == ContentPrivacy.private && allowedViewerIds.isNotEmpty) {
        await _storiesServices.setStoryAllowedViewers(
          storyId,
          allowedViewerIds,
        );
      }
      await fetchStories();
      emit(AddStorySuccess());
      await Future.delayed(const Duration(milliseconds: 100));
      emit(StoriesLoaded(cachedStories, DateTime.now()));
    } catch (e) {
      debugPrint('Error adding story with caption: $e');
      final isOffline = await ConnectivityBannerController.notifyIfOffline();
      emit(AddStoryError(e.toString(), isConnectivityError: isOffline));
    }
  }

  Future<void> pickAndPreviewVideoStory({required ImageSource source}) async {
    try {
      final XFile? pickedFile =
          source == ImageSource.camera
              ? await filePickerServices.takeVideoByCamera()
              : await filePickerServices.pickVideoFromGallery();

      if (pickedFile == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final destPath =
          '${appDir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4';

      final stableFile = await File(pickedFile.path).copy(destPath);

      if (!await stableFile.exists()) {
        emit(const StoryVideoPickError('Could not process the video file.'));
        return;
      }

      final duration = await _getVideoDuration(stableFile);

      if (duration > kMaxStoryVideoDuration) {
        // ignore: body_might_complete_normally_catch_error
        await stableFile.delete().catchError((_) {});
        emit(
          StoryVideoTooLong(
            videoDuration: duration,
            maxAllowed: kMaxStoryVideoDuration,
          ),
        );
        return;
      }

      _stableVideoFile = stableFile;
      selectedStoryFile = stableFile;
      emit(StoryVideoPicked(file: stableFile, videoDuration: duration));
    } catch (e) {
      debugPrint('Error picking video story: $e');
      emit(StoryVideoPickError(e.toString()));
    }
  }

  Future<void> addVideoStoryWithCaption({
    required File file,
    required UserData user,
    String? caption,
    Duration? videoDuration,
    ContentPrivacy privacy = ContentPrivacy.public,
    List<String> allowedViewerIds = const [],
  }) async {
    emit(AddStoryLoading());
    try {
      final File uploadFile =
          (_stableVideoFile != null && await _stableVideoFile!.exists())
              ? _stableVideoFile!
              : (await file.exists()
                  ? file
                  : throw PathNotFoundException(
                    file.path,
                    const OSError('File not found', 2),
                  ));

      final result = await _storiesServices.uploadStoryVideoFile(
        uploadFile,
        user.id,
      );
      final storyId = const Uuid().v4();
      final newStory = StoryModel(
        id: storyId,
        videoUrl: result.secureUrl,
        videoPublicId: result.publicId,
        authorId: user.id,
        authorName: user.name,
        createdAt: DateTime.now().toIso8601String(),
        caption: caption,
        videoDurationSeconds: videoDuration?.inSeconds,
        privacyType: privacy,
      );
      await _storiesServices.createStory(newStory);
      if (privacy == ContentPrivacy.private && allowedViewerIds.isNotEmpty) {
        await _storiesServices.setStoryAllowedViewers(
          storyId,
          allowedViewerIds,
        );
      }
      await fetchStories(isRefresh: true);
      _cleanupStableVideo();
      emit(AddStorySuccess());
      await Future.delayed(const Duration(milliseconds: 300));
      emit(StoriesLoaded(cachedStories, DateTime.now()));
    } on UploadCanceledException {
      return;
    } catch (e) {
      debugPrint('Error adding video story: $e');
      final isOffline = await ConnectivityBannerController.notifyIfOffline();
      emit(AddStoryError(e.toString(), isConnectivityError: isOffline));

      if (e.toString().contains('session_expired')) {
        emit(AddStoryError('Your session has expired; please log in again'));
        return;
      }
    }
  }

  // ── Stories fetch ──────────────────────────────────────────────────────────

  Future<void> fetchStories({bool isRefresh = false}) async {
    if (!isRefresh && state is! StoriesLoading) emit(StoriesLoading());
    try {
      final stories = await _storiesServices.fetchStories();
      cachedStories = stories;
      emit(StoriesLoaded(stories, DateTime.now()));
      _persistStoriesSnapshot(stories);
    } catch (e) {
      debugPrint('Error fetching stories: $e');
      if (cachedStories.isNotEmpty) {
        debugPrint('Silent error: no internet, showing cached stories.');
        emit(StoriesLoaded(cachedStories, DateTime.now()));
        return;
      }
      final diskStories = _readStoriesSnapshot();
      if (diskStories.isNotEmpty) {
        debugPrint(
          'Silent error: no internet, showing stories snapshot from disk.',
        );
        cachedStories = diskStories;
        emit(StoriesLoaded(diskStories, DateTime.now()));
        return;
      }
      emit(StoriesError(e.toString()));
    }
  }

  void _persistStoriesSnapshot(List<StoryModel> stories) {
    unawaited(
      LocalSnapshotStore.instance.saveList(
        SnapshotKeys.stories,
        stories
            .take(kMaxCachedStoriesSnapshot)
            .map((story) => story.toCacheJson())
            .toList(),
      ),
    );
  }

  List<StoryModel> _readStoriesSnapshot() {
    try {
      return LocalSnapshotStore.instance
          .readList(SnapshotKeys.stories)
          .map(StoryModel.fromCacheJson)
          .toList();
    } catch (e) {
      debugPrint('Failed to read stories snapshot from disk: $e');
      return [];
    }
  }

  Future<File> _writeToAppDir({
    required XFile xFile,
    required String extension,
  }) async {
    final bytes = await xFile.readAsBytes();
    final appDir = await getApplicationDocumentsDirectory();
    final destPath =
        '${appDir.path}/${DateTime.now().millisecondsSinceEpoch}.$extension';
    return File(destPath).writeAsBytes(bytes);
  }

  Future<Duration> _getVideoDuration(File file) async {
    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      return controller.value.duration;
    } finally {
      await controller.dispose();
    }
  }

  void _cleanupStableVideo() {
    // ignore: body_might_complete_normally_catch_error
    _stableVideoFile?.delete().catchError((_) {});
    _stableVideoFile = null;
  }
}
