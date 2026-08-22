import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/supabase_error_mapper.dart';
import '../../helpers/ai_chat_style_heuristic.dart';
import '../../models/ai_chat_language.dart';
import '../../models/ai_chat_message.dart';
import '../../models/ai_chat_message_record.dart';
import '../../models/ai_chat_tone.dart';
import '../../repository/ai_chat_repository.dart';
import '../../services/ai_gateway_service.dart';
part 'ai_chat_state.dart';

class AiChatCubit extends Cubit<AiChatMessagesState> {
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
    int? fileSizeBytes,
    int? durationSeconds,
  }) {
    final current = state;
    final existingDomain = current is AiChatMessagesLoaded
        ? current.messages
        : <AiChatMessage>[];

    final tempId = 'pending-${DateTime.now().microsecondsSinceEpoch}';
    final placeholder = AiChatMessage(
      id: tempId,
      role: AiChatRole.user,
      text: caption,
      status: AiChatDeliveryStatus.sending,
      createdAt: DateTime.now(),
      mediaType: mediaType,
      mediaUrl: localFilePath,
      fileSizeBytes: fileSizeBytes,
      durationSeconds: durationSeconds,
      uploadProgress: 0,
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
    final updated = current.messages
        .map(
          (m) => m.id == messageId ? m.copyWith(uploadProgress: progress) : m,
        )
        .toList(growable: false);
    emit(AiChatMessagesLoaded(messages: updated, isSending: current.isSending));
  }

  void removeOptimisticMessage(String messageId) {
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
    String? replacingMessageId,
  }) async {
    final current = state;
    final existingDomain = current is AiChatMessagesLoaded
        ? current.messages
        : <AiChatMessage>[];
    final baseDomain = replacingMessageId == null
        ? existingDomain
        : existingDomain
              .where((m) => m.id != replacingMessageId)
              .toList(growable: false);

    final userRecord = await _repository.appendMessage(
      sessionId: _sessionId,
      role: 'user',
      text: text,
      mediaType: mediaType,
      mediaUrl: mediaUrl,
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      durationSeconds: durationSeconds,
    );

    final afterUserMessage = [...baseDomain, userRecord.toDomain()];
    emit(AiChatMessagesLoaded(messages: afterUserMessage, isSending: true));

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
        if (imageBase64 != null) 'image_base64': imageBase64,
        if (imageBase64 != null) 'image_mime_type': imageMimeType,
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
            'content': m.text,
          },
        )
        .toList();
  }
}
