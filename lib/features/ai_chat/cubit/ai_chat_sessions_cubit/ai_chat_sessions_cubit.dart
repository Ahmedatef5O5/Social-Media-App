import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/ai_chat_session.dart';
import '../../repository/ai_chat_repository.dart';
part 'ai_chat_sessions_state.dart';

class AiChatSessionsCubit extends Cubit<AiChatSessionsState> {
  AiChatSessionsCubit(this._repository) : super(AiChatSessionsLoading()) {
    _subscription = _repository.watchSessions().listen(
      (sessions) => emit(AiChatSessionsLoaded(sessions)),
      onError:
          (Object e, StackTrace _) => emit(AiChatSessionsError(e.toString())),
    );
  }

  final AiChatRepository _repository;
  late final StreamSubscription<List<AiChatSession>> _subscription;

  Future<AiChatSession> startNewSession({String? firstMessage}) {
    return _repository.createSession(firstMessage: firstMessage);
  }

  Future<void> rename(String sessionId, String title) {
    return _repository.renameSession(sessionId, title);
  }

  Future<void> delete(String sessionId) async {
    await _repository.deleteSession(sessionId);
    final current = state;
    if (current is AiChatSessionsLoaded) {
      emit(
        AiChatSessionsLoaded(
          current.sessions.where((s) => s.id != sessionId).toList(),
        ),
      );
    }
  }

  void trackNewSession(AiChatSession session) {
    final current = state;
    if (current is! AiChatSessionsLoaded) return;
    if (current.sessions.any((s) => s.id == session.id)) return;
    emit(AiChatSessionsLoaded([session, ...current.sessions]));
  }

  @override
  Future<void> close() {
    unawaited(_subscription.cancel());
    return super.close();
  }
}
