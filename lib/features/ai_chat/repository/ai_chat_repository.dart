import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ai_chat_message_record.dart';
import '../models/ai_chat_session.dart';

/// Cache-first repository for the persistent AI assistant ("Syncra").

class AiChatRepository {
  AiChatRepository({
    required SupabaseClient supabase,
    required Box<AiChatSession> sessionsBox,
    required Box<AiChatMessageRecord> messagesBox,
  }) : _supabase = supabase,
       _sessionsBox = sessionsBox,
       _messagesBox = messagesBox;

  final SupabaseClient _supabase;
  final Box<AiChatSession> _sessionsBox;
  final Box<AiChatMessageRecord> _messagesBox;

  // --------------------------------------------------------------------
  // Sessions
  // --------------------------------------------------------------------

  Stream<List<AiChatSession>> watchSessions() async* {
    yield _sortedLocalSessions();

    try {
      final rows = await _supabase
          .from('ai_chat_sessions')
          .select()
          .order('last_message_at', ascending: false, nullsFirst: false);

      final fresh =
          (rows as List)
              .map((r) => AiChatSession.fromJson(r as Map<String, dynamic>))
              .toList();

      await _sessionsBox.clear();
      for (final s in fresh) {
        await _sessionsBox.put(s.id, s);
      }

      yield _sortedLocalSessions();
    } catch (_) {
      // Sync failure should not break the screen — the local snapshot
      // already emitted above is still shown.
    }
  }

  List<AiChatSession> _sortedLocalSessions() {
    final list = _sessionsBox.values.toList();
    list.sort((a, b) {
      final aTime = a.lastMessageAt ?? a.createdAt;
      final bTime = b.lastMessageAt ?? b.createdAt;
      return bTime.compareTo(aTime);
    });
    return list;
  }

  Future<AiChatSession> createSession({String? firstMessage}) async {
    final row =
        await _supabase
            .rpc(
              'create_ai_chat_session',
              params: {'p_first_message': firstMessage},
            )
            .single();

    final session = AiChatSession.fromJson(row);
    await _sessionsBox.put(session.id, session);
    return session;
  }

  Future<void> renameSession(String sessionId, String title) async {
    await _supabase.rpc(
      'rename_ai_chat_session',
      params: {'p_session_id': sessionId, 'p_title': title},
    );

    final cached = _sessionsBox.get(sessionId);
    if (cached != null) {
      await _sessionsBox.put(
        sessionId,
        cached.copyWith(
          title: title,
          titleIsAuto: false,
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  Future<void> deleteSession(String sessionId) async {
    await _supabase.rpc(
      'delete_ai_chat_session',
      params: {'p_session_id': sessionId},
    );

    await _sessionsBox.delete(sessionId);

    final keysToRemove =
        _messagesBox.keys
            .where((k) => k.toString().startsWith('$sessionId:'))
            .toList();
    await _messagesBox.deleteAll(keysToRemove);
  }

  // --------------------------------------------------------------------
  // Messages
  // --------------------------------------------------------------------

  List<AiChatMessageRecord> localMessages(String sessionId) {
    final list =
        _messagesBox.values.where((m) => m.sessionId == sessionId).toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  Future<List<AiChatMessageRecord>> syncMessages(
    String sessionId, {
    int limit = 50,
  }) async {
    final rows = await _supabase
        .from('ai_chat_messages')
        .select()
        .eq('session_id', sessionId)
        .order('created_at', ascending: true)
        .limit(limit);

    final fresh =
        (rows as List)
            .map((r) => AiChatMessageRecord.fromJson(r as Map<String, dynamic>))
            .toList();

    for (final m in fresh) {
      await _messagesBox.put('$sessionId:${m.id}', m);
    }

    return fresh;
  }

  Future<AiChatMessageRecord> appendMessage({
    required String sessionId,
    required String role,
    required String text,
    String mediaType = 'none',
    String? mediaUrl,
    String? fileName,
    int? fileSizeBytes,
    int? durationSeconds,
    String? provider,
    String? model,
    bool degraded = false,
    String? requestId,
  }) async {
    final row =
        await _supabase
            .rpc(
              'append_ai_chat_message',
              params: {
                'p_session_id': sessionId,
                'p_role': role,
                'p_content': text,
                'p_attachment_type': mediaType == 'none' ? null : mediaType,
                'p_attachment_url': mediaUrl,
                'p_provider': provider,
                'p_model': model,
                'p_degraded': degraded,
                'p_request_id': requestId,
                'p_file_name': fileName,
                'p_file_size_bytes': fileSizeBytes,
                'p_duration_seconds': durationSeconds,
              },
            )
            .single();

    final message = AiChatMessageRecord.fromJson(row);
    await _messagesBox.put('$sessionId:${message.id}', message);
    return message;
  }
}
