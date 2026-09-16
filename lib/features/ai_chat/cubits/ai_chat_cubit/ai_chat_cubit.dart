import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/supabase_error_mapper.dart';
import '../../../../core/helpers/safe_emit_mixin.dart';
import '../../../ai_assistant/helpers/ai_image_encoder.dart';
import '../../../ai_assistant/helpers/remote_media_fetcher.dart';
import '../../helpers/ai_chat_style_heuristic.dart';
import '../../models/ai_chat_language.dart';
import '../../models/ai_chat_message.dart';
import '../../models/ai_chat_message_record.dart';
import '../../models/ai_chat_tone.dart';
import '../../repository/ai_chat_repository.dart';
import '../../services/ai_gateway_service.dart';
part 'ai_chat_state.dart';

class AiChatCubit extends Cubit<AiChatMessagesState>
    with SafeEmitMixin<AiChatMessagesState> {
  AiChatCubit({
    required AiChatRepository repository,
    required AiGatewayService gatewayService,
    required String sessionId,
    bool isExisting = true,
  }) : _repository = repository,
       _gatewayService = gatewayService,
       _sessionId = sessionId,
       super(
         isExisting
             ? AiChatMessagesLoading()
             : AiChatMessagesLoaded(messages: const [], isSending: false),
       );

  final AiChatRepository _repository;
  final AiGatewayService _gatewayService;
  final String _sessionId;
  final Map<String, int> _progressBuckets = <String, int>{};
  static const int _progressBucketStep = 4; // percent

  List<AiChatMessage> _toDomainList(List<AiChatMessageRecord> records) {
    return records.map((r) => r.toDomain()).toList();
  }

  Future<void> loadMessages() async {
    final cached = _repository.localMessages(_sessionId);

    if (cached.isNotEmpty) {
      emit(
        AiChatMessagesLoaded(messages: _toDomainList(cached), isSending: false),
      );
    } else {
      emit(AiChatMessagesLoading());
    }

    try {
      final synced = await _repository.syncMessages(_sessionId);
      emit(
        AiChatMessagesLoaded(messages: _toDomainList(synced), isSending: false),
      );
    } catch (e) {
      if (cached.isEmpty) {
        emit(AiChatMessagesError(SupabaseErrorMapper.toUserMessage(e)));
      }
    }
  }

  String beginOptimisticMediaMessage({
    required AiChatMediaType mediaType,
    String caption = '',
    required String localFilePath,
    String? fileName,
    int? fileSizeBytes,
    int? durationSeconds,
    String? replyToMessageId,
    String? replyToMessageText,
    String? replyToSenderRole,
    String? replyToMediaType,
    String? replyToMediaUrl,
  }) {
    final current = state;
    final existingDomain =
        current is AiChatMessagesLoaded ? current.messages : <AiChatMessage>[];

    final tempId = 'pending-${DateTime.now().microsecondsSinceEpoch}';

    final placeholder = AiChatMessage(
      id: tempId,
      localId: tempId,
      role: AiChatRole.user,
      text: caption,
      status: AiChatDeliveryStatus.sending,
      createdAt: DateTime.now(),
      mediaType: mediaType,
      mediaUrl: localFilePath,
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      durationSeconds: durationSeconds,
      uploadProgress: 0,
      replyToMessageId: replyToMessageId,
      replyToText: replyToMessageText,
      replyToSenderRole: replyToSenderRole,
      replyToMediaType: replyToMediaType,
      replyToMediaUrl: replyToMediaUrl,
    );

    emit(
      AiChatMessagesLoaded(
        messages: [...existingDomain, placeholder],
        isSending: current is AiChatMessagesLoaded ? current.isSending : false,
      ),
    );
    return tempId;
  }

  void updateOptimisticProgress(String messageId, double progress) {
    final current = state;
    if (current is! AiChatMessagesLoaded) return;

    final bucket =
        ((progress.clamp(0.0, 1.0) * 100).round()) ~/ _progressBucketStep;
    if (_progressBuckets[messageId] == bucket) return;
    _progressBuckets[messageId] = bucket;

    final updated = current.messages
        .map(
          (m) =>
              m.id == messageId
                  ? m.copyWith(uploadProgress: progress, id: messageId)
                  : m,
        )
        .toList(growable: false);
    emit(AiChatMessagesLoaded(messages: updated, isSending: current.isSending));
  }

  void removeOptimisticMessage(String messageId) {
    _progressBuckets.remove(messageId);
    final current = state;
    if (current is! AiChatMessagesLoaded) return;
    final updated = current.messages
        .where((m) => m.id != messageId)
        .toList(growable: false);
    emit(AiChatMessagesLoaded(messages: updated, isSending: current.isSending));
  }

  Future<void> sendMessage({
    required String text,
    String mediaType = 'none',
    String? mediaUrl,
    String? fileName,
    int? fileSizeBytes,
    int? durationSeconds,
    String? imageBase64,
    String imageMimeType = 'image/jpeg',
    String? targetMediaType,
    String? textContent,
    String? documentBase64,
    String documentMimeType = 'application/pdf',
    String? replacingMessageId,
    String? replyToMessageId,
    String? replyToMessageText,
    String? replyToSenderRole,
    String? replyToMediaType,
    String? replyToMediaUrl,
  }) async {
    final current = state;
    final existingDomain =
        current is AiChatMessagesLoaded ? current.messages : <AiChatMessage>[];

    final baseDomain =
        replacingMessageId == null
            ? existingDomain
            : existingDomain
                .where((m) => m.id != replacingMessageId)
                .toList(growable: false);
    final replyOrigin = _findMessage(existingDomain, replyToMessageId);

    final resolvedReplyText = _firstNonEmpty([
      replyToMessageText,
      replyOrigin?.text,
    ]);

    final resolvedReplyMediaType =
        replyToMediaType ??
        (replyOrigin != null && replyOrigin.hasMedia
            ? replyOrigin.mediaType.name
            : null);

    final resolvedReplyMediaUrl = replyToMediaUrl ?? replyOrigin?.mediaUrl;

    final clientKey =
        replacingMessageId ?? 'client-${DateTime.now().microsecondsSinceEpoch}';

    final isOptimisticEchoNeeded =
        replacingMessageId == null && mediaType == 'none';

    if (isOptimisticEchoNeeded) {
      emit(
        AiChatMessagesLoaded(
          messages: [
            ...baseDomain,
            AiChatMessage(
              id: clientKey,
              localId: clientKey,
              role: AiChatRole.user,
              text: text,
              status: AiChatDeliveryStatus.sending,
              createdAt: DateTime.now(),
              replyToMessageId: replyToMessageId,
              replyToText: resolvedReplyText,
              replyToSenderRole: replyToSenderRole,
              replyToMediaType: resolvedReplyMediaType,
              replyToMediaUrl: resolvedReplyMediaUrl,
            ),
          ],
          isSending: true,
        ),
      );
    }

    final userRecordFuture = _repository.appendMessage(
      sessionId: _sessionId,
      role: 'user',
      text: text,
      mediaType: mediaType,
      mediaUrl: mediaUrl,
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      durationSeconds: durationSeconds,
      replyToMessageId: replyToMessageId,
      replyToText: resolvedReplyText,
      replyToSenderRole: replyToSenderRole,
      replyToMediaType: resolvedReplyMediaType,
      replyToMediaUrl: resolvedReplyMediaUrl,
    );

    final userRecord = await userRecordFuture;

    final userDomain = userRecord.toDomain().copyWith(
      id: userRecord.id,
      localId: clientKey,
      replyToMessageId: replyToMessageId,
      replyToText: resolvedReplyText,
      replyToSenderRole: replyToSenderRole,
      replyToMediaType: resolvedReplyMediaType,
      replyToMediaUrl: resolvedReplyMediaUrl,
    );

    _progressBuckets.remove(replacingMessageId);

    final afterUserMessage = [...baseDomain, userDomain];
    emit(AiChatMessagesLoaded(messages: afterUserMessage, isSending: true));

    var resolvedImageBase64 = imageBase64;
    var isRepliedImageAttached = false;

    if (resolvedImageBase64 == null &&
        resolvedReplyMediaType == 'image' &&
        resolvedReplyMediaUrl != null &&
        resolvedReplyMediaUrl.startsWith('http')) {
      final bytes = await RemoteMediaFetcher.fetchBytes(resolvedReplyMediaUrl);
      if (bytes != null) {
        resolvedImageBase64 = AiImageEncoder.encodeForCaption(bytes);
        isRepliedImageAttached = resolvedImageBase64 != null;
      }
    }

    final styleHint = AiChatStyleHeuristic.infer([
      ...baseDomain.where((m) => m.role == AiChatRole.user).map((m) => m.text),
      text,
    ]);

    final result = await _gatewayService.call(
      action: 'chat_message',
      payload: {
        'user_message': text,
        'history': _historyForPrompt(baseDomain),
        'user_language': styleHint.language.wireValue,
        'user_tone': styleHint.tone.wireValue,
        if (targetMediaType != null) 'target_media_type': targetMediaType,
        if (mediaType == 'voice' && mediaUrl != null) 'voice_url': mediaUrl,
        if (mediaType == 'image' && mediaUrl != null) 'image_url': mediaUrl,
        if (resolvedImageBase64 != null) 'image_base64': resolvedImageBase64,
        if (resolvedImageBase64 != null)
          'image_mime_type':
              isRepliedImageAttached ? 'image/jpeg' : imageMimeType,
        if (isRepliedImageAttached) 'reply_image_attached': true,
        if (textContent != null) 'text_content': textContent,
        if (documentBase64 != null) 'document_base64': documentBase64,
        if (documentBase64 != null) 'document_mime_type': documentMimeType,
        if (mediaType == 'file' && mediaUrl != null) 'file_url': mediaUrl,
        if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
        if (resolvedReplyText != null)
          'reply_to_message_text': resolvedReplyText,
        if (replyToSenderRole != null)
          'reply_to_sender_role': replyToSenderRole,
        if (resolvedReplyMediaType != null)
          'reply_to_media_type': resolvedReplyMediaType,
        if (resolvedReplyMediaUrl != null)
          'reply_to_media_url': resolvedReplyMediaUrl,
        if (replyOrigin?.fileName != null)
          'reply_to_file_name': replyOrigin!.fileName,
        if (replyOrigin?.durationSeconds != null)
          'reply_to_duration_seconds': replyOrigin!.durationSeconds,
      },
    );

    if (!result.success) {
      emit(
        AiChatMessagesLoaded(
          messages: afterUserMessage,
          isSending: false,
          error: result.reason,
        ),
      );
      return;
    }

    final assistantRecord = await _repository.appendMessage(
      sessionId: _sessionId,
      role: 'assistant',
      text: result.result as String,
      provider: result.provider,
      model: result.model,
      degraded: result.degraded,
      requestId: result.requestId,
    );

    emit(
      AiChatMessagesLoaded(
        messages: [...afterUserMessage, assistantRecord.toDomain()],
        isSending: false,
      ),
    );
  }

  AiChatMessage? _findMessage(List<AiChatMessage> messages, String? id) {
    if (id == null) return null;
    for (final m in messages) {
      if (m.id == id || m.localId == id) return m;
    }
    return null;
  }

  String? _firstNonEmpty(List<String?> candidates) {
    for (final c in candidates) {
      final trimmed = c?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }

  String _describeForPrompt(AiChatMessage message) {
    final text = message.text.trim();
    if (text.isNotEmpty) return text;

    switch (message.mediaType) {
      case AiChatMediaType.voice:
        final seconds = message.durationSeconds;
        return seconds == null
            ? '[voice message]'
            : '[voice message, ${seconds}s]';
      case AiChatMediaType.image:
        return '[image attachment]';
      case AiChatMediaType.video:
        return '[video attachment]';
      case AiChatMediaType.file:
        return '[file attachment: ${message.fileName ?? 'unnamed'}]';
      case AiChatMediaType.none:
        return '';
    }
  }

  /// Last 10 turns, oldest first, flattened for the gateway's chat_message
  /// prompt builder. Excludes the just-sent user message on purpose — the
  /// gateway receives it separately as `user_message`.
  List<Map<String, String>> _historyForPrompt(List<AiChatMessage> messages) {
    final turns = messages.where((m) => m.role != AiChatRole.system).toList();
    final recent = turns.length > 10 ? turns.sublist(turns.length - 10) : turns;
    return recent
        .map(
          (m) => {
            'role': m.role == AiChatRole.assistant ? 'assistant' : 'user',
            'content': _describeForPrompt(m),
          },
        )
        .toList();
  }
}
