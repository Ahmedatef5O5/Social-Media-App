part of 'group_details_cubit.dart';

mixin GroupMediaUploadMixin on Cubit<GroupDetailsState> {
  GroupChatServices get _services;
  GroupModel get group;
  GroupListCubit get groupListCubit;
  String get currentUserId;
  List<GroupMessageModel> get cachedMessages;
  set cachedMessages(List<GroupMessageModel> value);
  Map<String, double> get uploadProgressMap;
  ValueNotifier<GroupMessageModel?> get replyToMessage;
  AudioCompressionService get _audioCompressionService;
  MediaCacheRepository get _mediaCacheRepository;

  void _emitLoaded();

  final Map<String, dio_pkg.CancelToken> _cancelTokens = {};

  Future<void> sendMessage({
    required String text,
    String messageType = 'text',
    File? imageFile,
    File? videoFile,
    File? voiceFile,
    int? durationSeconds,
    File? documentFile,
    String? fileName,
    int? fileSizeBytes,
    String? remoteImageUrl,
    List<MentionRef> mentions = const [],
    String? caption,
    String? forwardedFromUserId,
    String? forwardedFromUserName,
    String? forwardedFromUserAvatar,
  }) async {
    final isOffline = await ConnectivityBannerController.notifyIfOffline();
    if (isOffline) return;

    if (text.trim().isEmpty &&
        imageFile == null &&
        videoFile == null &&
        voiceFile == null &&
        documentFile == null &&
        remoteImageUrl == null) {
      return;
    }

    final userProfile = await _services.getUserInfo(currentUserId);

    final senderName = userProfile['name'] ?? 'Me';
    final senderAvatar = userProfile['imageUrl'] ?? '';

    final reply = replyToMessage.value;
    replyToMessage.value = null;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    final cancelToken = dio_pkg.CancelToken();
    _cancelTokens[tempId] = cancelToken;

    final tempMsg = GroupMessageModel(
      id: tempId,
      groupId: group.id,
      senderId: currentUserId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      text: text,
      createdAt: DateTime.now(),
      messageType: messageType,
      imageUrl: remoteImageUrl ?? imageFile?.path,
      videoUrl: videoFile?.path,
      voiceUrl: voiceFile?.path,
      durationSeconds: durationSeconds,
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      mentions: mentions,
      replyToMessageId: reply?.id,
      replyToText: reply?.text,
      replyToSenderId: reply?.senderId,
      replyToSenderName: reply?.senderName,
      replyToMessageType: reply?.messageType,
      forwardedFromUserId: forwardedFromUserId,
      forwardedFromUserName: forwardedFromUserName,
      forwardedFromUserAvatar: forwardedFromUserAvatar,
    );
    cachedMessages = [tempMsg, ...cachedMessages];
    _emitLoaded();

    try {
      String? uploadedImageUrl,
          uploadedVideoUrl,
          uploadedVoiceUrl,
          uploadedFileUrl;
      String? imagePublicId, videoPublicId, voicePublicId, filePublicId;

      if (remoteImageUrl != null) {
        uploadedImageUrl = remoteImageUrl;
      } else if (imageFile != null) {
        uploadProgressMap[tempId] = 0;
        final result = await _services.storage.uploadFile(
          imageFile,
          'group_chats',
          currentUserId,
          filePrefix: 'group_',
          cancelToken: cancelToken,
          onProgress: (p) {
            uploadProgressMap[tempId] = p;
            (this as GroupDetailsCubit).progressNotifierFor(tempId).value = p;
          },
        );
        uploadedImageUrl = result.secureUrl;
        imagePublicId = result.publicId;
        await _mediaCacheRepository.adoptUploadedFile(
          uploadedImageUrl,
          imageFile,
        );
        uploadProgressMap.remove(tempId);
        (this as GroupDetailsCubit).disposeProgressNotifier(tempId);
      }

      if (videoFile != null) {
        uploadProgressMap[tempId] = 0;
        final result = await _services.storage.uploadFile(
          videoFile,
          'group_chats',
          currentUserId,
          filePrefix: 'group_',
          cancelToken: cancelToken,
          onProgress: (p) {
            uploadProgressMap[tempId] = p;
            (this as GroupDetailsCubit).progressNotifierFor(tempId).value = p;
          },
        );
        uploadedVideoUrl = result.secureUrl;
        videoPublicId = result.publicId;
        await _mediaCacheRepository.adoptUploadedFile(
          uploadedVideoUrl,
          videoFile,
        );
        (this as GroupDetailsCubit).disposeProgressNotifier(tempId);
      }

      if (voiceFile != null) {
        uploadProgressMap[tempId] = 0.0;
        _emitLoaded();
        final compression = await _audioCompressionService.compress(voiceFile);
        try {
          final result = await _services.storage.uploadFile(
            compression.fileToUpload,
            'group_chats',
            currentUserId,
            filePrefix: 'group_',
            cancelToken: cancelToken,
            onProgress: (p) {
              uploadProgressMap[tempId] = p;
              _emitLoaded();
            },
          );
          uploadedVoiceUrl = result.secureUrl;
          voicePublicId = result.publicId;
          uploadProgressMap.remove(tempId);
        } finally {
          await _audioCompressionService.cleanup(compression);
        }
      }
      if (documentFile != null) {
        uploadProgressMap[tempId] = 0;
        final result = await _services.storage.uploadFile(
          documentFile,
          'group_chats',
          currentUserId,
          filePrefix: 'group_',
          cancelToken: cancelToken,
          onProgress: (p) {
            uploadProgressMap[tempId] = p;
            (this as GroupDetailsCubit).progressNotifierFor(tempId).value = p;
          },
        );
        uploadedFileUrl = result.secureUrl;
        filePublicId = result.publicId;
        await _mediaCacheRepository.adoptUploadedFile(
          uploadedFileUrl,
          documentFile,
        );
        (this as GroupDetailsCubit).disposeProgressNotifier(tempId);
      }

      await _services.sendGroupMessage(
        groupId: group.id,
        groupName: group.name,
        groupImageUrl: group.avatarUrl,
        text: text,
        messageType: messageType,
        imageUrl: uploadedImageUrl,
        videoUrl: uploadedVideoUrl,
        voiceUrl: uploadedVoiceUrl,
        fileUrl: uploadedFileUrl,
        fileName: fileName,
        fileSizeBytes: fileSizeBytes,
        caption: caption,
        replyTo: reply,
        imagePublicId: imagePublicId,
        videoPublicId: videoPublicId,
        voicePublicId: voicePublicId,
        durationSeconds: durationSeconds,
        filePublicId: filePublicId,
        mentions: mentions,
        forwardedFromUserId: forwardedFromUserId,
        forwardedFromUserName: forwardedFromUserName,
        forwardedFromUserAvatar: forwardedFromUserAvatar,
      );
      final memberIds =
          group.members
              .map((m) => m.userId)
              .where((id) => id != currentUserId)
              .toList();

      final notificationFutures = memberIds.map(
        (memberId) => NotificationRepository.instance.notifyGroupMessage(
          receiverId: memberId,
          senderId: currentUserId,
          senderName: senderName,
          senderImageUrl: senderAvatar,
          groupId: group.id,
          groupName: group.name,
          messageBody: text.isNotEmpty ? text : (caption ?? ''),
          messageType: messageType,
        ),
      );
      unawaited(
        Future.wait(notificationFutures, eagerError: false).catchError((e) {
          debugPrint('Notification batch error: $e');
          return <void>[];
        }),
      );

      final rawPreview = switch (messageType) {
        'image' => caption ?? '',
        'video' => caption ?? '',
        'voice' => '',
        'file' => fileName ?? 'File',
        _ => text,
      };

      groupListCubit.updateGroupLastMessage(
        groupId: group.id,
        message: rawPreview,
        messageId: tempId,
        messageType: messageType,
        createdAt: DateTime.now(),
        lastMessageSenderId: currentUserId,
        lastMessageSenderName: senderName,
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (!(this as Cubit).isClosed) {
          cachedMessages.removeWhere((m) => m.id == tempId);
          _emitLoaded();
        }
      });
    } on UploadCanceledException {
      return;
    } catch (e) {
      cachedMessages.removeWhere((m) => m.id == tempId);
      uploadProgressMap.remove(tempId);

      final isOffline = await ConnectivityBannerController.notifyIfOffline();

      if (e is dio_pkg.DioException &&
          e.type == dio_pkg.DioExceptionType.cancel) {
        debugPrint('Upload canceled for tempId: $tempId');
      }
      if (e.toString().contains('session_expired')) {
        emit(
          GroupDetailsError('Your session has expired; please log in again'),
        );
        return;
      } else {
        debugPrint('Error uploading file: $e');

        _cancelTokens.remove(tempId);
        uploadProgressMap.remove(tempId);
        (this as GroupDetailsCubit).disposeProgressNotifier(tempId);
        cachedMessages.removeWhere((m) => m.id == tempId);

        if (!isOffline) {
          emit(GroupDetailsError(e.toString()));
        }

        emit(GroupDetailsLoaded(messages: List.from(cachedMessages)));
      }
    }
  }

  Future<void> deleteMessage(String messageId) async {
    cachedMessages.removeWhere((m) => m.id == messageId);
    _emitLoaded();
    await _services.deleteGroupMessage(messageId);
  }

  void cancelUpload(String tempId) {
    if (_cancelTokens.containsKey(tempId)) {
      _cancelTokens[tempId]!.cancel('User canceled upload');

      _cancelTokens.remove(tempId);
      uploadProgressMap.remove(tempId);
      (this as GroupDetailsCubit).disposeProgressNotifier(tempId);
      cachedMessages.removeWhere((m) => m.id == tempId);

      emit(GroupDetailsLoaded(messages: List.from(cachedMessages)));
    }
  }

  @override
  Future<void> close() {
    for (final token in _cancelTokens.values) {
      token.cancel('User left the chat screen');
    }
    _cancelTokens.clear();
    return super.close();
  }
}
