import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:social_media_app/core/supabase/supabase_provider.dart';
import 'package:social_media_app/core/utilities/supabase_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'package:social_media_app/core/cache/constants/snapshot_keys.dart';
import 'package:social_media_app/core/cache/services/local_snapshot_store.dart';
import 'package:social_media_app/core/services/cloudinary_storage_services.dart';
import 'package:social_media_app/core/services/file_picker_services.dart';
import 'package:social_media_app/core/services/fcm_services.dart';
import 'package:social_media_app/features/auth/data/models/user_data.dart';
import '../../../../core/connectivity/services/connectivity_banner_controller.dart';
import '../../../../core/toast/app_toast.dart';
import '../../../social_graph/models/content_privacy.dart';
import 'package:social_media_app/core/mentions/mentions.dart';
import '../../model/story_model.dart';
import '../../services/stories_services.dart';
part 'stories_state.dart';

const Duration kMaxStoryVideoDuration = Duration(seconds: 60);
const int kMaxCachedStoriesSnapshot = 30;

class StoriesCubit extends Cubit<StoriesState> {
  final StoriesServices _storiesServices;
  RealtimeChannel? _storiesChannel;

  StoriesCubit({StoriesServices? storiesServices})
    : _storiesServices = storiesServices ?? StoriesServices(),
      super(StoriesInitial()) {
    _monitorRealtimeStories();
  }

  List<StoryModel> cachedStories = [];
  final filePickerServices = FilePickerServices();
  final Map<String, ValueNotifier<double>> storyUploadProgress = {};
  final Map<String, dio_pkg.CancelToken> _uploadCancelTokens = {};
  File? selectedStoryFile;
  File? _stableVideoFile;

