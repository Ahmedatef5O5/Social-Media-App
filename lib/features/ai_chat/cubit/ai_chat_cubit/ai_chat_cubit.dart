import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/ai_chat_message.dart';
import '../../models/ai_chat_message_record.dart';
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
        emit(AiChatMessagesError(e.toString()));
      }
    }
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
  }) async {
    final current = state;
    final existingDomain =
        current is AiChatMessagesLoaded ? current.messages : <AiChatMessage>[];

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

    final afterUserMessage = [...existingDomain, userRecord.toDomain()];
    emit(AiChatMessagesLoaded(messages: afterUserMessage, isSending: true));

    final result = await _gatewayService.call(
      action: 'chat_message',
      payload: {
        'user_message': text,
        'history': _historyForPrompt(existingDomain),
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