  void _monitorRealtimeStories() {
    _storiesChannel =
        SupabaseProvider.client
            .channel('public_stories_changes')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: SupabaseConstants.stories,
              callback: ((payload) {
                _silentReconcile();
              }),
            )
            .subscribe();
  }

  Future<void> _silentReconcile() async {
    try {
      final stories = await _storiesServices.fetchStories();
      cachedStories = stories;
      emit(StoriesLoaded(stories, DateTime.now()));
      _persistStoriesSnapshot(stories);
    } catch (e) {
      debugPrint('Silent stories reconcile failed: $e');
    }
  }

  // ── Story actions ──────────────────────────────────────────────────────────

  ValueNotifier<double> progressNotifierFor(String storyId) {
    return storyUploadProgress.putIfAbsent(
      storyId,
      () => ValueNotifier<double>(0),
    );
  }

  void _disposeProgressNotifier(String storyId) {
    storyUploadProgress.remove(storyId)?.dispose();
  }

  void cancelStoryUpload(String storyId) {
    _uploadCancelTokens[storyId]?.cancel();
    _uploadCancelTokens.remove(storyId);
  }

  Future<void> addTextStory({
    required String text,
    required Color bgColor,
    required UserData user,
    ContentPrivacy privacy = ContentPrivacy.public,
    List<String> allowedViewerIds = const [],
    List<MentionRef> mentions = const [],
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
        authorImageUrl: user.imageUrl,
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
      if (mentions.isNotEmpty) {
        await _storiesServices.insertStoryMentions(
          storyId: storyId,
          mentions: mentions,
        );
        for (final mention in mentions) {
          unawaited(
            FcmService.instance.notifyMention(
              receiverId: mention.mentionedUserId,
              actorId: user.id,
              actorName: user.name,
              actorImageUrl: user.imageUrl ?? '',
              context: 'story',
              storyId: storyId,
            ),
          );
        }
      }

      cachedStories = [newStory, ...cachedStories];
      emit(StoriesLoaded(cachedStories, DateTime.now()));
      emit(AddStorySuccess());
      unawaited(_silentReconcile());
    } catch (e) {
      debugPrint('Error adding text story: $e');
      final isOffline = await ConnectivityBannerController.notifyIfOffline();
      emit(AddStoryError(e.toString(), isConnectivityError: isOffline));
    }
  }

  Future<void> addStoryWithCaption({
    required File file,
    required UserData user,
    String? caption,
    ContentPrivacy privacy = ContentPrivacy.public,
    List<String> allowedViewerIds = const [],
    List<MentionRef> mentions = const [],
  }) async {
    final storyId = const Uuid().v4();
    final createdAt = DateTime.now().toIso8601String();

    final cancelToken = dio_pkg.CancelToken();
    _uploadCancelTokens[storyId] = cancelToken;

    try {
      final fileSizeBytes = await file.length();

      final pendingStory = StoryModel(
        id: storyId,
        imageUrl: file.path,
        authorId: user.id,
        authorName: user.name,
        authorImageUrl: user.imageUrl,
        createdAt: createdAt,
        caption: caption,
        fileSizeBytes: fileSizeBytes,
        privacyType: privacy,
      );
      cachedStories = [pendingStory, ...cachedStories];
      emit(StoriesLoaded(cachedStories, DateTime.now()));

      final result = await _storiesServices.uploadStoryFile(
        file,
        user.id,
        cancelToken: cancelToken,
        onProgress: (progress) {
          progressNotifierFor(storyId).value = progress;
        },
      );
      final newStory = StoryModel(
        id: storyId,
        imageUrl: result.secureUrl,
        imagePublicId: result.publicId,
        authorId: user.id,
        authorName: user.name,
        authorImageUrl: user.imageUrl,
        createdAt: createdAt,
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
      if (mentions.isNotEmpty) {
        await _storiesServices.insertStoryMentions(
          storyId: storyId,
          mentions: mentions,
        );
        for (final mention in mentions) {
          unawaited(
            FcmService.instance.notifyMention(
              receiverId: mention.mentionedUserId,
              actorId: user.id,
              actorName: user.name,
              actorImageUrl: user.imageUrl ?? '',
              context: 'story',
              storyId: storyId,
            ),
          );
        }
      }

      cachedStories = [
        newStory,
        ...cachedStories.where((s) => s.id != storyId),
      ];
      _disposeProgressNotifier(storyId);
      emit(StoriesLoaded(cachedStories, DateTime.now()));
      AppToast.success('Story Added Successfully');
      unawaited(_silentReconcile());
      _uploadCancelTokens.remove(storyId);
    } catch (e) {
      debugPrint('Error adding story with caption: $e');
      cachedStories = cachedStories.where((s) => s.id != storyId).toList();
      _disposeProgressNotifier(storyId);
      emit(StoriesLoaded(cachedStories, DateTime.now()));
      final isOffline = await ConnectivityBannerController.notifyIfOffline();
      if (!isOffline) AppToast.error(e.toString());
      emit(AddStoryError(e.toString(), isConnectivityError: isOffline));
    }
  }

  Future<void> addVideoStoryWithCaption({
    required File file,
    required UserData user,
    String? caption,
    Duration? videoDuration,
    ContentPrivacy privacy = ContentPrivacy.public,
    List<String> allowedViewerIds = const [],
    List<MentionRef> mentions = const [],
  }) async {
    final storyId = const Uuid().v4();
    final createdAt = DateTime.now().toIso8601String();

    final cancelToken = dio_pkg.CancelToken();
    _uploadCancelTokens[storyId] = cancelToken;

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

      final fileSizeBytes = await uploadFile.length();

      final pendingStory = StoryModel(
        id: storyId,
        videoUrl: uploadFile.path,
        authorId: user.id,
        authorName: user.name,
        authorImageUrl: user.imageUrl,
        createdAt: createdAt,
        caption: caption,
        videoDurationSeconds: videoDuration?.inSeconds,
        fileSizeBytes: fileSizeBytes,
        privacyType: privacy,
      );
      cachedStories = [pendingStory, ...cachedStories];
      emit(StoriesLoaded(cachedStories, DateTime.now()));

      final result = await _storiesServices.uploadStoryVideoFile(
        uploadFile,
        user.id,
        cancelToken: cancelToken,
        onProgress: (progress) {
          progressNotifierFor(storyId).value = progress;
        },
      );
      final newStory = StoryModel(
        id: storyId,
        videoUrl: result.secureUrl,
        videoPublicId: result.publicId,
        authorId: user.id,
        authorName: user.name,
        authorImageUrl: user.imageUrl,
        createdAt: createdAt,
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
      if (mentions.isNotEmpty) {
        await _storiesServices.insertStoryMentions(
          storyId: storyId,
          mentions: mentions,
        );
        for (final mention in mentions) {
          unawaited(
            FcmService.instance.notifyMention(
              receiverId: mention.mentionedUserId,
              actorId: user.id,
              actorName: user.name,
              actorImageUrl: user.imageUrl ?? '',
              context: 'story',
              storyId: storyId,
            ),
          );
        }
      }

      cachedStories = [
        newStory,
        ...cachedStories.where((s) => s.id != storyId),
      ];
      _disposeProgressNotifier(storyId);
      _cleanupStableVideo();
      emit(StoriesLoaded(cachedStories, DateTime.now()));
      AppToast.success('Story Added Successfully');
      unawaited(_silentReconcile());
      _uploadCancelTokens.remove(storyId);
    } on UploadCanceledException {
      cachedStories = cachedStories.where((s) => s.id != storyId).toList();
      _disposeProgressNotifier(storyId);
      emit(StoriesLoaded(cachedStories, DateTime.now()));
    } catch (e) {
      debugPrint('Error adding video story: $e');
      cachedStories = cachedStories.where((s) => s.id != storyId).toList();
      _disposeProgressNotifier(storyId);
      emit(StoriesLoaded(cachedStories, DateTime.now()));
      final isOffline = await ConnectivityBannerController.notifyIfOffline();
      if (!isOffline) AppToast.error(e.toString());
      emit(AddStoryError(e.toString(), isConnectivityError: isOffline));

      if (e.toString().contains('session_expired')) {
        emit(AddStoryError('Your session has expired; please log in again'));
      }
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

  Future<void> pickAndPreviewVideoStory({required ImageSource source}) async {
    if (state is StoryVideoPicked) return;

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

  // ── Stories fetch ──────────────────────────────────────────────────────────

  Future<void> fetchAuthorStories(String authorId) async {
    if (state is! StoriesLoading) emit(StoriesLoading());
    try {
      final stories = await _storiesServices.getAuthorStories(authorId);
      cachedStories = stories;
      emit(StoriesLoaded(stories, DateTime.now()));
    } catch (e) {
      debugPrint('Error fetching author stories: $e');
      emit(StoriesError(e.toString()));
    }
  }

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

  List<StoryModel> readCachedSnapshot() => _readStoriesSnapshot();

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

  @override
  Future<void> close() {
    _storiesChannel?.unsubscribe();
    _cleanupStableVideo();
    for (final notifier in storyUploadProgress.values) {
      notifier.dispose();
    }
    return super.close();
  }
}
